---
version: 1.0
updated: 2026-07-12
summary: "Index of what this system actually is and how it behaves right now"
related:
  - ../PRD.md
  - ../ARCHITECTURE.md
---

# git-stack — System Spec

<!--
  specs/index.md is the always-on index of system truth.
  PRD says what we want. ARCHITECTURE says how the workspace is shaped.
  This file says what's actually built and how it actually behaves right now.

  Keep it short. For small projects, one bullet list is enough.
  For complex projects, break out per-capability files at specs/<capability>.md
  and reference them from here.
-->

## What this system is

`git-stack` is a portable Git/GitHub skill bundle with a script-first safety
core. Claude Code receives native plugin commands and optional short aliases;
Codex, Cursor, Antigravity, and OpenCode can receive generated command skills
from the same catalog. Distribution is validated through deterministic Node and
shell scripts.

## Capabilities

<Bullet list. One line each. Each bullet is something the system can do right now.
Link out to `specs/<capability>.md` only when a capability needs more than one line.>

- [Command-skill adapters](command-skills.md) — render the command catalog into
  native Claude commands or portable project/global Agent Skills.
- `git-ops` — script-backed commit, push, tag, release, cleanup, and GitHub
  workflows with compact verdict output.

## How to extend this file

- Add a bullet when a new capability ships (request → verified)
- Promote a bullet to `specs/<capability>.md` when it grows past one line
- Snapshot before major rewrites: `spectacular snapshot .spectacular/specs/index.md`
