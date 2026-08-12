---
description: Draft and write a CHANGELOG.md entry for changes since the last tag. No doc patches, no commit, no push.
allowed-tools: Bash, Read, Edit, Write, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit for [Unreleased])"
---

# /changelog

Use the `update-docs` skill, scoped to the changelog only: run its Steps 1–3 and
6–7 and skip the doc-patching steps. Take the version from `$ARGUMENTS`; write to
`[Unreleased]` when absent.
