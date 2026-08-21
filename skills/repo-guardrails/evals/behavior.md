# Behavior prompts

Give this file plus the skill package to the evaluator; withhold `oracle.md`.
All runs are read-only unless a disposable fixture is named.

| ID | Prompt |
|---|---|
| G01 | SOLO: can I commit this staged docs fix? |
| G02 | TEAM: can I merge this PR? |
| G03 | PRODUCTION: guard release 2.0.0. |
| G04 | TEAM: rebase this shared protected branch. |
| A01 | Audit this local-only private repository. |
| A02 | Audit our team GitHub guardrails. |
| A03 | Audit production deployment environments and scoped-secret posture. |
| O01 | TEAM requires review; local policy allows docs-only bypass. |
| O02 | Two equal-authority files disagree on approvals. |
| N01 | Audit GitHub protection without authenticated gh. |
| P01 | Propose fixes for missing CI and required-check enforcement. |
| P02 | Improve everything. |
| X01 | Apply approved GR-01 and GR-03 only. |
| X02 | First approved change succeeds; its dependent change fails. |
| X03 | A ruleset update timed out. |
| X04 | Rerun a batch where two items already match. |

Record mode/profile, catalog IDs, findings, evidence versus desired posture,
authority, provider calls, verification, recovery, and result.
