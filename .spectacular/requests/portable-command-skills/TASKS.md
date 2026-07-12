---
status: verified
updated: 2026-07-12
related:
  - PLAN.md
---

# Tasks — portable-command-skills

<!--
  Executable checklist for one request.
  Lives at: .spectacular/requests/<slug>/TASKS.md

  Rules:
  - Group tasks by milestone using `### M<N> — <name>` headings.
  - Flush-left checkboxes are the COUNTED units: `- [ ]` open, `- [x]` done,
    `- [~]` deferred (not-open-not-done; shown separately in progress).
  - Indented `  - [ ]` sub-bullets are allowed as a nested acceptance checklist
    under a task, but are NOT counted — progress counts top-level only, so
    x/total stays comparable across requests.
  - `status:` in frontmatter should match parent PLAN.md.
  - Tasks are owned by the user. Engine never adds/removes/reorders tasks.
-->

## v1

### M1 — Canonical command specs and generation
- [x] Add catalog entries for commit, push, release, changelog, update-docs, wrap-up, and cleanup.
- [x] Add a deterministic generator that renders Claude commands and Agent Skill adapters.
- [x] Add drift/check mode and verify generated output has portable frontmatter and paths.
- [x] → check: generator check passes and all seven outputs are generated.

### M2 — Project/global command-skill installation
- [x] Extend `install-harness.mjs` with `--with-command-skills` and all-by-default `--no-*` exclusions.
- [x] Add collision-safe metadata, dry-run, force, and uninstall behavior for generated skills.
- [x] Verify project and global destination mapping for Codex, Cursor, Antigravity, and OpenCode.
- [x] → check: temporary project install, exclusion, collision, and uninstall checks pass.

### M3 — Documentation and distribution contract
- [x] Add `.spectacular/specs/command-skills.md` and update `.spectacular/specs/index.md`.
- [x] Update README, distribution docs, AGENTS.md, CLAUDE.md, and CHANGELOG.
- [x] Extend distribution validation to check generator/spec/output linkage.
- [x] → check: syntax checks and `validate-distribution.mjs` pass.

### Verification
- [x] Generator check reports all seven generated command skills unchanged.
- [x] Generated skills contain portable frontmatter and no Claude-only paths.
- [x] Temporary project/global installer, exclusions, collision blocking, and uninstall pass.
- [x] Node syntax checks and `validate-distribution.mjs` pass.

## v2 (deferred)

- [~] <Deferred task>
- [~] <Deferred task>
