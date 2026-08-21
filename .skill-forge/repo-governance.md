# Repo Governance — forge record

## Run

- Operation: create
- Track: standard
- Target: portable Agent Skill, distributed by the existing Git Stack plugin
- Invocation: model-invoked; agents need this judgment before consequential
  repository work when intent or isolation is unclear.
- Status: blocking repair batch implemented under Spectacular M1; scoped
  verification is pending.

## Provisional contract

`repo-governance` establishes repository-local truth, classifies the intended
workstream, and recommends the smallest safe isolation boundary. It routes
atomic execution to `git-ops` and specialist work to the other Git Stack skills.

It does not replace repository-local instructions, project planning systems, or
the Git commands owned by `git-ops`. It creates no persistent project record by
default: branch, worktree, issue, PR, and repository anchors remain the source
of continuity.

## Architecture decisions

| Decision | Choice | Rationale |
|---|---|---|
| Public bundle name | Keep `git-stack` for now | The new capability can mature without a marketplace/repository rename. |
| Front door | `repo-governance` | Separates judgment from the existing atomic executor. |
| Core distinction | Branch is a history/review boundary; worktree is a concurrent-filesystem boundary | The two controls solve different risks and must be assessed independently. |
| Truth order | Local instructions and repository state before generic Git advice | Repository policy wins over generic conventions. |
| Mechanical layer | `git-stack.sh state` is a read-only fact collector, not a router | Repeated branch/status/upstream/worktree/target parsing is quicker and less error-prone mechanically; the model still chooses the route. |
| Persistent state | None by default | Do not duplicate state already expressed by Git, issues, PRs, or project anchors. |
| Universal cost | Quick local guard, then progressive orientation | Every Git request reaches governance without paying for a full audit. |
| History model | `PRIVATE`, `PUBLISHED_SOLO`, `SHARED`, `UNKNOWN` plus orthogonal risk flags | Ownership and risk conditions affect different operations and should not be collapsed. |
| Approval | Mixed continuation | Explicitly requested routine operations continue; unrequested structural, destructive, provider, or shared-history effects require one exact authorization question. |

## Candidate routes

| Route | Trigger | Planned result |
|---|---|---|
| `plan-work` | any ambiguous repository request; begins with the mandatory orient phase | verified state plus branch/worktree/workstream recommendation |
| `recover` | surprising, divergent, or unsafe state | recovery classification, factual evidence, and a stop before normal execution |
| `maintain` | health, docs, release, or presentation request | specialist routing |

## Package plan

- `skills/repo-governance/SKILL.md` — universal preflight, slim router, and
  specialist boundaries.
- `references/orient.md` — the universal preflight: repository anchors,
  evidence gathering, and compact report shape.
- `references/workstreams.md` — branch/worktree selection, matching-workstream
  evidence, and resume rules.
- `references/recover.md` — safe recovery classification and escalation.

`src/scripts/git-stack.sh state` implements the stable read-only subset of the
orient contract: local root, branch/status, cached upstream divergence,
interrupted operation, worktrees, and explicitly named target-path state. It
does not select a route, fetch, or mutate. `src/sync-scripts.mjs` distributes it
with `secret-patterns.sh` so the existing unconditional source remains valid.

## Main test prompt

> I need to make a small documentation fix, but this checkout has uncommitted
> work and another agent may be using a different worktree. Where should I do it?

Expected behavior: inspect repository instructions and Git/worktree facts; do
not switch or stash; distinguish whether the new task needs a branch and/or
worktree; return one safe next action or a narrow authorization question.

## Review state

- Mechanical gate: `check.py skills/repo-governance --profile portable` passes
  with 0 errors and 0 warnings after the repair batch.
- Full review: revise / underbuilt, 2026-08-21. The blocking repair batch and
  its one scoped verifier are complete.
- Blocking issues: `RG-INVOCATION-POLICY`, `RG-ROUTE-CONTRADICTION`,
  `RG-ORIENT-IS-PROMISSORY`, `RG-WORKSTREAM-IS-PROMISSORY`,
  `RG-RECOVERY-IS-PROMISSORY`, `RG-APPROVAL-UNSPECIFIED`, and
  `RG-COMPLETION-TOO-WEAK`.
- Advisory issues: merge the duplicate direct-to-`git-ops` route and add three
  human-review prompt tests for the dominant, risky, and near-miss cases.
- Scoped verification: pass, 2026-08-21. All seven original blockers resolved;
  no repair regression and no unresolved blocker.
- Verifier attribution: `repo_governance_verifier`, fresh context, inspected the
  repaired package and Skill Forge glossary, returned pass for the closed issue
  list. The first independent M1 FROST reviewer inspected commit `8ba7616` and
  requested one proof repair batch; its two blocking findings are retained in
  the M1 review trail rather than misreported as a passing Skill Forge review.
- M1 repair evidence: `workstream_fixture_runner` produced attributable results
  for five collision/isolation cases. `history_fixture_runner` exposed one
  structural-authorization ambiguity; after the instruction repair,
  `history_fixture_rerun` passed all eight history/profile variants including
  protected, release-bound, occupied/diverged, and unknown evidence. Results are
  retained in `skills/repo-governance/evals/results.md`.

### Verified dispositions

- `RG-INVOCATION-POLICY`: resolved by portable/model-invoked metadata and trigger
  boundary in `SKILL.md`.
- `RG-ROUTE-CONTRADICTION`: resolved by explicit orient-then-workstreams and
  orient-then-recover paths.
- `RG-ORIENT-IS-PROMISSORY`: resolved by the ordered read-only procedure,
  complete report, UNKNOWN behavior, and safe rerun.
- `RG-WORKSTREAM-IS-PROMISSORY`: resolved by candidate comparison, isolation and
  history matrices, authorization, and result schema.
- `RG-RECOVERY-IS-PROMISSORY`: resolved by recovery classes, containment,
  diagnostic stop, safe rerun, and handoff.
- `RG-APPROVAL-UNSPECIFIED`: resolved by enumerated triggers and one exact yes/no
  authorization form.
- `RG-COMPLETION-TOO-WEAK`: resolved by the exhaustive governance result fields
  and completion criterion.

## Repair evidence

- `SKILL.md` now declares portable/model-invoked policy, universal quick guard,
  five non-duplicated routes, mixed continuation, an exact approval question,
  and a complete result schema.
- `orient.md`, `workstreams.md`, and `recover.md` are ordered executable
  procedures with completion criteria, unavailable-context recovery, and safe
  rerun behavior. Recovery starts from the orient result.
- `evals/prompts.md` covers safe atomic, collision, concurrency, isolation,
  history, recovery, guardrail, specialist, and trigger cases.
- `git-stack.sh state` passed `bash -n`, current-repository execution with one
  existing and one absent target, and the post-sync drift check.

## Next action

The forge cycle is complete. Preserve this reviewed kernel and hand its boundary
contracts to the next Campaign blocks (`git-ops` refactor and
`repo-guardrails`).

## Feedback disposition

Claude review, 2026-08-21:

- Accepted: orient and plan-work are one v1 code path. Orient remains a
  reportable read-only phase, not an independent route.
- Accepted: recover ships as a diagnostic stop in v1; guided repair belongs to
  the later `/undo` capability.
- Accepted: a future state collector extends `src/scripts/git-stack.sh` and
  its generated copies; no standalone script bypasses the sync contract.
- Accepted: local authority belongs in the universal orient phase rather than
  a route of its own.
- Accepted: a matching workstream must use overlapping changed files as its
  strongest signal, ahead of branch-name or issue similarity.
- Deferred: integration is not a v1 route. Existing unambiguous integration
  work continues to `git-ops` until a distinct decision workflow is earned.
