---
description: Safe local commit with pre-flight checks. Reviews secrets, paths, gitignore, large files, and message quality before committing.
version: 2.1.0
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[commit message]"
---

# /commit — Safe Local Commit

Thin orchestrator. Owns the **sequence and confirmation flow**. Delegates **what to check** to the `git-guard` skill — load `skills/git-guard/references/core.md` and apply the rules defined there.

Goal: pre-flight → commit. Do NOT push.

## Operating principle — don't re-ask for consent

The user typed `/commit`. That **is** the instruction to commit — treat it as consent already given and proceed straight to the work.

- **Session clean, files good → just commit.** No confirm step. Show the DONE box after.
- **Stop ONLY when something is truly off** (see "What counts as a blocker" below).
- When you must stop, surface it through the **`AskUserQuestion` interactive modal** (keep all confirmations in the modal, never in inline text).
- All output that needs the user's eyes (recap, blocker, done) goes in a **box** — see "Box style".

### The simplicity test — what stays simple, stays simple

The guiding rule: **what's simple stays simple; what's outside simplicity needs clarity first.**

A change is **simple** when all of these hold:
- self-contained — the commit stands on its own
- non-breaking — doesn't break the build or anything else
- verified / works — it's been validated, not a guess
- on `main` — the session started and ended on `main` with a few non-breaking edits

A simple change on `main` → **commit, no questions, no warning.** Committing to `main` is not a blocker and not even worth a note when the change is simple. This is the common case — keep it frictionless.

### What counts as a blocker (the only reasons to stop)

Stop only when the change steps **outside simplicity**, or something is wrong, missing, or incoherent:

- **Not on `main`** — on any branch other than `main`/`master`, stop and clarify intent via `AskUserQuestion` (is this the right branch? open a PR? merge target?). A non-default branch is outside the simple path by definition.
- **Breaking / unverified change** — touches behavior in a way that could break the build or other code, or hasn't been verified. Clarify before committing.
- **Personal / secret files** — `.env`, credentials, keys, tokens, or an unintentional hardcoded `/Users/<name>/` path.
- **Stale / outdated folders staged** — `_archive/`, `_backups/`, `node_modules/`, build output that shouldn't ship.
- **Errors** — a failed check, a command that errored, a broken/missing file the commit references.
- **Missing files** — `.gitignore` absent on a repo that needs one; a staged symlink with no target.
- **Version / manifest mismatch** — version-bearing files disagree (more relevant to /wrap-up, but flag if seen).
- **Genuine ambiguity** — the diff is impossible to summarize into a message confidently and no message was given.

Everything else — a couple of MEDIUM notes, unstaged files left behind — is **not** a blocker. Apply the sensible default, note it in the DONE box, and proceed.

### Box style

Use a **left-border box** for every recap / blocker / done. No right border, no corners to align — so it can never break:

```
┌─ TITLE · context
│ label   value
│ label   value
└─
```

Never draw a right-side `│` or `┐`/`┘` corners — those require exact padding and break. Left border only.

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

Run each check below. **Collect ALL findings first, then report them together in one pass.**

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
If unstaged changes exist on tracked files, **default to committing the staged set as-is** and note the leftover unstaged files in the DONE box. Stage explicitly (`git add -u` for tracked files; never `git add .`). Fold an include-them choice into the modal only when a blocker has already forced a stop.

### 2g. Branch check
```bash
git branch --show-current
```
- **On `main`/`master`** → fine for a simple change (see the simplicity test). Not a blocker, no note needed.
- **On any other branch** → blocker. Stop and clarify via `AskUserQuestion` — a non-default branch is outside the simple path.

---

## Step 3 — Decide: proceed or stop

Check findings against "What counts as a blocker" at the top of this file.

**No blocker → proceed to Step 4.** Report MEDIUM/INFO notes (leftover unstaged files, gitignore gaps) inside the final DONE box. Being on `main` for a simple change is normal: list the branch as a plain `branch  main` field in the DONE box, the same way you'd list any other branch.

**Any blocker → stop once, via `AskUserQuestion`.** Present the blocker in a left-border box, then ask through the modal:

```
┌─ COMMIT BLOCKED
│ [HIGH] .env file staged — belongs in gitignore
│ [HIGH] possible secret in src/config.py:14
│ staged  3 files, +42 −7
└─
```

`AskUserQuestion` options: **Unstage & commit rest** / **Commit anyway** / **Abort**. Honor the choice, then continue or stop.

---

## Step 4 — Commit message

If `$ARGUMENTS` is provided → use it verbatim (the user wrote it — treat it as final).

Otherwise:
- Read `git diff --cached`.
- Draft a Conventional Commits message per `git-guard/references/core.md` → "git-stack.core.commit" (format, types, imperative mood, ≤72 chars).
- Use the drafted message and report it in the DONE box. Only stop to ask (via `AskUserQuestion`) if the diff is too ambiguous to summarize confidently.

---

## Step 5 — Commit

```bash
git add -u   # only if user opted to include unstaged changes
git commit -m "<message>"
```

Then show the DONE box. Do NOT push. Report the pre-flight results as a labelled `[CLEAN]`/`[INFO]` checklist so the user sees what was verified.

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

- Patterns and severity definitions live in `git-guard/references/core.md`. If you spot drift between this command and core.md, core.md wins.
- For repos that intentionally back up config files containing secrets, see `git-guard/references/decisions.md` → "I want to back up a config file that always contains secrets" (clean-filter pattern). Skip 2a for those files.
