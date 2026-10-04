---
description: Fast-lane atomic pipeline — commit staged changes, push to upstream, and verify postcondition.
allowed-tools: Bash, Read, AskUserQuestion
argument-hint: "[commit message]"
---

# /ship

Follow the **Ship** atomic fast path in the `git-ops` skill. Run inline:

```bash
bash "${CLAUDE_SKILL_DIR:-<skill-dir>}/scripts/git-stack.sh" ship --execute --message "$ARGUMENTS"
```

Verify postcondition parity (`HEAD == @{upstream}`) and emit the `┌─ SHIPPED` box.
