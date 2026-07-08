---
name: git-ops
version: 1.5.0
description: >
  Git and GitHub orchestration with safe defaults — use this for branching,
  committing, opening PRs, rebasing, resolving conflicts, tagging releases,
  setting up repos, cleaning up a repo, or deciding the right workflow strategy.
  Trigger whenever the user mentions push, pull, PR, branch, merge, rebase,
  commit, tag, release, GitHub Actions, repo cleanup / pruning branches /
  reclaiming space, or asks "how should I structure this repo" /
  "what's the right workflow here" / "help me manage this". Always use
  git-ops for git/GitHub work — it enforces safety rules Claude skips by default.
compatibility: Requires `git` and `gh` CLI. Verify with `gh auth status`.
---

# git-ops

Read only the reference file(s) needed for the current task.

| Domain | Covers | Reference | Load when… |
|--------|--------|-----------|------------|
| `core` | commit, commit identity (noreply email setup), branch, merge, rebase, stash, worktree | `references/core.md` | atomic git op needed |
| `github` | PR, review, issues, repo setup, releases, CI | `references/github.md` | anything touching GitHub |
| `workflows` | feature, bugfix, refactor, release, hotfix sequences | `references/workflows.md` | multi-step task |
| `decisions` | when to use what, risk table, situation → action map | `references/decisions.md` | user needs guidance on approach |
| `cleanup` | repo hygiene, dead/stale/unsynced branches, gc, big-blob purge | `references/cleanup.md` | cleaning up a repo or reclaiming space |

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
11. Before every commit, run the secrets pattern scan from `references/core.md` → "Secrets / API key scan". If a config file always contains secrets (e.g., `settings.json`, `config.toml`), use the git clean filter pattern in `references/decisions.md` → "I want to back up a config file that always contains secrets".
12. On request ("audit this repo", "check for leaks", "is it safe to make public"), run the three-pass repo-wide secret audit in `references/core.md` → "Repo-wide secret audit". Always check past commits, not just working tree.
13. During `/push`, run `scripts/check-manifests.sh` as an informational warning — `/push` is not a release, so drift is surfaced but does not block.
14. When the user asks to **install a pre-commit secret-block hook** in a repo ("protect this repo from secret commits", "add the hook", "wire up the secrets guard"), invoke `scripts/install-hooks.sh <repo>`. The installer is preview-only — it prints the exact `cp` or `ln -s` command for the user to run. Never modify `.git/hooks/` automatically.
15. For releases (`/release`, `/wrap-up`), use the **bump → audit** pattern: (a) preview with `scripts/bump-manifests.sh <target> --dry-run`, (b) execute `scripts/bump-manifests.sh <target>` to write the target version into every detected project-level location, (c) re-run `scripts/check-manifests.sh` and verify every reported version equals `<target>`. The post-write audit is the real release gate. If any location still drifts, offer to re-run the bumper; if it still drifts after that, abort before commit/tag. The bumper does **not** touch component-level frontmatter (per-skill, per-command) — those evolve independently. The bumper does **not** write CHANGELOG entries — that remains the command's responsibility.

**Pull requests**
11. On team projects, default to `--draft` when no reviewer is lined up yet.
12. On team projects, never merge your own PR without at least one review.
