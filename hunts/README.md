# hunts

One folder per hunt: `NN-short-name/` containing `query.kql` and a `README.md`
copied from [`_TEMPLATE.md`](_TEMPLATE.md).

A hunt starts from a hypothesis, not from a query. Write the hypothesis first, then
work out which logs would prove or disprove it.

| # | Hunt | ATT&CK | Data source | Status |
|---|---|---|---|---|
| 01 | Suspicious PowerShell execution | T1059.001 | Sysmon 1, Security 4688 | Planned |
| 02 | Persistence: tasks, run keys, services | T1053.005, T1547.001, T1543.003 | Security 4698, Sysmon 13, System 7045 | Planned |
| 03 | LSASS credential access | T1003.001 | Sysmon 10 | Planned |
| 04 | Brute force followed by success | T1110 | Security 4625, 4624 | Planned |
| 05 | Rare parent/child process pairs | T1204, T1059 | Sysmon 1 | Planned |
| 06 | Linux: SSH failures, new accounts, sudo | T1110, T1136.001 | Syslog (auth, authpriv) | Planned |
