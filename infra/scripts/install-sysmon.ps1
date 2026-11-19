<#
.SYNOPSIS
  Installs (or reconfigures) Sysmon on the Windows lab VM with the SwiftOnSecurity
  community config.

.DESCRIPTION
  Runs ON THE VM, as SYSTEM, through Azure Run Command. It:
    1. Downloads Sysmon from Microsoft Sysinternals and refuses to continue unless
       Sysmon64.exe carries a valid Microsoft Authenticode signature.
    2. Downloads the SwiftOnSecurity sysmon-config, pinned to one commit so every
       rebuild of the lab gets the same rules, and checks it parses as XML.
    3. Installs Sysmon with that config, or, if Sysmon is already installed,
       just loads the new config (so the script is safe to re-run).
    4. Prints the service state and the newest Sysmon event as proof.

  Sysmon writes to the "Microsoft-Windows-Sysmon/Operational" event log. The data
  collection rule in infra/modules/telemetry.bicep collects that channel into the
  Event table of the Log Analytics workspace.

  Why SwiftOnSecurity: one well-commented file, a good balance of signal and noise
  for a learning lab. Olaf Hartong's sysmon-modular is the alternative when you
  want finer control (it is built from per-technique modules).

.EXAMPLE
  # From the repo root on your PC (VM must be running):
  az vm run-command invoke -g rg-threat-hunting-lab -n vm-win-lab-01 `
      --command-id RunPowerShellScript --scripts "@infra/scripts/install-sysmon.ps1"
#>
param(
    # Pinned commit of https://github.com/SwiftOnSecurity/sysmon-config
    [string]$ConfigCommit = '1836897f12fbd6a0a473665ef6abc34a6b497e31'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is much faster without the progress bar
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$sysmonUrl = 'https://download.sysinternals.com/files/Sysmon.zip'
$configUrl = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/$ConfigCommit/sysmonconfig-export.xml"

$work = Join-Path $env:ProgramData 'SysmonInstall'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# 1. Sysmon binary, signature-checked
$zip = Join-Path $work 'Sysmon.zip'
Invoke-WebRequest -Uri $sysmonUrl -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $work -Force
$exe = Join-Path $work 'Sysmon64.exe'

$sig = Get-AuthenticodeSignature -FilePath $exe
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
    throw "Sysmon64.exe signature check failed (status: $($sig.Status)). Not installing."
}
Write-Output "Sysmon64.exe signature: Valid, signed by Microsoft Corporation"

# 2. Config, pinned and validated
$cfg = Join-Path $work 'sysmonconfig.xml'
Invoke-WebRequest -Uri $configUrl -OutFile $cfg -UseBasicParsing
[xml](Get-Content -Path $cfg -Raw) | Out-Null
$cfgHash = (Get-FileHash -Path $cfg -Algorithm SHA256).Hash
Write-Output "Config: SwiftOnSecurity @ $($ConfigCommit.Substring(0,7)), SHA256 $cfgHash"

# 3. Install or reconfigure
# Sysmon prints its banner to stderr. In Windows PowerShell 5.1, redirecting a
# native command's stderr under ErrorActionPreference=Stop throws, so relax it for
# this call and judge success by the exit code instead.
$ErrorActionPreference = 'Continue'
if (Get-Service -Name Sysmon64 -ErrorAction SilentlyContinue) {
    Write-Output 'Sysmon already installed: loading the config.'
    $out = & $exe -c $cfg 2>&1
} else {
    Write-Output 'Installing Sysmon.'
    $out = & $exe -accepteula -i $cfg 2>&1
}
$exitCode = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
$out | ForEach-Object { "$_" } | Where-Object { $_.Trim() } | Write-Output
if ($exitCode -ne 0) {
    throw "Sysmon64.exe exited with code $exitCode."
}

# 4. Proof
$svc = Get-Service -Name Sysmon64
Write-Output "Service Sysmon64: $($svc.Status), start type $($svc.StartType)"
Start-Sleep -Seconds 5
$latest = Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' -MaxEvents 1
Write-Output "Newest Sysmon event: ID $($latest.Id) at $($latest.TimeCreated.ToUniversalTime().ToString('u'))"
Write-Output 'SYSMON INSTALL OK'
