# AGENTS.md

This file provides guidance to AI agents (Claude Code, Codex, Gemini) when working with code in this repository.

## What This Is

`git-stack` is a portable Git/GitHub skill bundle with Claude Code command
adapters. It lives inside the `skills_db` vault and is managed by `apm`. It is
not an application project: there is no conventional build or test suite, but
the distribution and shell validators are release gates.

## Structure

```
git-stack/
├── plugin.json          # Antigravity plugin manifest
├── .claude-plugin/       # Claude Code manifest + marketplace
├── .codex-plugin/        # Codex plugin manifest
├── .cursor-plugin/       # Cursor skill-only manifest + marketplace
├── .agents/plugins/      # Codex repo marketplace
├── adapters/claude/       # Claude-only commands and optional Sonnet runner
├── specs/commands/        # Canonical command catalog for generated adapters
├── skills/
│   ├── git-ops/          # Main orchestration skill (load references on demand)
│   │   ├── SKILL.md        # Entry point — domain map and safety rules
│   │   ├── references/     # Load only what's needed for the task
│   │       ├── core.md     # Atomic Git ops: commit, branch, merge, rebase, stash, worktree
│   │       ├── github.md   # GitHub ops: PR, issues, releases, repo setup
│   │       ├── workflows.md # End-to-end sequences: feature, bugfix, release, hotfix
│   │       └── decisions.md # When to use what — situational decision guide
│   │   └── scripts/       # Compact Git, install, manifest, and release validators
│   └── repo-prettifier/      # README improvement skill (interactive, 4-phase)
│       └── SKILL.md
└── docs/DISTRIBUTION.md  # Per-harness install/update/release contract
```

`_archive/` contains superseded versions — do not modify or reference them.

## Agents

Common commit/push/tag/release work is script-first and runs inline through
`skills/git-ops/scripts/git-stack.sh`. It returns compact `KEY=value` verdicts,
so routine work does not justify a second model context.

**`git-stack-runner`** (`adapters/claude/agents/git-stack-runner.md`, model `sonnet`) is an
optional Claude Code fallback for explicitly delegated, high-volume Git checks.
It calls the same script and never loads the prose references. Do not delegate
routine commit, push, tag, or release work.

Claude Code plugin agents support `model: sonnet`, but
`CLAUDE_CODE_SUBAGENT_MODEL` and a per-invocation model override that field.
Other harnesses use incompatible agent schemas and paths. Keep the portable
behavior in `SKILL.md` + scripts and treat agents as optional adapters. Use
`scripts/install-harness.mjs` to install native adapters for Claude Code,
Codex, Cursor, or OpenCode. Pass `--with-command-skills` for non-Claude
harnesses to generate all command workflows as local Agent Skills; narrow the
default set with inverted `--no-*` flags. Antigravity subagents inherit the
parent model, so the installer intentionally supports its skill and command
skills only.

Cursor and OpenCode runner adapters require an explicit model. Do not select a
model merely because its ID is valid: verify that it is actually a smaller,
lower-cost choice for the user's account and plan.

The Claude manifest explicitly points to `adapters/claude/agents/`. Do not put
the runner under root `agents/`: Cursor and Antigravity also scan that name and
must not parse Claude's `model: sonnet`. The Cursor and Codex manifests export
only `skills/`; Antigravity uses root `plugin.json`; OpenCode consumes the Agent
Skills directly because its plugins are JavaScript/TypeScript event modules.

## Distribution

`docs/DISTRIBUTION.md` owns native install, update, and marketplace instructions.
`specs/commands/index.json` owns the command catalog used by generated
command-skill adapters. Run `generate-command-skills.mjs --check` when auditing
generated output.
Before a release, run `scripts/bump-manifests.sh`, `scripts/check-manifests.sh`,
then `scripts/validate-distribution.mjs --native`. The last command validates
all manifests and performs an isolated Codex marketplace install. Do not tag or
publish when it reports `DISTRIBUTION=INVALID`.

## Skill Architecture

**git-ops** is the master orchestration skill. It separates:
- **Atomic skills** (`git-stack.core.*`) — one operation, one responsibility
- **Workflows** (`git-stack.workflow.*`) — sequenced multi-step operations

Reference files are loaded on demand — only read the one(s) relevant to the current task. The skill naming convention is `git-stack.<domain>.<skill>` (e.g. `git-stack.core.commit`, `git-stack.github.pr-create`).

**repo-prettifier** is a 4-phase interactive skill: research → positioning interview → visual design decisions → write. Never write a README before completing phases 1–3 with the user.

**`adapters/claude/commands/`** contains Claude slash commands (not portable
skills). `commit.md`, `push.md`,
`release.md`, and `wrap-up.md` are thin orchestrators over `git-stack.sh` and
the manifest scripts. The script owns canonical checks and compact reporting;
`core.md` explains non-routine policy and remediation. All checks run before
asking the user — never interrupt mid-check.

## Key Safety Rules (apply to all skills in this bundle)

- Never commit directly to `main` — branch first
- Never rebase shared branches — rebase is for personal/local branches only
- Warn before any history rewrite (`rebase`, `reset --hard`, force push)
- Prefer `--force-with-lease` over `--force`
- Secrets never go in Git; `.env` must be in `.gitignore`

## Installing / Using

Skills are installed via `apm`:

```bash
# Install git-ops globally
apm --mode skills install git-ops

# Install project-scoped
apm --mode skills --project-dir /path/to/project install git-ops
```

Commands (`commit.md`, `push.md`, `changelog.md`, `update-docs.md`,
`release.md`, `wrap-up.md`) are Claude Code slash-command adapters — they do
not go through `apm`.

Claude plugin commands are namespaced (`/git-stack:commit`,
`/git-stack:push`). The optional `skills/git-ops/scripts/install-shortcuts.mjs`
installer can copy or link selected commands into `.claude/commands/` or the
user Claude command directory for short `/commit` and `/push` aliases. It is
collision-safe and reversible; plugin command files remain authoritative.

## Editing Skills

- Keep `SKILL.md` under 500 lines
- Reference files go in `references/` — they are loaded on demand, not auto-loaded
- Version bumps: patch for fixes, minor for new behavior, major for rewrites
- Store skill versions as `metadata.version` in frontmatter; top-level
  `version` is not part of the cross-harness Agent Skills schema
- Keep runtime requirements in the skill body; `compatibility` is not accepted
  by the current Codex Agent Skills validator
- Archive superseded versions in `versions/` as `SKILL@x.y.z.md` (do not put in `_archive/`)
