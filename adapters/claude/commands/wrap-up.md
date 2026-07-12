---
description: Save the current session with the script-first push path, optionally followed by a release.
version: 3.0.0
allowed-tools: Bash, Read, Edit, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0)"
---

# /wrap-up

Do not duplicate or delegate the lower-level flows.

- With no version, run the `/push` sequence and stop after reporting the saved
  commit/push. Do not ask whether to tag; the user can request a release.
- With a version, run the `/release` sequence for that exact version.
- Ask only for blockers surfaced by the script or an ambiguous changelog edit.
- Never stage unspecified files, force-push, or bypass default-branch policy
  without explicit approval.
