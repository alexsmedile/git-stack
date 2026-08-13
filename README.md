# git-stack

Portable Git & GitHub skill bundle for Claude Code, Codex, Cursor,
Antigravity, and OpenCode — script-first orchestration with safe defaults.

![License](https://img.shields.io/badge/license-MIT-blue)
![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-blueviolet)
![Codex](https://img.shields.io/badge/Codex-compatible-orange)
![Cursor](https://img.shields.io/badge/Cursor-compatible-7c3aed)
![Antigravity](https://img.shields.io/badge/Antigravity-compatible-4285f4)
![OpenCode](https://img.shields.io/badge/OpenCode-compatible-111827)
![Version](https://img.shields.io/badge/version-1.13.0-green)

## What's Inside

| Component | Invoked as | What it does |
|-----------|-----------|-------------|
| `git-ops` | `/git-stack:git-ops` | Orchestration layer for all Git/GitHub work — decision guide, atomic ops, multi-step workflows |
| `repo-prettifier` | `/git-stack:repo-prettifier` | Interactive README upgrade — positions, designs, and writes a high-converting README |
| `/commit` | `/git-stack:commit` | Safe local commit with the full pre-flight check suite |
| `/push` | `/git-stack:push` | Everything `/commit` does, plus remote state checks and a guarded push |
| `/release` | `/git-stack:release` | Bump manifests, update changelog, commit, push, and tag a release |
| `/changelog` | `/git-stack:changelog` | Draft and write a CHANGELOG entry for changes since the last tag |
| `/update-docs` | `/git-stack:update-docs` | Update CHANGELOG + all project docs after major changes |
| `/wrap-up` | `/git-stack:wrap-up` | Full release wrap-up — version bump, changelog, README patches, commit, tag, push |
| `/cleanup` | `/git-stack:cleanup` | Repo hygiene scan — dead/stale branches, junk, stashes, space reclaim. Read-only by default |

Claude Code namespaces plugin commands, so `/git-stack:commit` and
`/git-stack:push` are canonical; the short `/commit` and `/push` forms are
optional aliases installed by `install-shortcuts.mjs`.

## Install

### Claude Code — marketplace

```bash
claude plugin marketplace add alexsmedile/git-stack
claude plugin install git-stack@git-stack
```

Or open Claude Code's interactive `/plugin` manager.

Claude Code namespaces plugin commands. Use `/git-stack:commit` and
`/git-stack:push` directly, or install short aliases explicitly:

```bash
node skills/git-ops/scripts/install-shortcuts.mjs --scope project
```

This creates `.claude/commands/commit.md` and `push.md`. It is opt-in,
copy-based by default, collision-safe, and reversible with `--uninstall`.

### Codex — marketplace

```bash
codex plugin marketplace add alexsmedile/git-stack
codex plugin add git-stack@git-stack
```

Start a new Codex session after installation.

### Cursor — native plugin

Test a checkout directly:

```bash
cursor-agent --plugin-dir .
```

Public distribution uses the Cursor Marketplace submission flow; team
marketplaces import this GitHub repository.

### Antigravity — native plugin

```bash
agy plugin validate .
agy plugin install .
```

### OpenCode and universal Agent Skills

```bash
npx skills add alexsmedile/git-stack
```

### Native harness paths

The portable core is an Agent Skill plus scripts. Install it directly into a
harness-native location with the bundled cross-platform Node installer:

```bash
node skills/git-ops/scripts/install-harness.mjs cursor --scope global
node skills/git-ops/scripts/install-harness.mjs antigravity --scope global --surface cli
node skills/git-ops/scripts/install-harness.mjs opencode --scope global
```

Project scope is the default and installs into the current repository. Use
`--dry-run` to preview. Routine Git operations need only the skill.

### Scripts

`src/scripts/` is the source of truth for every script in the bundle. Skills are
self-contained, so the scripts each one needs are copied into
`skills/<name>/scripts/` by the sync tool:

```bash
node src/sync-scripts.mjs           # distribute
node src/sync-scripts.mjs --check   # fail if a copy has drifted
```

Edit `src/scripts/` and re-sync; generated copies carry a banner and are
overwritten. `repo-hygiene` and `update-docs` receive only `git-stack.sh`, since
they call just the read-only `cleanup` and `scan` subcommands.

### Non-Claude harnesses

The installer places all four skills (`git-ops`, `repo-hygiene`, `update-docs`,
`repo-prettifier`) into the harness's skill root:

```bash
node skills/git-ops/scripts/install-harness.mjs codex --scope project
```

Harnesses without native plugin commands invoke these conversationally — ask for
a commit, a release, or a repo cleanup and the matching skill loads. Use
`--scope global` for a user-wide install.

Optional native agent adapters are available when a separate context is truly
useful:

```bash
node skills/git-ops/scripts/install-harness.mjs claude --scope global --with-agent
node skills/git-ops/scripts/install-harness.mjs codex --scope global --with-agent
node skills/git-ops/scripts/install-harness.mjs cursor --scope global \
  --with-agent --model "$CURSOR_SMALL_MODEL"
node skills/git-ops/scripts/install-harness.mjs opencode --scope global \
  --with-agent --model anthropic/claude-haiku-4-20250514
```

Cursor requires an explicitly verified small/low-cost model ID because its
available IDs depend on account and plan. OpenCode requires an explicit
provider-qualified model. Antigravity intentionally has no generated runner
adapter because its documented subagents inherit the parent model; install the
skill and use the inline script path.

### Test locally (no install)

```bash
git clone https://github.com/alexsmedile/git-stack
claude --plugin-dir ./git-stack
node ./git-stack/skills/git-ops/scripts/validate-distribution.mjs --native
```

See [distribution and release](docs/DISTRIBUTION.md) for the exact package
surface, update workflow, and marketplace behavior of every harness.

## Skills

### `git-ops`

The orchestration layer. Covers:

- **Atomic ops** — commit, branch, merge, rebase, stash, worktree
- **GitHub ops** — PRs, issues, releases, repo setup
- **Workflows** — feature, bugfix, refactor, release, hotfix sequences
- **Secrets safety** — canonical pre-commit patterns + on-request repo-wide audit (working tree + git history) + git clean-filter recipe for config files that always contain secrets
- **Decision guide** — when to use what, risk table, common situation → action map

Reference files load on demand — only what's needed for the current task.

Routine commit, push, tag, and release paths are script-first. The bundled
`git-stack.sh` runs the mechanical checks and returns compact `KEY=value`
results, avoiding raw-log context bloat and a second model invocation.

It also exposes two read-only reports that never write:

| Op | Returns |
|---|---|
| `cleanup` | merged / stale / unsynced / gone branch counts, stashes, tracked junk, packed + loose size (`--stale-days` configurable) |
| `scan` | commits since the last tag grouped by Conventional type, with breaking-change detection |

`/cleanup` and `/changelog` call these instead of parsing raw `git branch`,
`git stash list`, `git count-objects`, or `git log` output.

### `repo-prettifier`

Transforms a bare README into a high-converting project page. Works interactively in 4 phases:

1. Research the repo silently, form a point of view
2. Positioning interview — hooks, title options, audience, tone
3. Visual design decisions — style, badges, icons, callouts, ASCII trees
4. Write `README2.md` for review, then replace on confirmation

Design patterns, tone rules, and badge templates live in
`references/design.md`, loaded at phase 3 rather than on every invocation.

## Commands

These slash commands are Claude-specific adapters under
`adapters/claude/commands/`. Plugin commands use the `git-stack:` namespace;
the unnamespaced `/commit` and `/push` forms are optional standalone aliases
installed by `install-shortcuts.mjs`. Other harnesses use the portable skills
rather than parsing Claude command frontmatter or environment variables.

### `/commit`

Safe local commit. Thin orchestrator over the bundled compact preflight:

- Secrets scan (canonical patterns from `git-ops/references/core.md` → OpenAI, Anthropic, GitHub, AWS, Google, Slack, Hugging Face, PEM blocks, etc.)
- `.env` detection
- Hardcoded absolute path detection
- Large file check (threshold owned by `git-stack.sh`; `--allow-large` to override)
- `.gitignore` audit
- Unstaged changes prompt
- Branch safety warning (main/master)

Stops only on a blocker; clean staged changes commit without delegation.

### `/push`

Everything `/commit` does, plus:

- Remote state check (fetch dry-run)
- Diverged history warning
- Upstream branch detection
- Push with `--set-upstream` when needed
- Force-push guardrail — `--force-with-lease` only, never to shared branches (per git-ops rule #4)

### Agent model portability

The common workflow does not require a subagent. Agent definitions are not a
portable standard, so git-stack generates native adapters instead of pretending
one file works everywhere:

| Harness | Native agent format | Default adapter model | Notes |
|---|---|---|---|
| Claude Code | Markdown/YAML | `sonnet` | Environment or invocation overrides can win |
| Codex | TOML | `gpt-5.6-terra`, low effort | Uses `developer_instructions` |
| Cursor | Markdown/YAML | User supplied | Must be a verified small/low-cost model available to the account |
| Antigravity | Dynamic/shared harness | Parent model | Skill-only; no false smaller-model guarantee |
| OpenCode | Markdown/YAML | User supplied | Must be `provider/model-id` |

The shared contract is `skills/git-ops/SKILL.md` plus its scripts. This is also
why the Cursor plugin manifest exports `skills/` but not the Claude-specific
root `agents/` directory.

The adapter contract is based on the current native documentation for
[Claude Code](https://code.claude.com/docs/en/sub-agents),
[Codex](https://learn.chatgpt.com/docs/agent-configuration/subagents?surface=app),
[Cursor](https://cursor.com/docs/subagents),
[Antigravity](https://antigravity.google/docs/subagents), and
[OpenCode](https://opencode.ai/docs/agents/). The
[VoltAgent Codex gallery](https://github.com/VoltAgent/awesome-codex-subagents)
is useful for examples, but official Codex fields remain the schema authority.

### `/changelog`

Drafts a [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) entry for all commits since the last tag. Auto-detects version bump (major/minor/patch) from change type. Confirms before writing.

### `/update-docs`

Updates CHANGELOG.md plus all project docs (README, AGENTS.md, CLAUDE.md, GEMINI.md) that exist in the repo. Resolves symlinks and edits the real file. Shows a diff-style preview per doc, confirms before writing anything.

### `/release`

Script-backed release: version decision → changelog → manifest bump/audit →
commit/push → annotated tag. The script gates clean state and default-branch
tagging while the orchestrator handles the small amount of semantic editing.

### `/wrap-up`

With no version, saves the session through `/push`. With a version, runs the
exact `/release` path. It no longer asks an open-ended tag question after every
ordinary save.

### `/cleanup`

Repo hygiene scan — merged/stale/unsynced branches, junk files, forgotten
stashes, and reclaimable space. Backed by `git-stack.sh cleanup`, which returns
counts rather than raw branch and stash listings; names are fetched only for
categories you choose to act on. Report-first and read-only by default;
`--deep` runs safe `gc`/`prune`, and any history rewrite stays behind an
explicit warning. Checks and severity tiers live in
`repo-hygiene/references/tiers.md`.

## Safety Rules

The full list lives in `skills/git-ops/SKILL.md` → "Safety rules" (numbered
1–19). Highlights:

- Never commit directly to `main` — branch first
- Never rebase shared branches
- Warn before any history rewrite
- Prefer `--force-with-lease` over `--force`
- Secrets never go in Git

## Requirements

- `git` CLI
- `gh` CLI (for GitHub operations) — verify with `gh auth status`

## After Install

Plugin-installed skills are namespaced by their host. Direct Agent Skill
installs expose `git-ops` and `repo-prettifier` by skill name.

To update after pushing changes:

```bash
claude plugin marketplace update git-stack
claude plugin update git-stack@git-stack
codex plugin marketplace upgrade git-stack
codex plugin add git-stack@git-stack
```

## License

MIT
