param([ValidateSet('admin', 'trainer')][string]$Role = 'admin')
$ErrorActionPreference = 'Stop'
$credentialPath = Join-Path (Split-Path $PSScriptRoot -Parent) ".dart_tool/private/$Role-login.credential.xml"
if (-not (Test-Path -LiteralPath $credentialPath -PathType Leaf)) { throw "No locally saved $Role credentials found." }
$credential = Import-Clixml -LiteralPath $credentialPath
Write-Host "Private $Role login — do not share or screenshot this output."
Write-Host ('Email: ' + $credential.UserName)
Write-Host ('Password: ' + $credential.GetNetworkCredential().Password)
