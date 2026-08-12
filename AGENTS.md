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
├── src/                   # SOURCE OF TRUTH for scripts — edit here, never in skills/
│   ├── scripts/           # Canonical Git, install, manifest, and release scripts
│   └── sync-scripts.mjs   # Distributes src/scripts/ into each skill that needs them
├── skills/
│   ├── git-ops/          # Git orchestration (load references on demand)
│   │   ├── SKILL.md        # Entry point — safety rules, domain map, script fast paths
│   │   ├── references/     # Load only what's needed for the task
│   │       ├── core.md     # Atomic Git ops: commit, commit identity, branch, merge, stash, worktree
│   │       ├── github.md   # GitHub ops: PR, issues, releases, repo setup
│   │       ├── workflows.md # End-to-end sequences: feature, bugfix, release, hotfix
│   │       └── decisions.md # When to use what — situational decision guide
│   │   └── scripts/       # GENERATED copies of src/scripts/ — do not edit
│   ├── repo-hygiene/      # Repo cleanup and space reclaim (3 tiers)
│   │   ├── SKILL.md
│   │   ├── references/tiers.md
│   │   └── scripts/       # GENERATED copy of git-stack.sh — do not edit
│   ├── update-docs/       # CHANGELOG, README, STATUS.md, docs/ updates
│   │   ├── SKILL.md
│   │   └── scripts/       # GENERATED copy of git-stack.sh — do not edit
│   └── repo-prettifier/   # README improvement skill (interactive, 4-phase)
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
Codex, Cursor, or OpenCode. The installer places all four skills into the
harness skill root; harnesses without plugin commands invoke them
conversationally. Antigravity subagents inherit the parent model, so the
installer intentionally supports its skills only.

Cursor and OpenCode runner adapters require an explicit model. Do not select a
model merely because its ID is valid: verify that it is actually a smaller,
lower-cost choice for the user's account and plan.

The Claude manifest explicitly points to `adapters/claude/agents/`. Do not put
the runner under root `agents/`: Cursor and Antigravity also scan that name and
must not parse Claude's `model: sonnet`. The Cursor and Codex manifests export
only `skills/`; Antigravity uses root `plugin.json`; OpenCode consumes the Agent
Skills directly because its plugins are JavaScript/TypeScript event modules.

## Scripts And The Sync Contract

`src/scripts/` is the **single source of truth** for every script in this
bundle. Skills must be self-contained — a skill installed on its own cannot
reach a sibling skill's directory — so the scripts each skill calls are copied
into `skills/<name>/scripts/` by `src/sync-scripts.mjs`.

```bash
node src/sync-scripts.mjs           # distribute src/scripts/ into the skills
node src/sync-scripts.mjs --check   # exit 1 if any copy has drifted
```

Rules:

- **Edit `src/scripts/`, never `skills/*/scripts/`.** Every generated copy
  carries a banner naming its source. A hand-edit is silently overwritten on the
  next sync.
- Run the sync after any script change, and before `check-manifests.sh` in a
  release. `--check` is the drift gate.
- `src/sync-scripts.mjs` owns the per-skill distribution list. `git-ops` gets the
  full set; `repo-hygiene` and `update-docs` get only `git-stack.sh`, because
  they call only the read-only `cleanup` and `scan` subcommands, which never
  invoke the sibling checker scripts.
- Scripts resolve the repository root by searching upward for
  `.claude-plugin/plugin.json`, so the same file works from `src/scripts/` and
  from any installed skill copy. Do not reintroduce a fixed `../../..` hop.

## Distribution

`docs/DISTRIBUTION.md` owns native install, update, and marketplace instructions.
Before a release, run `node src/sync-scripts.mjs --check`,
`scripts/bump-manifests.sh`, `scripts/check-manifests.sh`,
then `scripts/validate-distribution.mjs --native`. The last command validates
all manifests and performs an isolated Codex marketplace install. Do not tag or
publish when it reports `DISTRIBUTION=INVALID`.

## Skill Architecture

The bundle ships four skills. All auto-fire; none are user-invoke-only.

**git-ops** owns every Git and GitHub operation: commit, push, tag, release,
wrap-up, branch, merge, rebase, and PR work. Its `SKILL.md` carries the
script-first fast paths and the authoritative safety rules; `references/` is
loaded on demand for non-routine decisions.

**repo-hygiene** owns repo cleanup and space reclaim in three tiers (read-only
report → safe `gc`/prune → gated history rewrite). It calls its own generated
copy of `git-stack.sh cleanup`.

**update-docs** owns CHANGELOG entries and doc patches (README, STATUS.md,
AGENTS/CLAUDE/GEMINI, `docs/`). It never commits, pushes, or tags.

**repo-prettifier** is a 4-phase interactive skill: research → positioning
interview → visual design decisions → write. Never write a README before
completing phases 1–3 with the user.

**`adapters/claude/commands/`** contains seven Claude slash commands that are
thin pointers into these skills — `commit`, `push`, `release`, `wrap-up`, and
`changelog` into `git-ops` or `update-docs`; `cleanup` into `repo-hygiene`.
They carry no procedure of their own. When a workflow changes, edit the skill,
not the command.

`repo-hygiene` and `update-docs` call the script's read-only reports
(`git-stack.sh cleanup` / `scan`), which return counts instead of raw git
output. Each calls its own generated copy at `scripts/git-stack.sh`, so no skill
depends on another skill's path.

Script subcommands: `commit|push|tag|release` write; `cleanup|scan` never do.
When adding a workflow, put the mechanical scan in the script and leave only
judgment in the skill.

## Key Safety Rules (apply to all skills in this bundle)

`skills/git-ops/SKILL.md` → "Safety rules" is the single authoritative list
(numbered 1–19). Do not restate rules here or in `references/` — a second copy
drifts. The highlights, for orientation only:

- Never commit directly to `main` — branch first
- Never rebase shared branches — rebase is for personal/local branches only
- Warn before any history rewrite (`rebase`, `reset --hard`, force push)
- Prefer `--force-with-lease` over `--force`
- Secrets never go in Git; `.env` must be in `.gitignore`

Thresholds and overrides (large files, `--allow-large`, `--allow-main`) live in
`scripts/git-stack.sh`, not in prose. Cite the script, don't copy its numbers.

## Installing / Using

Skills are installed via `apm`:

```bash
# Install git-ops globally
apm --mode skills install git-ops

# Install project-scoped
apm --mode skills --project-dir /path/to/project install git-ops
```

Commands (`commit.md`, `push.md`, `changelog.md`, `update-docs.md`,
`release.md`, `wrap-up.md`, `cleanup.md`) are Claude Code slash-command
pointers — they do not go through `apm`.

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
- Archive superseded versions in `_archive/versions/<skill>/` as `SKILL@x.y.z.md`.
  Skill folders ship only what a runtime loads — `SKILL.md`, `references/`, and
  `scripts/`. Do not add a `versions/` directory inside a skill.
