---
name: git-ops
description: >-
  Focused execution and postcondition validation engine for Git & GitHub operations.
  Triggers on "commit", "push", "ship", "worktrees", "branches", "branch topology",
  "merge", "rebase", "tag", "release", "wrap-up", or when executing repository mutations.
metadata:
  version: "1.13.0"
---

# git-ops

Execute selected operations with local judgment and postcondition verification. Native `git`/`gh` are default; use `git-stack.sh` for compact fast-paths.

## Entry & Routing

- **Entry**: Accepts pre-verified repository boundaries or handoffs from `repo-governance`. General conversational requests enter via `repo-governance`.
- **Halt Condition**: If uncommitted collisions, divergence, or interrupted markers appear, halt immediately and route to governance `recover`.

## Operation Fast Paths

```bash
GIT_STACK="${CLAUDE_SKILL_DIR:-<skill-dir>}/scripts/git-stack.sh"
bash "$GIT_STACK" ship --execute --message "..." # atomic fast-lane: commit + push + post-verify
bash "$GIT_STACK" commit                         # exit 0: CLEAN, 1: BLOCKED, 2: NOTHING_TO_DO
bash "$GIT_STACK" push                           # check upstream and remote freshness
bash "$GIT_STACK" tag --version 1.2.3            # annotated release tag + optional --publish-tag
bash "$GIT_STACK" scan                           # conventional commit scan since last tag
bash "$GIT_STACK" worktrees --visual             # active worktrees map
bash "$GIT_STACK" branches --visual              # branch ahead/behind status & upstream sync
bash "$GIT_STACK" topology                       # ASCII branch hierarchy and stack topology
```

| Operation | Pre-conditions | Execution & Script Path | Post-condition Verify |
|---|---|---|---|
| `ship` | Staged changes, upstream tracked | `git-stack.sh ship --execute --message "..."` | Atomic commit + push; `HEAD == @{upstream}` |
| `commit` | Feature branch, clean index, `.gitignore` | `git-stack.sh commit --execute --message "..."` | Commit created; report residual unstaged count |
| `push` | Upstream tracked, no divergence | `git-stack.sh push --execute` (force-push blocked) | Remote ref equals local HEAD |
| `merge` | Target branch checked, clean working tree | `--ff-only` for linear stacks; `--no-ff` for true branches | Target contains source; offer `git branch -d` |
| `tag/release` | Clean release branch, manifests aligned | `git-stack.sh tag --version X.Y.Z` | Annotated tag matches HEAD; GitHub release if requested |
| `worktrees` | Git repository | `git-stack.sh worktrees --visual` | Active worktree map rendered |
| `branches` | Git repository | `git-stack.sh branches --visual` | Branch upstream & status rendered |
| `topology` | Git repository | `git-stack.sh topology` | ASCII branch stack hierarchy rendered |

## Report Format

Emit one left-border box inside a fenced `text` block upon completion:

```text
┌─ SHIPPED · feat/login · a1b2c3d
│ commit   a1b2c3d  feat: add password reset flow
│ push     feat/login -> origin/feat/login
│ status   clean · verified
└─

┌─ COMMITTED · feat/login · 3 files
│ commit   a1b2c3d  feat: add password reset flow
│ files    3 changed, +82 -14
│ next     push when requested
└─
```

For worktrees, branches, and topology:

```text
┌─ WORKTREES · 2 active trees
│  ● main        .             clean       (at c3f1a2b · docs: update roadmap)
│  ○ feat/login  ../wt-login   dirty (+3)  (at a8e4120 · feat: oauth callback)
└─

┌─ BRANCHES · default: main
│  ● feat/visuals  ahead 2            [origin/feat/visuals]  clean
│  ○ feat/login    ahead 1 · behind 4 [origin/feat/login]    [worktree: ../wt-login]
│  ○ fix/memory    merged into main   (safe to prune)
└─

┌─ BRANCH TOPOLOGY
│  main (origin/main)
│  ├─● feat/visuals (ahead 2)
│  └─○ feat/login (ahead 1 · behind 1)
│      └─○ feat/oauth-providers (ahead 3) [stacked]
└─
```

## Direct Negative Constraints ("DO NOT")

- **DO NOT commit directly to trunk (`main`/`master`)** without explicit `--allow-main`.
- **DO NOT rewrite shared history**. Rebase, squash, and amend only `PRIVATE` or authorized `PUBLISHED_SOLO` with lease protection.
- **DO NOT stage generated artifacts** (`.env*`, `node_modules/`, `dist/`, `build/`, `_archive/`).
- **DO NOT push when diverged or behind upstream**. Integrate and resolve locally first.
- **DO NOT stash when switching workstreams** if uncommitted work belongs to an active worktree.
- **DO NOT resolve merge conflicts directly on default branch**. Resolve in feature branch, verify tests, then advance trunk.
