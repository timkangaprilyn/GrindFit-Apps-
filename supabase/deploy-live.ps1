[CmdletBinding()]
param([switch]$ValidateOnly, [switch]$MealPreferences, [switch]$AdminDashboard, [switch]$StaffAccounts, [string]$ServiceAccountFile)

$ErrorActionPreference = 'Stop'
$projectRef = 'fizdgkpykhcdzvdyxvej'
if ((@($MealPreferences, $AdminDashboard, $StaffAccounts) | Where-Object { $_ }).Count -gt 1) { throw 'Choose only one of -MealPreferences, -AdminDashboard or -StaffAccounts.' }
if ($ServiceAccountFile -and -not $StaffAccounts) { throw '-ServiceAccountFile is only used with -StaffAccounts.' }
$serviceAccountJson = $null
if ($ServiceAccountFile) {
    if (-not (Test-Path -LiteralPath $ServiceAccountFile -PathType Leaf)) { throw "Service account file not found: $ServiceAccountFile" }
    $serviceAccountJson = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $ServiceAccountFile))
    $serviceAccount = $serviceAccountJson | ConvertFrom-Json
    if ($serviceAccount.type -ne 'service_account' -or $serviceAccount.project_id -ne 'grindfit-34b02' -or -not $serviceAccount.private_key) { throw 'This is not a Firebase service account key for grindfit-34b02.' }
    $serviceAccount = $null
}
$functionName = if ($StaffAccounts) { 'admin-staff' } elseif ($AdminDashboard) { 'admin-member-data' } elseif ($MealPreferences) { 'meal-preferences' } else { 'analytics-snapshot' }
$migrationName = if ($MealPreferences) { '202611090002_meal_preferences.sql' } else { '202611090001_analytics_snapshots.sql' }
$validatorName = if ($StaffAccounts) { 'requireAdmin, validateStaffRequest, parseClaims, withTrainerClaim, isManagedTrainer, trainerSummary' } elseif ($AdminDashboard) { 'requireAdmin, validateAdminRequest' } elseif ($MealPreferences) { 'validatePreferences' } else { 'validateSnapshot' }
$migrationPath = Join-Path $PSScriptRoot "migrations/$migrationName"
$policyPath = Join-Path $PSScriptRoot "functions/$functionName/policy.ts"
$handlerPath = Join-Path $PSScriptRoot "functions/$functionName/index.ts"
foreach ($requiredPath in @($migrationPath, $policyPath, $handlerPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) { throw "Missing deployment source: $requiredPath" }
}
$migration = [IO.File]::ReadAllText($migrationPath)
if ($AdminDashboard) {
    $migration += "`n" + [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'migrations/202611090002_meal_preferences.sql'))
}
$policy = [IO.File]::ReadAllText($policyPath)
if ($StaffAccounts) { $policy = $policy.Replace('export type StaffRequest', 'type StaffRequest') }
$handler = [IO.File]::ReadAllText($handlerPath).Replace("import { $validatorName } from './policy.ts';", '')
$source = $policy + "`n" + $handler
if ($ValidateOnly) {
    Write-Host "Deployment sources validated for $functionName in project $projectRef. No network requests or changes made."
    return
}

Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$client = [Net.Http.HttpClient]::new()
$client.Timeout = [TimeSpan]::FromMinutes(3)
$secureToken = $null
$tokenPointer = [IntPtr]::Zero
$accessToken = $null
try {
    Write-Host "Deploying $functionName only to Supabase project $projectRef."
    Write-Host 'Create a Personal Access Token at https://supabase.com/dashboard/account/tokens'
    Write-Host 'Enter it below. Input is hidden and is not saved to a file.'
    $secureToken = Read-Host 'Supabase Personal Access Token (not the publishable key)' -AsSecureString
    $tokenPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    $accessToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPointer)
    if ([string]::IsNullOrWhiteSpace($accessToken) -or $accessToken.StartsWith('sb_publishable_')) {
        throw 'A Supabase account access token is required, not a public app key.'
    }
    $client.DefaultRequestHeaders.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $accessToken)

    # Verify access before making any project changes.
    $projectResponse = $client.GetAsync("https://api.supabase.com/v1/projects/$projectRef").GetAwaiter().GetResult()
    try {
        if (-not $projectResponse.IsSuccessStatusCode) { throw "Project access failed (HTTP $([int]$projectResponse.StatusCode)). Verify account permissions and token." }
    } finally { $projectResponse.Dispose() }

    if ($StaffAccounts) { Write-Host '1/3 No database tables needed for admin-staff.' } else {
    Write-Host "1/3 Applying $functionName table migration..."
    $queryBody = @{ query = $migration } | ConvertTo-Json -Compress
    $queryContent = [Net.Http.StringContent]::new($queryBody, [Text.Encoding]::UTF8, 'application/json')
    try {
        $queryResponse = $client.PostAsync("https://api.supabase.com/v1/projects/$projectRef/database/query", $queryContent).GetAwaiter().GetResult()
        try {
            if (-not $queryResponse.IsSuccessStatusCode) { throw "Database setup failed (HTTP $([int]$queryResponse.StatusCode)). Check database permissions and SQL Editor logs; function was not deployed." }
        } finally { $queryResponse.Dispose() }
    } finally { $queryContent.Dispose() }
    }

    if ($serviceAccountJson) {
        Write-Host 'Saving FIREBASE_SERVICE_ACCOUNT as a Supabase Edge Function secret...'
        $secretBody = ConvertTo-Json -Compress -InputObject @(@{ name = 'FIREBASE_SERVICE_ACCOUNT'; value = $serviceAccountJson })
        $secretContent = [Net.Http.StringContent]::new($secretBody, [Text.Encoding]::UTF8, 'application/json')
        try {
            $secretResponse = $client.PostAsync("https://api.supabase.com/v1/projects/$projectRef/secrets", $secretContent).GetAwaiter().GetResult()
            try {
                if (-not $secretResponse.IsSuccessStatusCode) { throw "Saving the secret failed (HTTP $([int]$secretResponse.StatusCode)). Add FIREBASE_SERVICE_ACCOUNT in the Supabase dashboard instead." }
            } finally { $secretResponse.Dispose() }
        } finally { $secretContent.Dispose(); $secretBody = $null; $serviceAccountJson = $null }
    }

    Write-Host "2/3 Deploying Firebase-authenticated $functionName function..."
    $multipart = [Net.Http.MultipartFormDataContent]::new()
    try {
        $metadata = @{ name = $functionName; entrypoint_path = 'index.ts'; verify_jwt = $false } | ConvertTo-Json -Compress
        $multipart.Add([Net.Http.StringContent]::new($metadata, [Text.Encoding]::UTF8), 'metadata')
        $multipart.Add([Net.Http.StringContent]::new($source, [Text.Encoding]::UTF8, 'application/typescript'), 'file', 'index.ts')
        $deployResponse = $client.PostAsync("https://api.supabase.com/v1/projects/$projectRef/functions/deploy?slug=$functionName", $multipart).GetAwaiter().GetResult()
        try {
            if (-not $deployResponse.IsSuccessStatusCode) { throw "Function deployment failed (HTTP $([int]$deployResponse.StatusCode)). The restricted analytics table exists; rerun after fixing access or deployment errors." }
            $deployment = $deployResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
            if ($deployment.verify_jwt -ne $false) { throw 'Function JWT configuration was not confirmed. Check function settings before using analytics.' }
        } finally { $deployResponse.Dispose() }
    } finally { $multipart.Dispose() }

    # Remove management credentials before probing the public endpoint.
    $client.DefaultRequestHeaders.Authorization = $null
    $accessToken = $null
    Write-Host '3/3 Checking live endpoint and rejection of unauthenticated requests...'
    $endpoint = "https://$projectRef.supabase.co/functions/v1/$functionName"
    $verified = $false
    for ($attempt = 1; $attempt -le 6; $attempt++) {
        $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Post, $endpoint)
        $request.Headers.Add('apikey', 'sb_publishable_yCIBon4a0IDMmfCV4PGPtg_fIG_1hzS')
        $request.Content = [Net.Http.StringContent]::new('{}', [Text.Encoding]::UTF8, 'application/json')
        try {
            $probe = $client.SendAsync($request).GetAwaiter().GetResult()
            try {
                $probeBody = $probe.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                if ([int]$probe.StatusCode -eq 401 -and $probeBody -match 'Sign in required') { $verified = $true; break }
            } finally { $probe.Dispose() }
        } finally { $request.Dispose() }
        if ($attempt -lt 6) { Start-Sleep -Seconds 3 }
    }
    if (-not $verified) { throw 'Deployment returned success but live verification is still pending. Check Edge Function logs before claiming activation.' }
    Write-Host "LIVE: $functionName function is online and rejects unsigned requests." -ForegroundColor Green
    if ($StaffAccounts) {
        Write-Host 'Now sign in to the admin website as an admin and open Trainers. Delete the downloaded service account key file once the secret is saved.'
    } elseif ($AdminDashboard) {
        Write-Host 'Now sign in to the admin website with a Firebase admin claim. Check connection status and open a member profile.'
    } elseif ($MealPreferences) {
        Write-Host 'Now open Meal Recommendations, change a preference and confirm a row in meal_preferences.'
    } else {
        Write-Host 'Now run the updated app, sign in and open Analytics. Confirm Saved to Supabase and a row in analytics_snapshots.'
    }
    Write-Host 'An actual signed-in database save still needs this final app check.'
} finally {
    $client.DefaultRequestHeaders.Authorization = $null
    $client.Dispose()
    $accessToken = $null
    if ($tokenPointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPointer) }
    if ($null -ne $secureToken) { $secureToken.Dispose() }
}
