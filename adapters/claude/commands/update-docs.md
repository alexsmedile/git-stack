---
description: Update CHANGELOG.md, README, STATUS.md, and project docs after changes. Resolves symlinks, edits the real file.
allowed-tools: Bash, Read, Edit, Write, Glob, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit for [Unreleased])"
---

# /update-docs

Use the `update-docs` skill. Take the version from `$ARGUMENTS`; write to
`[Unreleased]` when absent.
