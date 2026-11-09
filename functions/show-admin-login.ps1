$ErrorActionPreference = 'Stop'
$credentialPath = Join-Path (Split-Path $PSScriptRoot -Parent) '.dart_tool/private/admin-login.credential.xml'
if (-not (Test-Path -LiteralPath $credentialPath -PathType Leaf)) { throw 'No locally saved admin credentials found.' }
$credential = Import-Clixml -LiteralPath $credentialPath
Write-Host 'Private admin login — do not share or screenshot this output.'
Write-Host ('Email: ' + $credential.UserName)
Write-Host ('Password: ' + $credential.GetNetworkCredential().Password)
