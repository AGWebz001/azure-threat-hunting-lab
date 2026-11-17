# Azure Threat Hunting Lab — instructions for Claude Code

This repo defines a personal Azure lab for learning threat hunting. The owner is
learning, so explain what you are doing and why, not only the final answer.

## Fixed choices

- **Infrastructure as code:** Bicep only. No Terraform, no ARM JSON written by hand.
- **Regions:** Log Analytics workspace and Sentinel in `eastus`; network and VMs in
  `northcentralus`. The free-trial subscription cannot use suitable VM sizes in
  `eastus` (`SkuNotAvailable`), and a VM must share a region with its network.
- **Resource group:** `rg-threat-hunting-lab` — every lab resource goes in it.
- **Tags:** every resource gets `project=threat-hunting-lab`.
- **Shell:** PowerShell on Windows. Python and Node are not installed on this machine.

## Before deploying anything

1. Run `az deployment group what-if` (or `az deployment sub what-if` for
   subscription-scope templates) and show the result.
2. Wait for explicit approval. Never deploy, change, or delete Azure resources without it.
3. No billable resource is deployed until the budget in `infra/budget.bicep` exists.

## Secrets and identifiers — never commit

- Passwords, keys, tokens, connection strings.
- Subscription IDs, tenant IDs, object IDs, the owner's public IP, email addresses.
- Pass these as parameters at deploy time. Passwords use `@secure()` parameters and
  are prompted for, never written to a file.
- Real parameter files are named `*.local.bicepparam` and are gitignored; commit only
  `*.example.bicepparam` with placeholder values.
- Check screenshots in `docs/` for the identifiers above before committing them.

## Cost

- VM sizes: Windows `Standard_B2as_v2`, Linux `Standard_B2als_v2` unless told
  otherwise (4 vCPUs total, which is the whole free-trial regional quota);
  auto-shutdown on every VM.
- Log Analytics: 30-day retention, daily ingestion cap.
- The subscription is a free trial with a time-limited credit — prefer the cheapest
  option that still teaches the concept, and say so when something will cost money.

## Security

- NSG rules allow RDP/SSH only from the owner's IP, supplied as a parameter. Never
  open management ports to `*` or `Internet` unless the owner explicitly asks for
  the optional honeypot exercise.
- Attack simulations (Atomic Red Team etc.) run only on VMs inside this lab.

## Conventions

- `infra/main.bicep` is the entry point; one module per concern in `infra/modules/`.
- Each hunt lives in `hunts/NN-short-name/` with `query.kql` and `README.md`
  (copy `hunts/_TEMPLATE.md`).
- Each simulation run gets a row in `simulations/LOG.md`.
- Each detection in `detections/` names its ATT&CK tactic and technique and links
  back to the hunt it came from.
- Commit or push only when asked. Small commits with clear messages.
