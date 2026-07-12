---
status: published
version: 1.0.0
updated: 2026-07-12
summary: "One command catalog renders Claude commands and portable Agent Skill adapters."
related:
  - index.md
  - ../../specs/commands/index.json
---

# Command-skill adapters

`specs/commands/index.json` is the command catalog. Its entries point to the
canonical command bodies under `adapters/claude/commands/`; the generator
transpiles their Claude-only frontmatter, plugin-root paths, and argument
markers into portable Agent Skills.

## Outputs

- Claude Code keeps native, namespaced plugin commands under
  `adapters/claude/commands/`.
- Codex, Cursor, Antigravity, and OpenCode can opt into generated
  `.agents/skills/<command>/SKILL.md` project adapters.
- Global installs map the same command skills to each harness's native global
  skill root.

## Installation contract

```bash
node skills/git-ops/scripts/install-harness.mjs codex \
  --scope project --with-command-skills --no-release
```

All catalog commands are enabled by default. Use inverted `--no-*` exclusions,
`--dry-run`, and `--force` for controlled installation. Generated outputs are
tracked by `.git-stack-command-skills.json`; collisions are blocked and
uninstall is ownership-aware.

## Validation

`generate-command-skills.mjs --check` verifies generated output without writing.
The distribution validator checks that the catalog and generator are present;
the installer tests exercise project scope, exclusions, collisions, and
uninstall behavior. Generation intentionally requires the full repository
checkout; skill-only installs do not contain the canonical command sources.
