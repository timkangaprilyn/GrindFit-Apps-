[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Uid)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Uid) -or $Uid.Length -gt 128) { throw 'Enter a valid Firebase UID.' }
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$nodePath = if ($nodeCommand) { $nodeCommand.Source } else { Join-Path $env:LOCALAPPDATA 'Temp/node-v22.23.4-win-x64/node.exe' }
if (-not (Test-Path -LiteralPath $nodePath -PathType Leaf)) { throw 'Node.js is required. Install Node.js 22 LTS, then rerun this command.' }
$cliPath = Join-Path $PSScriptRoot 'node_modules/firebase-tools/lib/bin/firebase.js'
if (-not (Test-Path -LiteralPath $cliPath -PathType Leaf)) { throw 'Firebase CLI dependency is missing. Run npm ci inside functions first.' }
$helperPath = Join-Path $PSScriptRoot 'grant-admin.cjs'
& $nodePath $helperPath --check-auth
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Sign in in the browser with the Google account that manages Firebase project grindfit-34b02.'
    & $nodePath $cliPath login
    if ($LASTEXITCODE -ne 0) { throw 'Firebase login did not finish. No admin claim was changed.' }
}
& $nodePath $helperPath $Uid
if ($LASTEXITCODE -ne 0) { throw 'Admin setup was not confirmed. Review the message above.' }
