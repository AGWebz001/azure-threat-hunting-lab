# simulations

Record of attack simulations run inside the lab. Every run gets a row in
[`LOG.md`](LOG.md) — the timestamp is what lets you find the activity in the logs
afterwards.

## Rules

- Run simulations only on VMs in `rg-threat-hunting-lab`.
- Note the time in UTC (Sentinel's `TimeGenerated` is UTC).
- Record what Defender blocked as well as what ran — a blocked test is a finding.
- Run the cleanup command for each Atomic test when finished.

## Tooling

[Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) via
`Invoke-AtomicRedTeam` on the Windows VM. Setup notes will be added here in Phase 5.
