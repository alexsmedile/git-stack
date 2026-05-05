---
name: git-guard
description: >
  Git and GitHub orchestration with safe defaults — use this for branching,
  committing, opening PRs, rebasing, resolving conflicts, tagging releases,
  setting up repos, or deciding the right workflow strategy. Trigger whenever
  the user mentions push, pull, PR, branch, merge, rebase, commit, tag,
  release, GitHub Actions, or asks "how should I structure this repo" /
  "what's the right workflow here" / "help me manage this". Always use
  git-guard for git/GitHub work — it enforces safety rules Claude skips by default.
compatibility: Requires `git` and `gh` CLI. Verify with `gh auth status`.
---

# git-guard

Read only the reference file(s) needed for the current task.

| Domain | Covers | Reference | Load when… |
|--------|--------|-----------|------------|
| `core` | commit, branch, merge, rebase, stash, worktree | `references/core.md` | atomic git op needed |
| `github` | PR, review, issues, repo setup, releases, CI | `references/github.md` | anything touching GitHub |
| `workflows` | feature, bugfix, refactor, release, hotfix sequences | `references/workflows.md` | multi-step task |
| `decisions` | when to use what, risk table, situation → action map | `references/decisions.md` | user needs guidance on approach |

## Safety rules

**Branching & history**
1. Never commit directly to `main` — branch first, merge via PR.
2. Never rebase shared branches — rebase is for local/personal branches only.
3. Before any history rewrite (`rebase`, `reset --hard`, force push): run `git status` + `git diff --staged`, show the user what will be affected, and confirm before proceeding.
4. Prefer `--force-with-lease` over `--force` — fails safely if remote has moved.
5. Never tag on a branch — only tag on `main` (or the designated release branch).

**Before acting**
6. Run `git fetch` before any merge or rebase — never work from stale remote state.
7. Check for uncommitted changes before switching branches — stash or commit first.

**Files & secrets**
8. Secrets never go in Git — `.env` must be in `.gitignore` before the first commit.
9. `.gitignore` must exist before the first commit on any new repo.
10. Warn before committing any file >500KB — confirm it belongs in the repo.

**Pull requests**
11. On team projects, default to `--draft` when no reviewer is lined up yet.
12. On team projects, never merge your own PR without at least one review.
