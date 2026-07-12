---
description: Commit the staged set safely through the compact git-stack preflight.
version: 3.0.0
allowed-tools: Bash, Read, AskUserQuestion
argument-hint: "[commit message]"
---

# /commit

Run the common path inline. Do not delegate.

1. Run:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/git-stack.sh" commit
   ```
2. `NOTHING_TO_DO`: report it and stop. `BLOCKED`: show all `BLOCKER` and
   `WARNING` lines once, then ask how to resolve them. Never pass `--allow-main`
   without explicit user approval.
3. `CLEAN`: use `$ARGUMENTS` verbatim, or inspect only `git diff --cached` and
   draft an imperative Conventional Commit subject of at most 72 characters.
4. Execute:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/git-stack.sh" commit \
     --execute --message "$MESSAGE"
   ```
5. Report the returned commit, warnings, and remaining unstaged/untracked
   counts. Do not push and do not stage unspecified files.

Read `skills/git-ops/references/core.md` only if message or blocker handling is
ambiguous.
