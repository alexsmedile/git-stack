---
description: Safe commit + push with full pre-flight checks. Reviews secrets, paths, gitignore, large files, branch safety, and remote state before committing and pushing.
version: 2.0.0
allowed-tools: Bash, Read, Glob, Grep
argument-hint: "[commit message]"
---

# /push — Safe Commit + Push

Thin orchestrator. Owns the **sequence and confirmation flow**. Delegates **what to check** to the `git-guard` skill — load `skills/git-guard/references/core.md` and apply the rules defined there.

Goal: pre-flight → report → confirm → commit → push.

---

## Step 1 — Repo state

```bash
git status
git diff --cached --stat
git diff --stat
git remote -v
git branch --show-current
```

If clean working tree and nothing staged → skip to Step 6 (push only).

---

## Step 2 — Pre-flight checks

Run all checks defined in `/commit` Step 2 (same canonical list from `git-guard/references/core.md`):

- 2a. Secrets / API keys — pattern from git-guard core.md → "Secrets / API key scan"
- 2b. `.env` files staged
- 2c. Hardcoded absolute paths
- 2d. Large files
- 2e. `.gitignore` audit
- 2f. Unstaged changes
- 2g. Branch safety (rule #1: never push directly to `main`)

Collect ALL findings before asking the user.

---

## Step 3 — Remote state

```bash
git fetch --dry-run 2>&1 || git fetch origin 2>&1
git status -sb
```

Apply rules from `git-guard/SKILL.md`:
- Rule #6: `git fetch` before any merge/rebase. Always.
- **Diverged history**: if local is behind remote, warn — suggest pull/rebase first. Do NOT force push (rule #4: `--force-with-lease` only).
- **No remote**: warn, ask if user wants to add one.
- **No upstream**: note that push will use `--set-upstream`.

---

## Step 4 — Report & confirm

```
PRE-FLIGHT REPORT
─────────────────
[HIGH]   .env file staged — should be in .gitignore
[MEDIUM] Hardcoded path found: /Users/username/... in src/config.py
[MEDIUM] Remote is 2 commits ahead — consider pulling first
[INFO]   .gitignore missing: .DS_Store, __pycache__/
[INFO]   Branch: main — pushing directly to main

Staged: 3 files changed, 42 insertions, 7 deletions
Remote: origin → git@github.com:user/repo.git
```

Ask: **"Proceed with commit + push? (yes / fix first / abort)"**

- `fix first`: pause, re-run Step 2 after fixes.
- `abort`: stop. No commit, no push.
- `yes` with HIGH findings: confirm once more explicitly.

---

## Step 5 — Commit

If `$ARGUMENTS` is provided → use verbatim.

Otherwise draft a Conventional Commits message per `git-guard/references/core.md` → "git-stack.core.commit" and confirm with the user.

```bash
git add -u   # only if user confirmed unstaged changes in 2f
git commit -m "<message>"
```

Report: commit hash, branch, files changed.

---

## Step 6 — Push

```bash
git push
# or, if no upstream:
git push --set-upstream origin <branch>
```

If push fails, follow `git-guard/references/decisions.md`:
- **Rejected (non-fast-forward)**: diverged — `git pull --rebase` then re-push. Never force-push to shared branches.
- **Auth error**: check credentials / SSH key / `gh auth status`.
- **Other**: show raw error, do not auto-retry.

Report: remote URL, branch pushed, commit hash.

---

## Notes

- This command and `/commit` share Step 2 by design. Patterns live in `git-guard/references/core.md` — update there, both inherit.
- For force-push scenarios, see `git-guard/references/decisions.md` → "I need to force push" (always `--force-with-lease`, never to shared branches).
