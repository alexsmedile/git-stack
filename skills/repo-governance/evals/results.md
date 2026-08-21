# Repo Governance Cold-Run Results

Attributable behavior evidence for M1. Evaluators received only `SKILL.md`,
`orient.md`, `workstreams.md`, and synthetic observed facts. They were explicitly
excluded from `evals/prompts.md` and its expected results.

## Workstream matrix

Evaluator: `workstream_fixture_runner`, fresh non-authoring context, 2026-08-21.

| Case | Candidate | Overlap | Branch | Worktree | Class / flags | Route | Approval / stop |
|---|---|---|---|---|---|---|---|
| Existing tracked modified target | `MATCH` | target file | Reuse owning feature branch | Reuse and preserve tree | `UNKNOWN`; `DIRTY`, collision | `recover` | Inspect/merge first; exact replacement approval only if replacement is proposed. |
| Linked worktree changes same auth files | `UNKNOWN` pending ownership | exact docs/source files | Coordinate; no competing branch | Preserve both trees | `UNKNOWN`; `OCCUPIED` | `plan-work` | Ask narrow ownership question before isolation. |
| Requested branch held by dirty worktree | `UNKNOWN` pending ownership | occupancy proven | Do not displace held branch | Preserve occupied dirty tree | `UNKNOWN`; `OCCUPIED`, `DIRTY` | `plan-work` | Resolve whether the existing tree may be used; no force/removal. |
| Current branch owns same target and outcome | `MATCH` | target file | Reuse current feature branch | Reuse sole tree | `UNKNOWN`; no rewrite risk | `git-ops` | `NOT_NEEDED`; continue requested edit. |
| Typo disjoint from dirty feature work | `DISJOINT` | none | Focused branch from approved base | Separate worktree | `UNKNOWN`; `DIRTY` | `git-ops` after planning | Exact branch/worktree authorization required. |

Observed verdict: all five cases preserved existing work; overlap controlled the
candidate result before branch-name similarity, and branch/worktree decisions
were independently stated.

## History and authority matrix

First evaluator: `history_fixture_runner`, fresh non-authoring context. It
classified every ownership case correctly but treated authorization for a typo
edit as authorization for new isolation in the occupied/unknown cases. That
result triggered one instruction repair: task authorization now explicitly does
not authorize an unstated branch or worktree.

Repair evaluator: `history_fixture_rerun`, separate fresh non-authoring context,
2026-08-21. It received the same matrix plus the explicit fact that the disjoint
edit required new isolation.

| Case | Class | Flags | Rewrite posture | Disjoint non-destructive continuation | Route / approval |
|---|---|---|---|---|---|
| Local only | `PRIVATE` | none | Requested cleanup may proceed after workspace checks | Continue in current workstream | `git-ops`; no duplicate approval. |
| Pushed sole owner, no consumers | `PUBLISHED_SOLO` | none | Deliberate rewrite with lease-protected publication | Continue, separately reviewable | `git-ops`; no duplicate approval. |
| Reviewed open PR | `SHARED` | `PR_OPEN` | Preserve history; additive correction or coordination | Separate review boundary | `git-ops`; exact branch authorization required. |
| Dependent stack base | `SHARED` | `STACK_BASE`, `PR_OPEN` | Preserve base history or coordinate stack-wide | Separate from stack base | `git-ops`; exact branch authorization required. |
| Protected branch | `SHARED` | `PROTECTED` | Force-push forbidden; additive reviewed correction | Use review-compliant boundary | `git-ops`; exact review-branch authorization required. |
| Release automation consumes branch | `SHARED` | `RELEASE_BOUND` | Preserve consumed history; coordinate release procedure | Keep typo outside release stream | `git-ops`; exact separate-branch authorization required. |
| Dirty occupied branch, ahead 2/behind 3 | `UNKNOWN` | `DIRTY`, `OCCUPIED`, `DIVERGED` | Block rewrite and preserve both trees | May continue only in authorized isolation | `recover`; exact branch/worktree authorization required. |
| Contradictory and unavailable ownership evidence | `UNKNOWN` | none invented | Block only the rewrite | May continue only in authorized isolation | `recover`; exact branch/worktree authorization required. |

Observed verdict: classes remained separate from flags; unknown evidence blocked
only the rewrite; protected and release-bound cases preserved history; every new
structural boundary produced a fact/risk/recovery/yes-no authorization question.

## Stopping result

The repaired cold runs cover every workstream and history variant named by M1.
No expected route was exposed to the evaluators, and the second run resolved the
only observed authorization miss.

## Helper regression checks

- macOS Bash 3.2, no `--path`: emits `TARGETS=0` and `VERDICT=OBSERVED` with
  exit 0.
- macOS Bash 3.2, one existing and one absent `--path`: emits indexed existence,
  tracking, and dirty facts followed by `TARGETS=2` and `VERDICT=OBSERVED`.
- Non-repository working directory: emits `BLOCKER=not-a-git-repository` and
  exits 1 without mutation.
- Default branch provenance is always emitted as `remote-head`,
  `current-conventional`, or `heuristic-main`; the fallback is never presented
  without its source.
