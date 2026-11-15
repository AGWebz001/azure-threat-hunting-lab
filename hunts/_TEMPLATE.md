# Hunt NN — Title

| | |
|---|---|
| **Date** | YYYY-MM-DD |
| **ATT&CK** | Tactic — Technique ID and name |
| **Data sources** | Tables and event IDs used |
| **Related simulation** | Link to the row in `simulations/LOG.md` |

## Hypothesis

One or two sentences: what the attacker would be doing, and what trace it should
leave in which log.

## Query

See [`query.kql`](query.kql). Explain what each stage of the query does and why.

## Findings

What the query returned. True positives (the simulation), false positives (normal
activity that matched), and anything unexpected.

## Tuning

What was changed to cut noise, and what legitimate activity is now excluded.

## Detection potential

Could this run as a scheduled analytics rule? At what threshold and frequency?
What would an analyst need in the alert to triage it?

## Lessons learned

What was missing from the logs, what you would collect differently next time.
