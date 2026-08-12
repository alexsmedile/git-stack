---
description: Repo hygiene scan — surface dead/stale/unsynced branches, junk, stashes, and reclaim space.
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[--deep | --purge]"
---

# /cleanup

Use the `repo-hygiene` skill. Default to Tier 1 (read-only). `--deep` in
`$ARGUMENTS` adds Tier 2; `--purge` unlocks Tier 3 behind its destructive-action
gate.
