---
description: Safe local commit with pre-flight checks. Reviews secrets, paths, gitignore, large files, and message quality before committing.
version: 1.0.0
allowed-tools: Bash, Read, Glob, Grep
argument-hint: "[commit message]"
---

# /commit — Safe Local Commit

Run all pre-flight checks, then commit locally. Do NOT push.

---

## Step 1 — Repo state

```bash
git status
git diff --cached --stat
git diff --stat
```

If there are no changes at all (clean working tree, nothing staged), stop and tell the user. Nothing to commit.

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

### 2g. Branch check
```bash
git branch --show-current
```
If on `main` or `master`, warn: **"You are committing directly to main — is this intentional?"**

---

## Step 3 — Report & confirm

Present a single summary block:

```
PRE-FLIGHT REPORT
─────────────────
[HIGH]   .env file staged — should be in .gitignore
[MEDIUM] Hardcoded path found: /Users/username/... in src/config.py
[INFO]   .gitignore missing: .DS_Store, __pycache__/
[INFO]   Branch: main — committing directly

Staged: 3 files changed, 42 insertions, 7 deletions
```

Then ask: **"Proceed with commit? (yes / fix first / abort)"**

- If "fix first": pause, let the user fix, then re-run checks from Step 2.
- If "abort": stop. Do not commit.
- If HIGH severity findings exist and user says "yes": confirm once more explicitly.

---

## Step 4 — Commit message

If $ARGUMENTS is provided, use it verbatim as the commit message.

If $ARGUMENTS is empty:
- Run `git diff --cached` to read staged changes
- Write a concise conventional commit message: `type: summary` (e.g. `feat: add user auth`, `fix: correct path resolution`)
- Show the message to the user and ask: **"Commit with this message? (yes / edit)"**
- If "edit": ask for the message.

---

## Step 5 — Commit

```bash
git add -u   # only if user confirmed unstaged changes in 2f
git commit -m "<message>"
```

Report: commit hash, branch, files changed.

Do NOT push.
