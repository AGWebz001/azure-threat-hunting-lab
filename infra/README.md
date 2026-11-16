# infra

Bicep templates that build the lab.

| File | Scope | Purpose | Status |
|---|---|---|---|
| `budget.bicep` | Subscription | Monthly budget with email alerts | Deployed |
| `main.bicep` | Resource group | Entry point; calls the modules below | Deployed |
| `modules/network.bicep` | Resource group | Virtual network, subnet, NSG | Deployed |
| `modules/logging.bicep` | Resource group | Log Analytics workspace, Sentinel | Deployed |
| `modules/vms.bicep` | Resource group | Windows and Ubuntu VMs, auto-shutdown | Planned |
| `modules/monitoring.bicep` | Resource group | Azure Monitor Agent, data collection rules | Planned |
| `scripts/` | — | Helper scripts (for example Sysmon install) | Planned |

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
