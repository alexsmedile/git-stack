---
description: Tag a release version, update CHANGELOG.md, bump manifests, and push the tag.
allowed-tools: Bash, Read, Edit, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit to infer)"
---

# /release

Follow the **Release** fast path in the `git-ops` skill. Run it inline; do not
delegate. Take the version from `$ARGUMENTS`, stripping any leading `v`; infer
it when absent.
