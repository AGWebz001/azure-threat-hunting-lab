# Azure Threat Hunting Lab

A home lab for practising threat hunting and detection engineering in Microsoft Azure.
Everything is defined as code (Bicep), so the whole environment can be deployed,
torn down, and rebuilt on demand.

> **Status:** scaffolded — infrastructure not yet deployed.

## Goal

Build a small, realistic environment that produces security telemetry, simulate
attacker behaviour mapped to MITRE ATT&CK inside it, hunt for that behaviour with KQL
in Microsoft Sentinel, and turn the best hunts into detections deployed from this repo.

## Architecture (planned)

| Component | Purpose |
|---|---|
| Resource group `rg-threat-hunting-lab` | Single container for every lab resource |
| Virtual network + NSG | Isolated lab network; admin access restricted to one IP |
| Windows Server VM | Attack target; Security events and Sysmon |
| Ubuntu VM | Attack target; syslog / auth logs |
| Log Analytics workspace | Central log store (daily ingestion cap) |
| Microsoft Sentinel | Hunting, analytics rules, incidents, workbooks |
| Azure Monitor Agent + data collection rules | Ships logs from the VMs |

A diagram will be added to [`docs/`](docs/) once the infrastructure is deployed.

## Repository layout

| Folder | Contents |
|---|---|
| [`infra/`](infra/) | Bicep templates and helper scripts for the environment |
| [`simulations/`](simulations/) | Log of attack simulations run in the lab |
| [`hunts/`](hunts/) | KQL hunting queries, each with a written hypothesis and findings |
| [`detections/`](detections/) | Sentinel analytics rules as code |
| [`docs/`](docs/) | Architecture notes and screenshots |

## Hunts

| # | Hunt | ATT&CK | Status |
|---|---|---|---|
| 1 | Suspicious PowerShell execution | T1059.001 | Planned |
| 2 | Persistence via scheduled tasks, run keys, services | T1053.005, T1547.001, T1543.003 | Planned |
| 3 | LSASS credential access | T1003.001 | Planned |
| 4 | Brute force followed by success | T1110 | Planned |
| 5 | Rare parent/child process pairs | T1204, T1059 | Planned |
| 6 | Linux: SSH failures, new accounts, sudo use | T1110, T1136.001 | Planned |

## Safety and cost

- Attack simulations run only against VMs inside this lab.
- No secrets, subscription IDs, tenant IDs, or IP addresses are committed.
- A budget alert is deployed before any billable resource; VMs auto-shut down nightly.
- Teardown: `az group delete --name rg-threat-hunting-lab --yes`

## Tools

Azure CLI, Bicep, GitHub CLI, Microsoft Sentinel (KQL), Sysmon, Atomic Red Team,
and Claude Code as the build assistant.
