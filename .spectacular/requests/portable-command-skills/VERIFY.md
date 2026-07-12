---
updated: 2026-07-12
---

# Verification — portable-command-skills

## Automated {run}

- [x] `node skills/git-ops/scripts/generate-command-skills.mjs --root . --skill-root /private/tmp/git-stack-command-skills-check/.agents/skills --script-path .agents/skills/git-ops/scripts --check`
- [x] `node --check skills/git-ops/scripts/generate-command-skills.mjs`
- [x] `node --check skills/git-ops/scripts/install-harness.mjs`
- [x] `node --check skills/git-ops/scripts/validate-distribution.mjs`
- [x] `node skills/git-ops/scripts/validate-distribution.mjs`

## Structural {assert}

- [x] Generated command skills contain no `CLAUDE_PLUGIN_ROOT`, `allowed-tools`, `argument-hint`, or command-level `version` frontmatter.
- [x] `specs/commands/index.json` lists all seven command workflows and each source exists.

## Installer behavior {judge}

- [x] Temporary project/global dry-runs, all-by-default generation, inverted exclusions, collision blocking, and ownership-aware uninstall were exercised and recorded in VERIFY-LOG.md.
