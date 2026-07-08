---
description: Safe local commit with pre-flight checks. Reviews secrets, paths, gitignore, large files, and message quality before committing.
version: 2.2.0
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[commit message]"
---

# /commit — Safe Local Commit

Thin orchestrator. Sequence and confirmation flow. Details in `skills/git-ops/references/core.md` (canonical rules/severity).

Goal: pre-flight → commit. Do NOT push.

## Delegate the mechanical work (default)

To keep the noisy `git status`/`diff`/scan output off your context, delegate to
the **`git-stack-runner`** subagent (Sonnet) via the Task tool. Pass:
`operation: commit`, the absolute repo path, the commit message (if given), and
any allowed non-noreply emails. It runs the sequence below headlessly and returns
a one-line verdict:
- **`VERDICT: DONE`** → relay COMMIT/PREFLIGHT to the user in the DONE box.
- **`VERDICT: BLOCKED`** → take its BLOCKERS list and run the `AskUserQuestion` modal yourself, then act on the choice.
- **`VERDICT: NOTHING-TO-DO`** → report clean, nothing to commit.

Run the steps below inline only if the agent is unavailable or the user asks to
see each check. Blocker decisions ALWAYS stay with you.

## Operating Principles
- **Consent**: The slash command is implicit consent; auto-run without confirming if clean/valid.
- **Blockers**: Stop and ask only for high-severity issues (see Blocker list) using `AskUserQuestion` modal.
- **Box Style**: Format recaps/blockers/done using left-border only (`┌─`, `│`, `└─`). No right border/corners.
- **Simplicity Test**: A change on `main` is "simple" if it is self-contained, non-breaking, and verified. If simple, commit silently with no warnings.

### What counts as a blocker (reasons to stop)
- **Branch**: Not on `main`/`master` (clarify intent).
- **Quality**: Breaking/unverified changes, or genuine commit message ambiguity.
- **Safety**: Staged secrets/API keys, `.env` files, or hardcoded `/Users/` or `/home/` paths.
- **Repos**: Stale directories staged (`_archive/`, `_backups/`, `node_modules/`, build output), missing `.gitignore`, or command errors.

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
Run checks below. Collect ALL findings first, then report together. Refer to `git-ops/references/core.md` for definitions.

- **2a. Secrets**: Scan added lines of staged diff (`'^+'` filter, exclude `'+++'` headers) using regex from `core.md`:
  ```bash
  git diff --cached | grep '^+' | grep -v '^+++' | grep -nE '<SECRET_RE from core.md>'
  ```
  Severity: HIGH. Block on match unless user overrides.
- **2b. `.env` files staged**:
  ```bash
  git diff --cached --name-only | grep -E "^\.env$|\.env\."
  ```
  Severity: HIGH.
- **2c. Hardcoded absolute paths**:
  ```bash
  git diff --cached | grep -E "(/Users/[a-zA-Z]+/|/home/[a-zA-Z]+/)" | grep -v "^---\|^+++" | head -20
  ```
  Severity: MEDIUM. Warn user.
- **2d. Large files**:
  ```bash
  git diff --cached --name-only | xargs -I{} find . -name "{}" -size +500k 2>/dev/null
  find . -not -path "./.git/*" -size +1M -not -path "./node_modules/*" 2>/dev/null | head -10
  ```
  Flag >500KB staged (MEDIUM). Warn >1MB in repo (INFO).
- **2e. `.gitignore` audit**: Verify `.gitignore` exists and covers `.env`, `node_modules/`, `*.log`, `_archive/`, `_backups/`.
- **2f. Unstaged changes**:
  ```bash
  git diff --stat
  ```
  Default to committing staged set as-is. List leftovers in DONE box. If blocked, offer to include them.
- **2g. Branch check**:
  ```bash
  git branch --show-current
  ```
  Block if not `main`/`master` (clarify intent). If simple on `main`, proceed silently.
- **2h. Author-email leak** (WARNING, not blocking):
  ```bash
  bash "${CLAUDE_SKILL_DIR}/scripts/check-author-email.sh" --staged
  ```
  Checks the configured `user.email` you're about to commit as. Exit `1` = a leak (personal email, `name@Host.local` machine default, or `noreply@github.com`). Surface it in the DONE box and offer the fix (`git config --global user.email "ID+username@users.noreply.github.com"` — see `core.md` → "Commit identity"), but do not hard-block a simple commit. See `core.md` → "Author-email leak check".

---

## Step 3 — Decide: proceed or stop
- **No blocker** → proceed to Step 4. Report MEDIUM/INFO notes in the final DONE box.
- **Any blocker** → stop once via `AskUserQuestion`. Present blockers in a left-border box.
  Modal options: **Unstage & commit rest** / **Commit anyway** / **Abort**.

---

## Step 4 — Commit message
If `$ARGUMENTS` is provided → use verbatim.
Otherwise:
- Read `git diff --cached`.
- Draft a Conventional Commits message per `core.md` (format, imperative mood, ≤72 chars).
- Only ask if the diff is genuinely ambiguous.

---

## Step 5 — Commit
```bash
git add -u   # only if user opted to include unstaged changes
git commit -m "<message>"
```
Show the DONE box with checklist:
```
┌─ COMMITTED
│ commit     abc1234  fix: correct auth token refresh
│ branch     feature/auth
│ files      3 changed, +42 −7
│ pre-flight [CLEAN] secrets · [CLEAN] paths · [CLEAN] large files · [CLEAN] gitignore
│ note       2 unstaged files left in working tree
└─
```

---

## Notes
- Patterns and severity definitions live in `git-ops/references/core.md`. If you spot drift between this command and core.md, core.md wins.
- For repos that intentionally back up config files containing secrets, see `git-ops/references/decisions.md` → clean-filter pattern. Skip 2a for those files.
