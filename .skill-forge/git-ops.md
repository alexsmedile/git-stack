# git-ops — forge record

## Run

- Operation: Update
- Audit mode: extend
- Track: audit with checkable fixtures
- Target: portable Agent Skill in Git Stack
- Invocation: model-invoked specialist behind repo-governance; direct
  unambiguous Git/GitHub operations may invoke it.
- Status: repaired and verified; no reviewed blocker remains.

## Delta and boundary

Refactor a mixed router/tutorial/guard into the focused executor. Preserve
script fast paths and the user's fenced left-border report format. Universal
orientation/recovery belongs to repo-governance; repository policy to
repo-guardrails; cleanup, docs, and presentation to their specialists.

## Package plan

- `SKILL.md`: entry/return contract, proportional execution, fast paths, routing,
  hard guardrails, shared report format.
- `operations.md`: local operation matrix and recovery.
- `github.md`: provider operation matrix and PR/review judgment.
- `workflows.md`: only sequences whose workflow/completion genuinely differs.
- `core.md`: identity/secret detail disclosed only on matching blockers.
- `decisions.md` retired; universal decisions moved to repo-governance and local
  decisions are co-located with operations.

## Preserved invariants and regression surface

Native Git remains valid; canonical scripts remain under `src/scripts/`; compact
commit/push/tag/release behavior stays compatible; no installation/provider
mutation occurs. Test triggering, aliases/callers, script sync, operation safety,
provider authority, and the report format.

## Next action

Verify `STEP-01`, `SAFE-01`, and `SAFE-02` with focused script fixtures, then
dispatch the one allowed issue-scoped verifier. Advisories `EVAL-01` and
`PRUNE-01` were repaired in the same batch; installation packaging and `.DS_Store`
remain advisory because moving/deleting them is outside M2's executor behavior.

## Full review issues

- `STEP-01` blocking: steps 3–4 lacked completion criteria — repaired inline.
- `SAFE-01` blocking: tag execution implied remote publication — repaired with
  local-only default and explicit `--publish-tag`.
- `SAFE-02` blocking: push inferred commit authority. The first repair blocked
  staged pushes; scoped verification correctly found that this failed the
  required "push existing commits and report residual state" behavior. Repair 2
  now removes implicit commit execution while leaving staged files untouched.

The default two reviewer calls were consumed before this mismatch was repaired.
A final issue-only verification is exceptionally required because SAFE-02 would
otherwise remain formally unresolved; it may inspect only that issue and the
repair regression, not reopen general review.

## Verification evidence

- Mechanical: portable `check.py` passes with 0 errors and 0 warnings.
- Repository: manifest alignment, native distribution validation, Bash syntax,
  source/generated sync, and whitespace checks pass.
- Tag fixture: `tag --execute` created local `v1.0.0` with no remote ref;
  `--publish-tag` created and published `v1.0.1`.
- Push fixture: with one outgoing commit and one staged residual file, push
  advanced the remote while both `HEAD` and the index tree remained unchanged.
- Full review: revise/underbuilt with `STEP-01`, `SAFE-01`, and `SAFE-02`.
- First scoped verification: `STEP-01` and `SAFE-01` resolved; `SAFE-02`
  unresolved because the first repair over-blocked.
- Exceptional final issue-only verification: pass; `SAFE-02` resolved at
  `scripts/git-stack.sh:350-351,389-395`; no repair regression.
- Primary reviewer identities, issue lists, dispositions, and reviewed tree are
  retained in M2 Evidence `EV1-skill-forge-review-artifacts.md`.
- Attributable cold routing/operation results are retained in
  `skills/git-ops/evals/results.md`. Every Git/GitHub family passed paired
  dominant/risky coverage; T03 truthfully reports the planned M3 guardrails
  specialist as absent rather than claiming M2 implemented it.
