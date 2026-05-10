# git-stack

Modular Git & GitHub skill bundle for Claude Code and Codex — orchestration, safe commits, PRs, and README prettification.

![License](https://img.shields.io/badge/license-MIT-blue)
![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-blueviolet)
![Codex](https://img.shields.io/badge/Codex-compatible-orange)
![Version](https://img.shields.io/badge/version-1.0.0-green)

## What's Inside

| Component | Invoked as | What it does |
|-----------|-----------|-------------|
| `git-guard` | `/git-stack:git-guard` | Orchestration layer for all Git/GitHub work — decision guide, atomic ops, multi-step workflows |
| `repo-prettifier` | `/git-stack:repo-prettifier` | Interactive README upgrade — positions, designs, and writes a high-converting README |
| `/commit` | `/commit` | Safe local commit with pre-flight checks (secrets, paths, large files, `.gitignore`) |
| `/push` | `/push` | Safe commit + push with remote state checks and branch safety warnings |
| `/changelog` | `/changelog` | Draft and write a CHANGELOG entry for changes since the last tag |
| `/update-docs` | `/update-docs` | Update CHANGELOG + all project docs (README, AGENTS, CLAUDE, GEMINI) after major changes |
| `/wrap-up` | `/wrap-up` | Full release wrap-up — version bump, changelog, README patches, commit, tag, push |

## Quick Start

### Claude Code — install from marketplace

```bash
/plugin marketplace add alexsmedile/git-stack
/plugin install git-stack@git-stack
```

Or open the interactive plugin manager:

```
/plugin
```

### Claude Code — test locally without installing

```bash
claude --plugin-dir ./
```

### Codex — install from GitHub

```bash
codex plugin install https://github.com/alexsmedile/git-stack
```

### Codex — install from local clone

```bash
codex plugin install ./git-stack
```

### Vercel skills — install via npx

```bash
npx skills add alexsmedile/git-stack
```

## Skills

### `git-guard`

The orchestration layer. Covers:

- **Atomic ops** — commit, branch, merge, rebase, stash, worktree
- **GitHub ops** — PRs, issues, releases, repo setup
- **Workflows** — feature, bugfix, refactor, release, hotfix sequences
- **Decision guide** — when to use what, risk table, common situation → action map

Reference files load on demand — only what's needed for the current task.

### `repo-prettifier`

Transforms a bare README into a high-converting project page. Works interactively in 4 phases:

1. Research the repo silently, form a point of view
2. Positioning interview — hooks, title options, audience, tone
3. Visual design decisions — style, badges, icons, callouts, ASCII trees
4. Write `README2.md` for review, then replace on confirmation

## Commands

### `/commit`

Safe local commit. Runs before writing anything:

- Secrets scan (API keys, tokens, private keys)
- `.env` detection
- Hardcoded absolute path detection
- Large file check (>500KB staged, >1MB in repo)
- `.gitignore` audit
- Unstaged changes prompt
- Branch safety warning (main/master)

Presents a single `PRE-FLIGHT REPORT` block, then asks to proceed.

### `/push`

Everything `/commit` does, plus:

- Remote state check (fetch dry-run)
- Diverged history warning
- Upstream branch detection
- Push with `--set-upstream` when needed

### `/changelog`

Drafts a [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) entry for all commits since the last tag. Auto-detects version bump (major/minor/patch) from change type. Confirms before writing.

### `/update-docs`

Updates CHANGELOG.md plus all project docs (README, AGENTS.md, CLAUDE.md, GEMINI.md) that exist in the repo. Resolves symlinks and edits the real file. Shows a diff-style preview per doc, confirms before writing anything.

### `/wrap-up`

Full release in one command: version bump → changelog → README patches → pre-flight checks → commit → optional tag → push. One confirm gate before any writes.

## Safety Rules

All skills in this bundle enforce:

- Never commit directly to `main` — branch first
- Never rebase shared branches
- Warn before any history rewrite
- Prefer `--force-with-lease` over `--force`
- Secrets never go in Git

## Requirements

- `git` CLI
- `gh` CLI (for GitHub operations) — verify with `gh auth status`

## After Install

Skills are namespaced: `/git-stack:skill-name`

To update after pushing changes:

```
/plugin marketplace update git-stack
```

## License

MIT
