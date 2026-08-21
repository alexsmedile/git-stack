---
type: Evidence
id: 01a025e5-0001-7000-8000-000000000001
ref: EV1
title: Skill Forge and paired cold evaluation for repo-guardrails
mission: M3
status: current
method: Fresh-context full review, issue-scoped verification, and oracle-withheld paired cold evaluation.
---

# Skill Forge review

Full reviewer `/root/guardrails_forge_review` received only the package, glossary,
and full-review protocol. Verdict `revise`, sizing `underbuilt`.

- `INV-01`: apply over-triggered ordinary policy requests.
- `SCOPE-01`: full audit had no finite control catalog.
- `EVAL-01`: combined eval prompts exposed expected answers and lacked baseline.

Issue-scoped verifier `/root/guardrails_forge_verify` received only the repaired
package, glossary, original issue list, and verification protocol. Verdict
`pass`; all three issues resolved; no unresolved blocker or repair regression.

# Paired cold evidence

The untouched baseline and oracle-withheld skilled run are retained in
`skills/repo-guardrails/evals/results.md` plus per-case `skilled-run.md` and
`baseline-run.md`. The skilled run passed 28/28 cases,
accounted for all 19 catalog controls in audits, loaded no unrelated context,
and kept every write behind named proposal-ID approval and read-after-write proof.

# Limitations

No live GitHub policy mutation was performed. Apply behavior was assessed from
the executable procedure and cold partial/timeout/rerun cases; live provider
effects require explicit owner authority and disposable or owner-selected targets.
