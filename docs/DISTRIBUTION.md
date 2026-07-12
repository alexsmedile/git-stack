# Distribution and release

git-stack has one portable Agent Skill core and several native packaging
adapters. It does not claim that one plugin manifest works in every harness.

## Support matrix

| Harness | Package surface | Manifest/catalog | Distribution |
|---|---|---|---|
| Claude Code | Full native plugin | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Git marketplace |
| Codex | Verified skill plugin | `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json` | Codex marketplace source |
| Cursor | Native skill-only plugin | `.cursor-plugin/plugin.json`, `.cursor-plugin/marketplace.json` | Local plugin, team marketplace, or public submission |
| Antigravity | Native skill-only plugin | `plugin.json` | `agy plugin install` or plugin directory |
| OpenCode | Agent Skill, not a JS plugin | `skills/*/SKILL.md` | Skill installer or `npx skills` |

Claude-only commands and the optional runner live under `adapters/claude/` and
are declared explicitly by the Claude manifest. Keeping them outside root
`commands/` and `agents/` prevents Antigravity from converting Claude commands
to skills and prevents Cursor or Antigravity from parsing `model: sonnet` as
their own agent configuration. Routine Git operations do not use the runner.

## Install and update

### Claude Code

```bash
claude plugin marketplace add alexsmedile/git-stack
claude plugin install git-stack@git-stack
```

After a release:

```bash
claude plugin marketplace update git-stack
claude plugin update git-stack@git-stack
```

Plugin commands are namespaced by Claude Code. The portable form is
`/git-stack:commit` and `/git-stack:push`. If you prefer short project-local or
user-global aliases, install them explicitly:

```bash
# Project-local: creates .claude/commands/commit.md and push.md
node skills/git-ops/scripts/install-shortcuts.mjs --scope project

# User-global: creates aliases under ~/.claude/commands/
node skills/git-ops/scripts/install-shortcuts.mjs --scope user
```

The installer is copy-based by default, refuses to overwrite existing commands,
records ownership in `.git-stack-shortcuts.json`, and supports `--dry-run`,
`--mode symlink`, `--force`, `--commands`, and `--uninstall`. The plugin files
remain authoritative; rerun the installer after a plugin update.

Claude Code uses the version in `.claude-plugin/plugin.json` as its cache key.
The marketplace entry intentionally omits `version`; setting it in both places
creates two release authorities.

### Codex

```bash
codex plugin marketplace add alexsmedile/git-stack
codex plugin add git-stack@git-stack
```

After a release:

```bash
codex plugin marketplace upgrade git-stack
codex plugin add git-stack@git-stack
```

Start a new Codex session after installation or update. The marketplace entry
links to `https://github.com/alexsmedile/git-stack.git`, and the installed
plugin is identified by `.codex-plugin/plugin.json`.

### Cursor

Test the checkout without installing it:

```bash
cursor-agent --plugin-dir .
```

For a team marketplace, import the repository in the Cursor dashboard. For the
public marketplace, submit the repository at
<https://cursor.com/marketplace/publish>. Cursor reviews initial submissions and
updates. The Cursor manifest exports only `skills/`; Claude commands and the
Claude runner are intentionally excluded.

### Antigravity

Validate and install a checkout with the CLI:

```bash
agy plugin validate .
agy plugin install .
```

The Antigravity app also discovers workspace plugins under `.agents/plugins/`
and global plugins under `~/.gemini/config/plugins/`. The root `plugin.json`
uses Antigravity's strict manifest schema and exposes only the shared skills.
No Antigravity subagent adapter is shipped because its subagents inherit the
parent model.

For skill-only global installs, choose the surface explicitly:

```bash
node skills/git-ops/scripts/install-harness.mjs antigravity --scope global --surface app
node skills/git-ops/scripts/install-harness.mjs antigravity --scope global --surface cli
```

### OpenCode

OpenCode's plugin system loads JavaScript/TypeScript event modules. git-stack
does not need such a module, so it is distributed as an Agent Skill:

```bash
npx skills add alexsmedile/git-stack
node skills/git-ops/scripts/install-harness.mjs opencode --scope global
```

### Command skills on non-Claude harnesses

Codex, Cursor, Antigravity, and OpenCode can opt into generated command skills
from the shared command catalog:

```bash
node skills/git-ops/scripts/install-harness.mjs codex \
  --scope project --with-command-skills
```

All catalog commands are installed by default (`commit`, `push`, `release`,
`changelog`, `update-docs`, `wrap-up`, and `cleanup`). Exclude individual
workflows with inverted flags such as `--no-release`; use `--scope global` for
the harness's user-level skill root. Generated adapters live beside the core
`git-ops` skill and are recorded in `.git-stack-command-skills.json`. Remove
only the generated adapters with `--uninstall-command-skills`. Verify an
existing generated set with `generate-command-skills.mjs --check`.
Command-skill generation requires the full repository checkout because the
catalog points to the canonical command bodies; skill-only installs remain
portable core installs.

An optional OpenCode runner requires an explicit provider-qualified model:

```bash
node skills/git-ops/scripts/install-harness.mjs opencode --scope global \
  --with-agent --model provider/small-model-id
```

## Release gate

Run the deterministic checks after updating the changelog and versions but
before the release commit or tag:

```bash
bash skills/git-ops/scripts/bump-manifests.sh X.Y.Z --dry-run
bash skills/git-ops/scripts/bump-manifests.sh X.Y.Z
bash skills/git-ops/scripts/check-manifests.sh
node skills/git-ops/scripts/validate-distribution.mjs --native
```

`validate-distribution.mjs` checks manifest shapes, version agreement,
repository URLs, marketplace policies, component isolation, and documentation.
With `--native`, it additionally runs available Claude and Antigravity
validators, performs an isolated Codex marketplace install from the current
working tree, and confirms OpenCode discovers both skills under isolated XDG
directories. Native checks write only to temporary configuration directories.

Once validation passes, use the normal script-backed commit, push, and annotated
`vX.Y.Z` tag flow. Platform refresh/submission steps happen after the tag:

- Claude Code: update the marketplace and plugin.
- Codex: upgrade the marketplace, reinstall, and start a new session.
- Cursor: request marketplace re-index/review when published there.
- Antigravity: reinstall the plugin checkout.
- OpenCode: rerun the skill installer.

## Source documentation

- [Claude Code plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Codex plugin authoring](https://developers.openai.com/codex/plugins/build)
- [Cursor plugin specification](https://github.com/cursor/plugins)
- [Antigravity plugins](https://antigravity.google/docs/plugins)
- [Antigravity CLI plugins](https://antigravity.google/docs/cli-plugins)
- [OpenCode skills](https://opencode.ai/docs/skills)
- [OpenCode plugins](https://opencode.ai/docs/plugins)
