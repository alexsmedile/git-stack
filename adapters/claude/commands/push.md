---
description: Commit the staged set if needed, then push through the compact git-stack preflight.
version: 3.0.0
allowed-tools: Bash, Read, AskUserQuestion
argument-hint: "[commit message]"
---

# /push

Run the common path inline. Do not delegate.

1. Run:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/git-stack.sh" push
   ```
2. `NOTHING_TO_DO`: report it and stop. `BLOCKED`: show all `BLOCKER` and
   `WARNING` lines once, then ask how to resolve them. Never force-push and
   never pass `--allow-main` without explicit user approval.
3. If `STAGED` is nonzero, use `$ARGUMENTS` verbatim or inspect only
   `git diff --cached` and draft an imperative Conventional Commit subject.
4. Execute with `--message "$MESSAGE"` when committing:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/git-stack.sh" push \
     --execute --message "$MESSAGE"
   ```
   If `STAGED=0`, omit `--message`.
5. Report only the returned commit/push destination, warnings, and leftover
   counts. Do not stage unspecified files.

Read `skills/git-ops/references/core.md` or `decisions.md` only when a blocker
needs a non-routine decision.
