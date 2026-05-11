# git-stack / core — Git Fundamentals

This file covers the atomic Git skills: the building blocks every workflow uses.
Each skill includes purpose, key commands, guardrails, and when to use it.

---

## Mental model

```
local machine  = your workspace (where you code)
Git            = the history engine (tracks every change)
GitHub         = the shared remote (backup, sync, collaboration)
```

The three things you do:
- **commit** → save a snapshot into Git history
- **push** → upload history to GitHub
- **pull/fetch** → download history from GitHub

---

## git-stack.core.commit

**Purpose:** Save a logical unit of work as a permanent snapshot in history.

**When to use:** After completing any self-contained change — a feature, a fix,
a refactor step, a docs update. Not before. Not "when you remember to."

**The rule:** One commit = one clear story. If you can't describe it in one line,
split it.

```bash
# Stage specific files (preferred over git add .)
git add src/auth.ts tests/auth.test.ts

# Stage all tracked changes
git add -A

# Commit with message (Conventional Commits format)
git commit -m "feat(auth): add JWT token refresh logic"

# Amend last commit before pushing (fix message or add missed file)
git commit --amend --no-edit       # keep message, add staged changes
git commit --amend -m "new msg"    # change message only
```

**Message format:** `type(scope): short description`
Types: `feat` `fix` `docs` `refactor` `test` `chore` `perf` `ci`

**Multi-line commit with body:**
```bash
git commit -m "fix(auth): prevent token refresh loop on every request

The expiry check compared timestamps without accounting for clock skew.
Added a 30-second buffer to the comparison.

Closes #88"
```

**Guardrails:**
- Never commit: `.env`, `node_modules/`, build output, secrets, large binaries
- Keep subject line ≤ 72 characters
- Use imperative mood: "add" not "added", "fix" not "fixed"
- Body (optional) explains *why*, not *what*; blank line between subject and body

### Secrets / API key scan

Run BEFORE every commit. Catches accidental commits of provider keys, GitHub tokens, AWS access keys, private key blocks, etc.

```bash
# Scan staged diff for known secret patterns
git diff --cached | grep -nE '(sk-proj-[A-Za-z0-9_-]{40,}|sk-ant-[a-z0-9-]+-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{40,}|jina_[A-Za-z0-9]{40,}|tvly-(dev-|prod-)?[A-Za-z0-9_-]{20,}|apify_api_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{30,}|xoxb-[A-Za-z0-9-]{20,}|hf_[A-Za-z0-9]{30,}|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----)'
```

Coverage:

| Pattern              | Vendor                     |
|----------------------|----------------------------|
| `sk-proj-…`          | OpenAI project keys        |
| `sk-ant-…`           | Anthropic                  |
| `sk-…`               | OpenAI legacy / generic    |
| `jina_…`             | Jina AI                    |
| `tvly-dev-…` / `tvly-prod-…` | Tavily                |
| `apify_api_…`        | Apify                      |
| `ghp_…` / `gho_…` / `github_pat_…` | GitHub tokens (classic / OAuth / fine-grained) |
| `AKIA…`              | AWS access key IDs         |
| `AIza…`              | Google API keys            |
| `xoxb-…`             | Slack bot tokens           |
| `hf_…`               | Hugging Face               |
| `-----BEGIN ... PRIVATE KEY-----` | RSA/EC/OpenSSH/PGP private key blocks |

If any pattern matches: STOP. Either (a) remove the value, (b) move it to a gitignored file + reference via env var, or (c) set up a git clean filter (see `decisions.md` → "I want to back up a config file that always contains secrets").

### Installing the secret-block hook (per-repo)

git-guard ships a reusable pre-commit hook at `scripts/pre-commit-block-secrets.sh` that runs the same pattern set above. To install it in a repo without modifying anything automatically, use the preview installer:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/install-hooks.sh" /path/to/repo
```

This prints the exact `cp` or `ln -s` command to run. Two modes:

- **Copy**: snapshots the hook script into `.git/hooks/pre-commit`. Survives git-guard upgrades; behavior is frozen at install time.
- **Symlink**: `ln -sf` from `.git/hooks/pre-commit` to the skill's script. Auto-picks up new patterns when git-guard updates.

Caveat: `.git/hooks/` is **not versioned by git**. Clones do not inherit hooks — every contributor runs the installer themselves. Document this in the project's README or `CONTRIBUTING.md`.

To bypass for one commit (e.g., emergency hotfix where the false positive can be re-flagged in a follow-up): `git commit --no-verify`. Never make this a habit.

### Repo-wide secret audit (on request)

Run when the user asks to **audit a repo for leaks**, **check for committed secrets**, or before opening a repo to the public. Three passes:

```bash
# Shared pattern (export once)
SECRET_RE='(sk-proj-[A-Za-z0-9_-]{40,}|sk-ant-[a-z0-9-]+-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{40,}|jina_[A-Za-z0-9]{40,}|tvly-(dev-|prod-)?[A-Za-z0-9_-]{20,}|apify_api_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{30,}|xoxb-[A-Za-z0-9-]{20,}|hf_[A-Za-z0-9]{30,}|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----)'

# 1. Currently tracked files (the live working tree, only files git knows about)
git ls-files -z | xargs -0 grep -nHE "$SECRET_RE" 2>/dev/null

# 2. All env / config files in the working tree (tracked OR ignored — catches misconfigured .gitignore)
find . -type f \( -name '.env*' -o -name '*.env' -o -name 'config.toml' -o -name 'settings.json' -o -name 'secrets.*' -o -name '*.pem' -o -name '*.key' \) -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null \
  | xargs grep -nHE "$SECRET_RE" 2>/dev/null

# 3. Full git history (every blob ever committed, on every branch)
git log --all -p -- . | grep -nE "$SECRET_RE"
```

Reporting:

| Finding location              | Severity | Action                                                          |
|-------------------------------|----------|-----------------------------------------------------------------|
| Working tree, NOT in `.gitignore` | HIGH | Rotate key, gitignore the file, restore-from-env pattern         |
| Working tree, gitignored      | LOW      | OK if intentional (local dev). Mention it.                       |
| Git history (any past commit) | CRITICAL | **Rotate immediately**, then `git filter-repo` to scrub, force-push, notify collaborators |

Common false positives: example/template files (`*.example`, `*.template`), test fixtures, and documentation strings showing placeholder formats. Confirm before flagging.

The history scan is slow on large repos — warn the user and offer to scope it: `git log --all -p -- path/to/dir | grep …`.

---

## git-stack.core.branch

**Purpose:** Isolate a line of work from the stable codebase.

**When to use:** Always, before starting any change. Every feature, fix, or
experiment gets its own branch. This protects main and lets you work freely.

**Naming convention:**
```
feat/login-flow
fix/payment-null-error
refactor/api-client
docs/setup-guide
chore/update-deps
```

```bash
# Create and switch in one step (preferred)
git switch -c feat/my-feature

# Push and track remote
git push -u origin feat/my-feature

# List branches
git branch -a               # local + remote
git branch --merged         # branches merged into current

# Delete after merge
git branch -d feat/my-feature           # local (safe — blocked if unmerged)
git push origin --delete feat/my-feature # remote
```

**Guardrails:**
- Never work directly on `main` or `master`
- Keep branches short-lived (days, not weeks)
- Rebase onto main frequently to avoid drift

---

## git-stack.core.merge

**Purpose:** Join two branches — bring a feature/fix into the main line.

**When to use:** When a branch is ready and reviewed. Usually done via PR on
GitHub (preferred) rather than a local merge.

```bash
# Merge feature into current branch
git switch main
git merge feat/my-feature

# Fast-forward only (cleaner, but fails if histories diverged)
git merge --ff-only feat/my-feature

# Merge with explicit commit (preserves branch history)
git merge --no-ff feat/my-feature

# Abort a merge in progress
git merge --abort
```

**Conflict resolution:**
```bash
# After conflicts appear:
# 1. Open conflicted files, look for <<<<<<< markers
# 2. Edit to the correct final state
# 3. Stage resolved files
git add <file>
# 4. Complete the merge
git merge --continue
```

**Guardrails:**
- Prefer PRs on GitHub over direct local merges — enables review and CI
- Use `--no-ff` on `main` when you want to preserve branch history
- Resolve all conflicts before committing

---

## git-stack.core.rebase

**Purpose:** Replay your commits on top of an updated base — keeps history linear
and avoids merge commits.

**When to use:**
- Syncing a personal feature branch with main before a PR
- Cleaning up messy commits before sharing (interactive rebase)

**When NOT to use:** On any branch that other people have already pulled.
Rewriting shared history creates chaos.

```bash
# Rebase current branch onto updated main
git fetch origin
git rebase origin/main

# Interactive rebase — rewrite/squash/reorder last N commits
git rebase -i HEAD~4
# In the editor: pick / squash / fixup / drop / reword

# During rebase, when conflicts appear:
git add <resolved-file>
git rebase --continue

# Abort if something goes wrong
git rebase --abort
```

**Interactive rebase actions:**
| Action | Effect |
|--------|--------|
| `pick` | Keep commit as-is |
| `squash` | Fold into previous, combine messages |
| `fixup` | Fold into previous, discard message |
| `reword` | Keep changes, edit message |
| `drop` | Remove commit entirely |

**Guardrails:**
- Rule: personal branch → rebase freely. Shared branch → use merge instead.
- After rebase, push requires `--force-with-lease` (never plain `--force`)
- Warn users before rebasing: "this rewrites history"

---

## git-stack.core.stash

**Purpose:** Temporarily shelve uncommitted work without making a commit.

**When to use:** When you need to context-switch (urgent fix, pull needed) but
your current work isn't commit-ready.

```bash
# Stash current changes (tracked files)
git stash

# Stash with a descriptive name
git stash push -m "WIP: half-done auth refactor"

# Include untracked files
git stash push -u

# List stashes
git stash list

# Apply most recent stash (keep it in stash list)
git stash apply

# Apply and remove from list
git stash pop

# Apply a specific stash
git stash apply stash@{2}

# Drop a stash
git stash drop stash@{0}

# Clear all stashes
git stash clear
```

**Guardrails:**
- Stash is a temporary holding area, not an archive. Don't let stashes sit for days.
- Always name your stash — `git stash list` becomes unreadable without names
- If stash pop causes conflicts, resolve them the same as merge conflicts

---

## git-stack.core.worktree

**Purpose:** Check out multiple branches of the same repo into separate
directories simultaneously — true parallel work without constant checkout switching.

**When to use:** When you genuinely need two branches active at the same time:
- Working on a feature while handling a hotfix
- Running an AI agent on a separate branch in its own folder
- Comparing two implementations side by side

```bash
# Add a worktree for an existing branch
git worktree add ../my-app-hotfix hotfix/critical-bug

# Add a worktree and create a new branch
git worktree add -b feat/auth ../my-app-auth

# List active worktrees
git worktree list

# Remove a worktree (after you're done)
git worktree remove ../my-app-hotfix

# Prune stale worktree references
git worktree prune
```

**Example layout:**
```
~/code/my-app/              → main branch (primary)
~/code/my-app-auth/         → feat/auth (in development)
~/code/my-app-hotfix/       → hotfix/prod (urgent fix)
```

**Guardrails:**
- Each branch can only be checked out in one worktree at a time
- Worktrees share the same `.git` directory — commits in any worktree are visible everywhere
- Clean up worktrees when done (`git worktree remove`)

---

## Inspection commands (understand before acting)

Always orient yourself before making changes:

```bash
# Current state of working tree
git status

# What changed in files (unstaged)
git diff

# What's staged and ready to commit
git diff --staged

# Commit history
git log --oneline -20
git log --oneline --graph --all   # visual branch history

# Who changed what (per line)
git blame <file>

# Find when a bug was introduced
git bisect start
git bisect bad           # current commit is broken
git bisect good v1.0.0   # this tag was good
# Git checks out midpoints — test and mark good/bad until found
git bisect reset
```

---

## History rewriting — squash all commits into one clean root

**When to use:** Before publishing a repo publicly when early commits contain
personal data, wrong author identity, or sensitive paths you want gone from
history entirely. Also useful when a repo's full history is noise and you want
a single clean starting point.

**The orphan branch technique** is the safest approach — cleaner than
`git rebase -i` (which can leave dangling refs) and simpler than
`git filter-branch` (slow, error-prone).

```bash
# Step 1 — fix your files first (the current working tree must be clean)
# Edit anything that needs changing, stage it all

# Step 2 — create an orphan branch (no parent commits, all files staged)
git checkout --orphan clean-main

# Step 3 — single root commit with correct author
git commit -m "feat: initial release — v1.0.0"

# Step 4 — replace main with the orphan branch
git branch -M clean-main main

# Step 5 — force push (rewrites remote history)
git push --force-with-lease origin main
```

**If you also have tags pointing to old commits:**
```bash
# Delete the old tag locally and remotely
git tag -d v1.0.0
git push origin :v1.0.0

# Re-create tag on the new clean commit
git tag v1.0.0
git push origin v1.0.0
```

**Guardrails:**
- Only do this on repos where you control all forks/clones — rewrites break
  anyone who has already pulled the old history
- Always verify the working tree is exactly what you want before the orphan
  commit — there's no going back without the old commits
- `--force-with-lease` is safer than `--force` but will still be rejected if
  the remote moved since your last fetch; run `git fetch` first if unsure

---

## Undo operations

```bash
# Undo last commit, keep changes staged
git reset --soft HEAD~1

# Undo last commit, unstage changes (keep files)
git reset HEAD~1

# DESTRUCTIVE: discard all local changes
git restore .                  # discard unstaged changes
git reset --hard HEAD          # reset to last commit

# Recover a deleted branch (within reflog window ~30 days)
git reflog
git switch -c recovered-branch <sha>

# Revert a commit (safe — creates a new undo commit)
git revert <commit-sha>
```
