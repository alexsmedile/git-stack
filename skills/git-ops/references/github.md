# GitHub operation contracts

Use this when: the selected operation reads or changes GitHub. Run
`gh auth status` before the provider call; local work may continue without it.

| Operation | Required facts | Judgment and authority | Done evidence |
|---|---|---|---|
| open PR | head/base, remote branch, diff, commits, checks, links, profile | draft vs ready from review readiness; push/create must be requested | URL, exact head/base, draft state, checks |
| review PR | role, full diff, checks, threads, policy | prioritize architecture, correctness, security, data/API integrity | submitted state and unresolved blockers |
| merge PR | approvals, checks, protection, mergeability, history, deployment | strategy from commit quality and policy; never infer self-merge | merged commit/strategy and base result |
| issue | repo, content, labels, links, mutation | create/comment/close are provider effects | URL/state/links match request |
| CI | workflow/ref/run, permission, environment impact | rerun is an effect; deployment follows local authority | named run conclusion or attributed block |
| release | tag/commit, notes, draft, assets, environments | create/publish/upload are distinct effects | URL, tag, state, assets agree |

Self-review the actual PR diff. Explain why, approach, relevant alternatives,
testing, migration/rollback, and UI evidence when applicable. Stack work when
dependency or review boundaries require it, not at an arbitrary line count.

Draft means direction or validation remains open. Ready means reproducible tests
and no known author-side blocker. Repository review/protection policy wins.

Squash intermediate commits without independent value; rebase-merge clean atomic
commits when linear bisectability is desired; use a merge commit when topology or
an integration boundary matters. Preserve shared/dependent PR history.

Branch protection, rulesets, required checks/reviews, secret scanning, push
protection, environments, Dependabot, and CodeQL belong to `repo-guardrails`.
`git-ops` may execute an explicitly approved change specified there.

On failure, capture repository, target, auth, provider error, and partial effect.
A timeout after creation is `UNKNOWN`: query for the intended object before
retrying, or duplicate PRs/issues/releases may result.
