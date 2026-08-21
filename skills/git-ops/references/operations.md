# Operation contracts

Use this when: a local Git operation is selected and needs its inputs, focused
checks, authority boundary, recovery, and done condition.

| Operation | Required facts | Focused judgment | Authorization when newly discovered | Done evidence |
|---|---|---|---|---|
| commit | branch, staged diff/paths, residual work, identity, scans | staged set is one coherent change in this workstream | adding paths, bypassing blocker, default/protected commit | commit contains exactly approved paths; residual counts reported |
| push | upstream, ahead/behind, staged work, remote freshness | normal publish vs divergence/rewrite | unexpected remote/publish or any force push | expected remote ref equals local commit |
| branch | selected workstream/base, target, overlap | useful history/review boundary | creation was not implied | ref uses intended base; tree intact |
| worktree | branch ownership, linked trees, target path, dirty state | separate concurrent filesystem state | create/remove/relocate not requested | intended branch/path mapping; source intact |
| merge | source/base, dirty state, freshness, consumers, stack subsumption | direction/strategy preserve history (ff vs 3-way) | merge/publish not requested or semantic resolution | target contains source; checks pass; no merge state; subsumed branches identified for cleanup |
| rebase | history class, upstream, dirty state, freshness, dependents | only private or deliberately solo history rewrites | published rewrite or new consumer | commits replayed; checks pass; no rebase state |
| revert | commit/range, merge parent, release state | additive rollback vs forward fix | revert not requested or operational impact | inverse commit and focused verification |
| tag | version, release branch, clean tree, existing tags | tag verified release commit exactly once | pushing/replacing tag | annotated tag resolves to expected commit |

Repository-local instructions override these defaults. Unknown facts block only
operations whose safety depends on them.

## Commit shape

Atomic means one independently reviewable purpose, not one file or a fixed line
limit. A trunk commit must satisfy the repository's local gate. Prefer the local
message convention; use Conventional Commits only as a fallback. Clean private
WIP history before publication only when ownership permits.

## Branch and worktree

A branch separates history/review; a worktree separates concurrent filesystem
state. A new branch does not cure file overlap with active work. A dirty checkout
is evidence to preserve, not an instruction to stash.

If a branch is held elsewhere, inspect `git worktree list`. Resume that tree when
it is the matching workstream. Remove a worktree only after proving it has no
uncommitted or unpushed work.

## Merge and rebase

Fetch before deciding against remote state. Rebase private history when replay
improves review; merge shared history or meaningful integration boundaries.
Squash noisy PR commits; preserve atomic commits whose bisectability matters.

For divergence across the same files, integrate the protected/default branch
into the feature/integration branch, resolve and verify there, then advance the
protected branch through its normal gate. If intent is unclear, abort and route
to governance recovery.

## Failure and resume

Record operation, branch/worktree, interrupted marker, staged/dirty counts,
divergence, and exact error. Preserve files and refs. Use native `--abort` only
after confirming its recovery target. Revalidate preconditions before resume.
