[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Email)
$ErrorActionPreference = 'Stop'
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$nodePath = if ($nodeCommand) { $nodeCommand.Source } else { Join-Path $env:LOCALAPPDATA 'Temp/node-v22.23.4-win-x64/node.exe' }
if (-not (Test-Path -LiteralPath $nodePath -PathType Leaf)) { throw 'Node.js 22 is required.' }
$privateDir = Join-Path (Split-Path $PSScriptRoot -Parent) '.dart_tool/private'
New-Item -ItemType Directory -Path $privateDir -Force | Out-Null
$credentialPath = Join-Path $privateDir 'admin-login.credential.xml'
if (Test-Path -LiteralPath $credentialPath) { throw 'A local admin credential already exists. It will not be overwritten.' }
$randomBytes = New-Object byte[] 24
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($randomBytes)
$rng.Dispose()
$password = [Convert]::ToBase64String($randomBytes) + '!aA7'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = [Management.Automation.PSCredential]::new($Email, $securePassword)
# Windows Export-Clixml protects the password with this Windows user's DPAPI key.
# Save before network mutations, so a created account never loses its password.
$credential | Export-Clixml -LiteralPath $credentialPath
try {
    $inputJson = @{email=$Email;password=$password} | ConvertTo-Json -Compress
    $output = $inputJson | & $nodePath (Join-Path $PSScriptRoot 'create-admin.cjs')
    if ($LASTEXITCODE -ne 0) { throw 'Admin account was not confirmed. Check the message above. Encrypted local credentials are retained for recovery; existing Firebase passwords were not changed.' }
    $result = $output | ConvertFrom-Json
    if ($result.admin -ne $true -or -not $result.uid) { throw 'Admin verification output was invalid.' }
    Write-Host "Verified new admin account: $Email"
    Write-Host "UID: $($result.uid)"
    Write-Host 'Password saved encrypted for this Windows user. Run functions/show-admin-login.ps1 in your own terminal to view it.'
} finally {
    $password = $null
    $inputJson = $null
    $securePassword.Dispose()
    [Array]::Clear($randomBytes, 0, $randomBytes.Length)
}
