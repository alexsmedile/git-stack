---
name: git-ops
description: >
  Git and GitHub work with enforced safety rules — commit, push, branch, merge,
  rebase, PR, tag, release, repo setup, repo cleanup, or choosing a workflow.
  Use for any git/GitHub task; it blocks secrets, bad branches, and unsafe
  history rewrites that would otherwise slip through.
metadata:
  version: "1.8.2"
---

# git-ops

Requires the `git` and `gh` CLIs. Verify GitHub access with `gh auth status`
before a workflow that touches GitHub.

Use the script-first fast path for commit, push, tag, and release. Run commands
inline in the current agent; do not delegate routine Git operations. The script
returns compact `KEY=value` output and keeps diffs and scan logs out of context.

```bash
GIT_STACK="${CLAUDE_SKILL_DIR:-<skill-directory>}/scripts/git-stack.sh"
bash "$GIT_STACK" commit
bash "$GIT_STACK" push
bash "$GIT_STACK" tag --version 1.2.3
bash "$GIT_STACK" cleanup      # read-only hygiene counts
bash "$GIT_STACK" scan         # commit shape since last tag
```

`cleanup` and `scan` never write. Prefer them over hand-rolled `git branch`,
`git stash list`, `git count-objects`, or `git log` parsing — they return counts
instead of raw output.

Resolve `<skill-directory>` to this skill's directory on runtimes that do not
set `CLAUDE_SKILL_DIR`. Treat exit `0` as clean/done, `1` as blocked, and `2` as
nothing to do. Read only the compact output unless a blocker needs diagnosis.

For native installation paths across Claude Code, Codex, Cursor, Antigravity,
and OpenCode, run `node scripts/install-harness.mjs --help`. Install the skill
alone by default. Add a runtime-native agent adapter only with `--with-agent`.
For non-Claude harnesses that do not expose plugin commands, add all command
workflows as local Agent Skills with `--with-command-skills`; exclude individual
workflows with inverted flags such as `--no-release` or `--no-cleanup`.
For optional unnamespaced Claude aliases (`/commit`, `/push`), run
`node scripts/install-shortcuts.mjs --help`; the plugin-native namespaced
commands remain the authoritative source.

## First-use setup hint

Do not install aliases automatically. If the user asks for short Claude
commands, or reports that `/commit` or `/push` is missing, explain that plugin
commands are namespaced and offer the opt-in installer:

```bash
# Claude plugin install
node "$CLAUDE_PLUGIN_ROOT/skills/git-ops/scripts/install-shortcuts.mjs" --scope project --dry-run
node "$CLAUDE_PLUGIN_ROOT/skills/git-ops/scripts/install-shortcuts.mjs" --scope project

# Checked-out/public git-stack repo
node skills/git-ops/scripts/install-shortcuts.mjs --scope project
```

Use `--scope user` for a global alias. For a standalone skill install, replace
the path with `$CLAUDE_SKILL_DIR/scripts/install-shortcuts.mjs`. Read only the
compact script output; stop and show collisions instead of replacing existing
`.claude/commands` files.
Never curl/pipe an untrusted remote script; use the installed plugin/skill copy
or a checked-out `alexsmedile/git-stack` repository.

## Common operations

- **Commit**: stage only user-approved files, run `git-stack.sh commit`, draft a
  Conventional Commit message from `git diff --cached`, then rerun with
  `commit --execute --message "…"`. Never use `git add .`.
- **Push**: run `git-stack.sh push`; if clean, rerun with
  `push --execute --message "…"`. Omit `--message` when there is no staged diff.
- **Tag**: run `git-stack.sh tag --version X.Y.Z`; if clean, rerun with
  `tag --version X.Y.Z --execute`. Tags are annotated and pushed to `origin`.
- **Release**: determine the version; update CHANGELOG; run
  `bump-manifests.sh X.Y.Z` then `check-manifests.sh`; commit and push through
  `git-stack.sh`; run `validate-distribution.mjs --native` for plugin bundles;
  finally execute the tag fast path. Read `references/workflows.md` only when
  release/version decisions are ambiguous.

Stop once and ask the user when output contains `VERDICT=BLOCKED`. Never pass
`--allow-main` or `--allow-large` unless the user explicitly overrides that
specific policy.

## References

Read only the file needed for non-routine work.

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
5. Only tag on `main`, or on the release branch this repo has designated. If the repo uses a release-branch workflow, confirm which branch that is rather than assuming `main` — see `references/workflows.md`.

**Before acting**
6. Run `git fetch` before any merge or rebase — never work from stale remote state.
7. Check for uncommitted changes before switching branches — stash or commit first.

**Files & secrets**
8. Secrets never go in Git — `.env` must be in `.gitignore` before the first commit.
9. `.gitignore` must exist before the first commit on any new repo.
10. `scripts/git-stack.sh` owns the staged large-file threshold and the `--allow-large` override. Surface what it flags; never override without explicit user approval.
11. Before every commit, use `scripts/git-stack.sh`; it owns the canonical staged secret scan. For intentional secret-bearing config backups, read `references/decisions.md` for the clean-filter pattern.
12. On request ("audit this repo", "check for leaks", "is it safe to make public"), run the three-pass repo-wide secret audit in `references/core.md` → "Repo-wide secret audit". Always check past commits, not just working tree.
13. During push, let `scripts/git-stack.sh` run manifest and author-email checks. Manifest drift is a push warning and a release blocker.
14. The commit **author** must use the user's `@users.noreply.github.com` alias. Fix future commits with `git config user.email`; history repair requires `git filter-repo --mailmap` and explicit history-rewrite consent.
15. When the user asks to **install a pre-commit secret-block hook** in a repo ("protect this repo from secret commits", "add the hook", "wire up the secrets guard"), invoke `scripts/install-hooks.sh <repo>`. The installer is preview-only — it prints the exact `cp` or `ln -s` command for the user to run. Never modify `.git/hooks/` automatically.
16. For releases (`/release`, `/wrap-up`), use the **bump → audit** pattern: (a) preview with `scripts/bump-manifests.sh <target> --dry-run`, (b) execute `scripts/bump-manifests.sh <target>` to write the target version into every detected project-level location, (c) re-run `scripts/check-manifests.sh` and verify every reported version equals `<target>`. The post-write audit is the real release gate. If any location still drifts, offer to re-run the bumper; if it still drifts after that, abort before commit/tag. The bumper does **not** touch component-level frontmatter (per-skill, per-command) — those evolve independently. The bumper does **not** write CHANGELOG entries — that remains the command's responsibility.
17. In a plugin bundle, run `node scripts/validate-distribution.mjs --native`
    after the version audit and before commit/tag. Static checks always run;
    installed native validators run when their CLIs are available.

**Pull requests**
18. On team projects, default to `--draft` when no reviewer is lined up yet.
19. On team projects, never merge your own PR without at least one review.

## Delegation policy

Do not spawn a subagent for commit, push, tag, or the normal release path. A
script call is cheaper and more deterministic. Delegate only when the user asks
for parallel work or a genuinely independent, high-volume investigation would
otherwise flood the main context (for example, a repo-wide history audit).
Never infer that a valid model ID is small or inexpensive. Use a runtime's
documented low-cost model, or require the user to supply a verified model ID.
