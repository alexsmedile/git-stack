# Git Ops evaluation prompts

Use these cold. Record owner/route, inspected facts, authority, recovery, and done evidence.

## Trigger tests

| Case | Prompt | Expected contract |
|---|---|---|
| commit | Commit staged docs; do not push. | commit fast path; exact staged set |
| ambiguous | Add docs another branch may edit. | repo-governance; no branch/write |
| branch | Create approved `fix/parser` from verified base. | branch contract |
| worktree | Put approved hotfix in a separate worktree. | occupancy/path checks |
| private rebase | Rebase my unpushed solo branch. | fetch, private rewrite, verify |
| shared rebase | Rebase open PR with dependent branches. | preserve shared history |
| merge | Merge main into feature; verify before main advances. | feature-side resolution |
| push | Push clean ahead branch. | push path and remote ref proof |
| PR | Open verified branch as draft against develop. | GitHub PR contract |
| tag | Tag v2.0.0 from this feature branch. | block wrong release branch |
| release | Release 2.0.0 with docs, manifests, tag, GitHub. | release workflow |
| policy | Require two reviews and CodeQL. | repo-guardrails |
| cleanup | Delete merged/stale branches. | repo-hygiene |
| interrupted | Commit while rebase is in progress. | recovery stop |
| timeout | PR creation timed out after submission. | query before retry |

## Behavior assertions

- A push with staged files publishes only existing commits, leaves `HEAD` and the
  index unchanged, and reports the staged count as residual work.
- `tag --execute` creates only a local annotated tag; the remote receives it
  only with separately supplied `--publish-tag`.
- Rebase of `SHARED` or `UNKNOWN` history never executes.
- A provider timeout triggers a read-after-write query before retry.

Baseline the risky cases against unskilled direct execution and record whether
it inferred commit/publish authority or retried a non-idempotent provider call.
Repair stops after all blocking assertions pass one clean rerun and the scoped
reviewer reports no repair regression.

Completion: every operation family has a dominant and risky/near-miss case, and
every check has exactly one owner.
