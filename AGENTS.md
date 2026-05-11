# AGENTS.md

This file provides guidance to AI agents (Claude Code, Codex, Gemini) when working with code in this repository.

## What This Is

`git-stack` is a skill bundle containing Git/GitHub skills and slash commands for Claude Code. It lives inside the `skills_db` vault and is managed by `apm`. It is **not** a software project — there is no build, test, or lint pipeline.

## Structure

```
git-stack/
├── skills/
│   ├── git-guard/          # Main orchestration skill (load references on demand)
│   │   ├── SKILL.md        # Entry point — domain map and safety rules
│   │   └── references/     # Load only what's needed for the task
│   │       ├── core.md     # Atomic Git ops: commit, branch, merge, rebase, stash, worktree
│   │       ├── github.md   # GitHub ops: PR, issues, releases, repo setup
│   │       ├── workflows.md # End-to-end sequences: feature, bugfix, release, hotfix
│   │       └── decisions.md # When to use what — situational decision guide
│   └── repo-prettifier/      # README improvement skill (interactive, 4-phase)
│       └── SKILL.md
└── commands/
    ├── commit.md           # /commit — safe local commit with pre-flight checks
    ├── push.md             # /push — safe commit + push with pre-flight checks
    ├── changelog.md        # /changelog — draft and write a CHANGELOG entry
    ├── update-docs.md      # /update-docs — changelog + all project docs update
    └── wrap-up.md          # /wrap-up — full release wrap-up (version, changelog, commit, tag, push)
```

`_archive/` contains superseded versions — do not modify or reference them.

## Skill Architecture

**git-guard** is the master orchestration skill. It separates:
- **Atomic skills** (`git-stack.core.*`) — one operation, one responsibility
- **Workflows** (`git-stack.workflow.*`) — sequenced multi-step operations

Reference files are loaded on demand — only read the one(s) relevant to the current task. The skill naming convention is `git-stack.<domain>.<skill>` (e.g. `git-stack.core.commit`, `git-stack.github.pr-create`).

**repo-prettifier** is a 4-phase interactive skill: research → positioning interview → visual design decisions → write. Never write a README before completing phases 1–3 with the user.

**commands/** are slash commands (not skills). `commit.md` and `push.md` are **thin orchestrators** — they own the sequence and confirmation flow, while `git-guard/references/core.md` owns the canonical pattern definitions and severity rules (secrets scan, `.env` detection, hardcoded path scan, large file check, `.gitignore` audit, unstaged changes prompt, branch safety warning). Update patterns in core.md once, both commands inherit. `changelog.md` drafts changelog entries. `update-docs.md` updates CHANGELOG, README, AGENTS, CLAUDE, and GEMINI docs. `wrap-up.md` orchestrates a full release (version bump → docs → commit → tag → push). All checks run before asking the user — never interrupt mid-check.

## Key Safety Rules (apply to all skills in this bundle)

- Never commit directly to `main` — branch first
- Never rebase shared branches — rebase is for personal/local branches only
- Warn before any history rewrite (`rebase`, `reset --hard`, force push)
- Prefer `--force-with-lease` over `--force`
- Secrets never go in Git; `.env` must be in `.gitignore`

## Installing / Using

Skills are installed via `apm`:

```bash
# Install git-guard globally
apm --mode skills install git-guard

# Install project-scoped
apm --mode skills --project-dir /path/to/project install git-guard
```

Commands (`commit.md`, `push.md`, `changelog.md`, `update-docs.md`, `wrap-up.md`) are slash commands invoked directly in Claude Code — they do not go through `apm`.

## Editing Skills

- Keep `SKILL.md` under 500 lines
- Reference files go in `references/` — they are loaded on demand, not auto-loaded
- Version bumps: patch for fixes, minor for new behavior, major for rewrites
- Update `version:` in frontmatter on every meaningful change
- Archive superseded versions in `versions/` as `SKILL@x.y.z.md` (do not put in `_archive/`)
