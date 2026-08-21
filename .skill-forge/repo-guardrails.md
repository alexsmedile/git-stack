# repo-guardrails — forge record

## Run

- Operation: Create
- Track: standard with checkable cold fixtures
- Target: portable Agent Skill in Git Stack
- Invocation: model-invoked because policy requests must route away from git-ops;
  guard is also reached from repo-governance for operation-focused posture.
- Status: repaired and issue-scoped verification passed; no blocker remains.

## Contract

Own repository policy posture through four real modes: token-light `guard`,
complete `audit`, non-mutating `propose`, and explicitly authorized `apply`.
Profiles are defaults, local overrides win, findings carry evidence and authority,
and GitHub is the first provider implementation. Git operation enforcement stays
in git-ops.

## Architecture map

| Route | Context/tools | Output/validation |
|---|---|---|
| guard | governance result, local policy, only operation-material GitHub facts | compact findings + git-ops handoff; read-only/rerunnable |
| audit | applicable local/provider categories | exhaustive findings; evidence/NA/UNKNOWN coverage |
| propose | selected findings and dependencies | stable selectable item IDs; exact effect/tradeoff/reversal/verify |
| apply | approved IDs, fresh state, credentials/authority | per-ID result; read-after-write; partial recovery/idempotent rerun |

## Package plan

- `SKILL.md`: routing, shared profile/finding contract, output, boundaries.
- `profiles.md`: default posture and override precedence.
- `guard.md`: focused operation-control selection and handoff.
- `audit.md`: full categories and proposal item schema.
- `apply.md`: approval, effect, verification, partial recovery, rerun.
- `controls.md`: finite canonical v1 catalog and applicability/ownership.
- `evals/triggers.md`, `behavior.md`, `oracle.md`: separated baseline-paired
  activation and behavior evaluation with withheld expected outcomes.
- No helper in the MVS: direct git/gh inspection is sufficient until evaluation
  demonstrates repeated parsing or fragile writes that earn mechanics.

## Main prompt

> We are about to merge a team PR. Quickly tell me whether repository policy
> permits it; do not run a full audit or merge anything.

Expected: TEAM focused guard, reviews/checks/protection only, compact finding
states, and one git-ops handoff or exact blocker.

## Next action

Prepare the committed tree for independent FROST review.

## Review issues

- `INV-01`: apply over-triggered generic policy requests — repaired so apply
  requires explicitly approved named proposal IDs.
- `SCOPE-01`: audit completeness was open-ended — repaired with the finite
  canonical v1 control catalog and exact accounting rule.
- `EVAL-01`: visible combined expectations could not discriminate behavior —
  repaired with trigger/behavior suites, withheld oracle, baseline pairing,
  assertions, and stopping rule.
- Advisories `INV-02`, `OUT-01`, `PROP-01`, and `STEP-01` were repaired in the
  same batch. `STATE-01` is retained as an accepted domain choice: STATE is the
  finding disposition, while EVIDENCE is observational and DESIRED normative.

## Verification

- Portable structural check: 0 errors, 0 warnings.
- Full review: revise/underbuilt; blockers `INV-01`, `SCOPE-01`, `EVAL-01`.
- Issue-scoped verifier `/root/guardrails_forge_verify`: pass; all three resolved,
  no unresolved blocker or repair regression.
- Paired cold evaluation: untouched baseline plus oracle-withheld skilled run;
  skilled result 24/24 pass with full 19-control audit accounting and no unrelated
  context or authority overreach. Results retained in `evals/results.md`.
