<#
.SYNOPSIS
  Deploys (or updates) the threat hunting lab from infra/main.bicep.

.DESCRIPTION
  Looks up your current public IP for the RDP/SSH firewall rules, then runs the
  deployment. The Azure CLI prompts for the VM admin password with hidden input;
  it is never written to disk or passed on the command line.

  Add -WhatIf to preview the changes without deploying.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File infra\deploy.ps1
  powershell -ExecutionPolicy Bypass -File infra\deploy.ps1 -WhatIf
#>
[CmdletBinding()]
param(
    [string]$ResourceGroup = 'rg-threat-hunting-lab',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# Pick up tools installed after this terminal was opened.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) not found. Install it with: winget install --id Microsoft.AzureCLI -e'
}

az account show --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    throw 'Not signed in to Azure. Run "az login" first.'
}

$ip = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 15).Trim()
if ($ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
    throw 'Could not determine your public IPv4 address.'
}

$template = Join-Path $PSScriptRoot 'main.bicep'
$action = if ($WhatIf) { 'what-if' } else { 'create' }

Write-Host ''
Write-Host "Resource group : $ResourceGroup"
Write-Host "Action         : $action"
Write-Host 'Admin username : labadmin'
Write-Host ''
Write-Host 'You will be asked for adminPassword. Typing is hidden.'
Write-Host 'Rules: 12+ characters, with three of: lowercase, uppercase, digit, symbol.'
Write-Host ''

az deployment group $action `
    --resource-group $ResourceGroup `
    --name 'lab-vms' `
    --template-file $template `
    --parameters adminSourceIp="$ip/32" `
    --query '{state: properties.provisioningState, outputs: properties.outputs}' `
    --output json

if ($LASTEXITCODE -eq 0) {
    Write-Host ''
    Write-Host "DEPLOY FINISHED: az exited successfully ($action)." -ForegroundColor Green
} else {
    Write-Host ''
    Write-Host "DEPLOY FAILED: az exit code $LASTEXITCODE. Scroll up for the error." -ForegroundColor Red
}
