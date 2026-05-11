---
description: Safe local commit with pre-flight checks. Reviews secrets, paths, gitignore, large files, and message quality before committing.
version: 2.0.0
allowed-tools: Bash, Read, Glob, Grep
argument-hint: "[commit message]"
---

# /commit — Safe Local Commit

Thin orchestrator. Owns the **sequence and confirmation flow**. Delegates **what to check** to the `git-guard` skill — load `skills/git-guard/references/core.md` and apply the rules defined there.

Goal: pre-flight → report → confirm → commit. Do NOT push.

---

## Step 1 — Repo state

```bash
git status
git diff --cached --stat
git diff --stat
```

If clean working tree and nothing staged → stop, tell the user. Nothing to commit.

---

## Step 2 — Pre-flight checks

Run each check below. **Collect ALL findings before asking the user — do not interrupt mid-check.**

Each check links to its canonical definition in git-guard. If you've already loaded `git-guard/references/core.md` for this turn, reuse the patterns and severity tables from there.

### 2a. Secrets / API keys
Use the regex from `git-guard/references/core.md` → "Secrets / API key scan". Scan ADDED lines only of the staged diff (`'^+'` filter, exclude `'+++'` headers) so cleanup commits removing previously-leaked secrets are NOT flagged:
```bash
git diff --cached | grep '^+' | grep -v '^+++' | grep -nE '<SECRET_RE from core.md>'
```
Severity: HIGH. Block on match unless user explicitly overrides.

### 2b. `.env` files staged
```bash
git diff --cached --name-only | grep -E "^\.env$|\.env\."
```
Severity: HIGH. `.env` belongs in `.gitignore`.

### 2c. Hardcoded absolute paths
```bash
git diff --cached | grep -E "(/Users/[a-zA-Z]+/|/home/[a-zA-Z]+/)" | grep -v "^---\|^+++" | head -20
```
Severity: MEDIUM. Ask if intentional.

### 2d. Large files
```bash
git diff --cached --name-only | xargs -I{} find . -name "{}" -size +500k 2>/dev/null
find . -not -path "./.git/*" -size +1M -not -path "./node_modules/*" 2>/dev/null | head -10
```
Flag >500KB staged. Warn about >1MB in repo.

### 2e. `.gitignore` audit
Per `git-guard/SKILL.md` rule #9: `.gitignore` must exist before the first commit on any new repo. Verify it covers `.env`, `node_modules/`, `*.log`, `_archive/`, `_backups/`, `__pycache__/`, `.DS_Store`.

### 2f. Unstaged changes
```bash
git diff --stat
```
If unstaged changes exist on tracked files: ask **"You have unstaged changes — include them?"** Use `git add -u` if yes, never `git add .` unless explicit.

### 2g. Branch safety
Per `git-guard/SKILL.md` rule #1: never commit directly to `main`. If `git branch --show-current` returns `main` or `master`, warn explicitly.

---

## Step 3 — Report & confirm

Single summary block:

```
PRE-FLIGHT REPORT
─────────────────
[HIGH]   .env file staged — should be in .gitignore
[MEDIUM] Hardcoded path found: /Users/username/... in src/config.py
[INFO]   .gitignore missing: .DS_Store, __pycache__/
[INFO]   Branch: main — committing directly

Staged: 3 files changed, 42 insertions, 7 deletions
```

Ask: **"Proceed with commit? (yes / fix first / abort)"**

- `fix first`: pause, let user fix, re-run Step 2.
- `abort`: stop.
- `yes` with HIGH findings: confirm once more explicitly.

---

## Step 4 — Commit message

If `$ARGUMENTS` is provided → use verbatim.

Otherwise:
- Read `git diff --cached`.
- Draft Conventional Commits message per `git-guard/references/core.md` → "git-stack.core.commit" (format, types, imperative mood, ≤72 chars).
- Show and ask: **"Commit with this message? (yes / edit)"**

---

## Step 5 — Commit

```bash
git add -u   # only if user confirmed unstaged changes in 2f
git commit -m "<message>"
```

Report: commit hash, branch, files changed. Do NOT push.

---

## Notes

- Patterns and severity definitions live in `git-guard/references/core.md`. If you spot drift between this command and core.md, core.md wins.
- For repos that intentionally back up config files containing secrets, see `git-guard/references/decisions.md` → "I want to back up a config file that always contains secrets" (clean-filter pattern). Skip 2a for those files.
