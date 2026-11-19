# infra

Bicep templates that build the lab.

| File | Scope | Purpose | Status |
|---|---|---|---|
| `budget.bicep` | Subscription | Monthly budget with email alerts | Deployed |
| `main.bicep` | Resource group | Entry point; calls the modules below | Deployed |
| `modules/network.bicep` | Resource group | Virtual network, subnet, NSG | Deployed |
| `modules/logging.bicep` | Resource group | Log Analytics workspace, Sentinel | Deployed |
| `modules/vms.bicep` | Resource group | Windows and Ubuntu VMs, auto-shutdown | Deployed |
| `deploy.ps1` | — | Looks up your IP, prompts for the VM password, runs the deployment | — |
| `modules/telemetry.bicep` | Resource group | Azure Monitor Agent on both VMs; DCR for Windows Security events (Common set) and Sysmon | Deployed |
| `telemetry.bicep` | Resource group | Stand-alone entry for the telemetry layer only (no password or IP needed) | Deployed |
| `scripts/install-sysmon.ps1` | VM | Installs Sysmon with the SwiftOnSecurity config (pinned commit); run via `az vm run-command` | Run on `vm-win-lab-01` |

## Telemetry

The data collection rule lives in the workspace region (eastus) because a DCR must
share a region with its Log Analytics destination; the VMs it collects from are in
northcentralus. Deploy or update just this layer with:

```powershell
az deployment group what-if --resource-group rg-threat-hunting-lab --name lab-telemetry --template-file infra/telemetry.bicep
az deployment group create  --resource-group rg-threat-hunting-lab --name lab-telemetry --template-file infra/telemetry.bicep
```

Install or update Sysmon on the Windows VM (the VM must be running; the script
runs as SYSTEM and is safe to re-run):

```powershell
az vm run-command invoke -g rg-threat-hunting-lab -n vm-win-lab-01 --command-id RunPowerShellScript --scripts "@infra/scripts/install-sysmon.ps1"
```

Sysmon events land in the `Event` table: `Event | where Source == "Microsoft-Windows-Sysmon"`.

## One-time subscription setup

A new subscription must register the resource providers the lab uses. Sentinel
onboarding fails with `MissingSubscriptionRegistration` if
`Microsoft.OperationsManagement` is missing, even though no template resource
references it directly.

```powershell
foreach ($ns in 'Microsoft.Network','Microsoft.OperationalInsights','Microsoft.SecurityInsights','Microsoft.OperationsManagement') { az provider register --namespace $ns --wait }
```

## Deploying

Always preview first:

```powershell
az deployment group what-if --resource-group rg-threat-hunting-lab --template-file infra/main.bicep --parameters adminSourceIp=<your-ip>/32
```

Then deploy with the same arguments, replacing `what-if` with `create`.

## Parameters

`adminSourceIp` is your current public IP in CIDR form. It is passed on the command
line and never committed. If your IP changes, re-run the deployment with the new
value to update the NSG rules. The VM admin password (added with the VMs) is never
stored — it is prompted for at deploy time.
