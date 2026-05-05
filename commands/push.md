---
description: Safe commit + push with full pre-flight checks. Reviews secrets, paths, gitignore, large files, branch safety, and remote state before committing and pushing.
allowed-tools: Bash, Read, Glob, Grep
argument-hint: "[commit message]"
---

# /push — Safe Commit + Push

Run all pre-flight checks, commit locally, then push to remote.

---

## Step 1 — Repo state

```bash
git status
git diff --cached --stat
git diff --stat
git remote -v
git branch --show-current
```

If there are no changes at all (clean working tree, nothing staged), skip to Step 6 (push only).

---

## Step 2 — Pre-flight checks

Run each check. Collect ALL findings before asking the user — do not interrupt mid-check.

### 2a. Secrets scan
Search staged and unstaged tracked files for patterns that look like secrets:
```bash
git diff HEAD | grep -iE "(api_key|api_secret|secret_key|access_token|auth_token|password|passwd|private_key|-----BEGIN|sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]+|AKIA[0-9A-Z]{16})" | head -30
```
Flag any matches as HIGH severity.

### 2b. .env files staged
```bash
git diff --cached --name-only | grep -E "^\.env$|\.env\."
```
Flag any `.env` file staged as HIGH severity. It should be in `.gitignore`.

### 2c. Hardcoded absolute paths
Search staged changes for hardcoded user paths:
```bash
git diff --cached | grep -E "(/Users/[a-zA-Z]+/|/home/[a-zA-Z]+/)" | grep -v "^---\|^+++" | head -20
```
Flag matches as MEDIUM severity — ask if intentional.

### 2d. Large files
```bash
git diff --cached --name-only | xargs -I{} find . -name "{}" -size +500k 2>/dev/null
```
Also check:
```bash
find . -not -path "./.git/*" -size +1M -not -path "./node_modules/*" 2>/dev/null | head -10
```
Flag files >500KB staged, and warn about any file >1MB in the repo.

### 2e. .gitignore check
```bash
cat .gitignore 2>/dev/null || echo "NO_GITIGNORE"
```
If no `.gitignore` exists, flag as MEDIUM — suggest creating one.
If `.gitignore` exists, check it covers common patterns: `.env`, `node_modules/`, `*.log`, `_archive/`, `_backups/`, `__pycache__/`, `.DS_Store`.
Report any commonly missing patterns.

### 2f. Unstaged changes left behind
```bash
git diff --stat
```
If there are unstaged changes on tracked files, show them and ask the user: **"You have unstaged changes — do you want to include them?"**
If yes, run `git add -u` before committing (do NOT use `git add .` unless user explicitly says so).

### 2g. Branch safety
```bash
git branch --show-current
```
If on `main` or `master`, warn: **"You are about to commit AND push directly to main — is this intentional?"**

---

## Step 3 — Remote state check

```bash
git fetch --dry-run 2>&1 || git fetch origin 2>&1
git status -sb
```

Check for:
- **Diverged history**: if local is behind remote, warn: "Remote has commits you don't have — consider pulling or rebasing first."
- **No remote set**: if no remote exists, warn and ask if user wants to add one.
- **No upstream branch**: if branch has no upstream, note that push will use `--set-upstream`.

---

## Step 4 — Report & confirm

Present a single summary block:

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

Then ask: **"Proceed with commit + push? (yes / fix first / abort)"**

- If "fix first": pause, let the user fix, then re-run checks from Step 2.
- If "abort": stop. Do not commit or push.
- If HIGH severity findings exist and user says "yes": confirm once more explicitly.

---

## Step 5 — Commit

If $ARGUMENTS is provided, use it verbatim as the commit message.

If $ARGUMENTS is empty:
- Run `git diff --cached` to read staged changes
- Write a concise conventional commit message: `type: summary` (e.g. `feat: add user auth`, `fix: correct path resolution`)
- Show the message to the user and ask: **"Commit with this message? (yes / edit)"**
- If "edit": ask for the message.

Then commit:
```bash
git add -u   # only if user confirmed unstaged changes in 2f
git commit -m "<message>"
```

Report: commit hash, branch, files changed.

---

## Step 6 — Push

```bash
git push
# or if no upstream:
git push --set-upstream origin <branch>
```

If push fails:
- **Rejected (non-fast-forward)**: explain the diverge, suggest `git pull --rebase` then re-push. Do NOT force push.
- **Auth error**: tell user to check credentials / SSH key.
- **Other error**: show raw error, do not retry automatically.

Report: remote URL, branch pushed, commit hash.
