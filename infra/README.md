# infra

Bicep templates that build the lab.

| File | Scope | Purpose | Status |
|---|---|---|---|
| `budget.bicep` | Subscription | Monthly budget with email alerts | Planned |
| `main.bicep` | Resource group | Entry point; calls the modules below | Planned |
| `modules/network.bicep` | Resource group | Virtual network, subnet, NSG | Planned |
| `modules/logging.bicep` | Resource group | Log Analytics workspace, Sentinel | Planned |
| `modules/vms.bicep` | Resource group | Windows and Ubuntu VMs, auto-shutdown | Planned |
| `modules/monitoring.bicep` | Resource group | Azure Monitor Agent, data collection rules | Planned |
| `scripts/` | — | Helper scripts (for example Sysmon install) | Planned |

## Deploying

Always preview first:

```powershell
az deployment group what-if --resource-group rg-threat-hunting-lab --template-file infra/main.bicep --parameters infra/main.local.bicepparam
```

Then deploy with the same arguments, replacing `what-if` with `create`.

## Parameters

Copy `main.example.bicepparam` to `main.local.bicepparam` and fill in your values.
The `.local` file is gitignored. The VM admin password is never stored — it is
prompted for at deploy time.
