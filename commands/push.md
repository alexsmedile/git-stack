---
description: Safe commit + push with full pre-flight checks. Reviews secrets, paths, gitignore, large files, branch safety, and remote state before committing and pushing.
version: 2.2.0
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[commit message]"
---

# /push — Safe Commit + Push

Thin orchestrator. Owns the **sequence and confirmation flow**. Delegates **what to check** to the `git-guard` skill — load `skills/git-guard/references/core.md` and apply the rules defined there.

Goal: pre-flight → commit → push.

## Operating principle — don't re-ask for consent

The user typed `/push`. That **is** the instruction to commit and push — treat it as consent already given and proceed straight to the work.

- **Session clean, files good → commit + push.** No confirm step. Show the DONE box after.
- **Stop ONLY when something is truly off** (see "What counts as a blocker").
- When you must stop, surface it through the **`AskUserQuestion` interactive modal** (keep all confirmations in the modal, never in inline text).
- Recap, blocker, and done output go in a **left-border box** — see "Box style".

### The simplicity test — what stays simple, stays simple

The guiding rule: **what's simple stays simple; what's outside simplicity needs clarity first.**

A change is **simple** when all of these hold: self-contained · non-breaking · verified/works · on `main`. A simple change on `main` → **commit + push, no questions, no warning.** Pushing to `main` is not a blocker when the change is simple. Common case — keep it frictionless.

### What counts as a blocker (the only reasons to stop)

Stop only when the change steps **outside simplicity**, or something is wrong, missing, or incoherent:

- **Not on `main`** — on any branch other than `main`/`master`, stop and clarify intent via `AskUserQuestion` (right branch? push + open a PR? set upstream where?). A non-default branch is outside the simple path.
- **Breaking / unverified change** — could break the build or other code, or hasn't been verified. Clarify before pushing.
- **Personal / secret files** — `.env`, credentials, keys, tokens, unintentional hardcoded `/Users/<name>/` paths.
- **Stale / outdated folders staged** — `_archive/`, `_backups/`, `node_modules/`, build output.
- **Errors** — a failed check, a broken/missing file the commit references.
- **Missing files** — `.gitignore` absent where needed; staged symlink with no target.
- **Remote can't be pushed** — diverged history (would need force push) or no remote configured.
- **Version / manifest mismatch** seen in the diff.
- **Genuine ambiguity** — diff can't be summarized into a message and none was given.

Everything else — MEDIUM notes, no upstream yet, leftover unstaged files — is **not** a blocker. Apply the default, note it in the DONE box, and proceed.

### Box style

Use a **left-border box** for every recap / blocker / done. No right border, no corners — so it never misaligns:

```
┌─ TITLE · context
│ label   value
│ label   value
└─
```

Never draw a right-side `│` or `┐`/`┘` corners.

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
- 2g. Branch check — on `main`/`master` with a simple change: fine, proceed silently. On any other branch: blocker, clarify intent via `AskUserQuestion`.
- 2h. Manifest alignment — run `${CLAUDE_SKILL_DIR}/scripts/check-manifests.sh` from the repo root. Reports drift across project-level version fields (plugin manifests, package.json/Cargo.toml/etc., CHANGELOG top entry, README badge). Severity: WARNING for `/push` (drift is informational here — it's blocking for `/release` and `/wrap-up`). Show the full report in the preflight summary so the user sees it before pushing.

Collect ALL findings before asking the user.

---

## Step 3 — Remote state

```bash
git fetch --dry-run 2>&1 || git fetch origin 2>&1
git status -sb
```

Apply rules from `git-guard/SKILL.md`:
- Rule #6: `git fetch` before any merge/rebase. Always.
- **Diverged history** (local behind remote → push would be rejected): this is a **HIGH** blocker. Stop. Do NOT force push (rule #4: `--force-with-lease` only).
- **No remote**: HIGH blocker — can't push. Stop and ask via modal.
- **No upstream**: not a blocker — push will use `--set-upstream`. Note it in the DONE box.

---

## Step 4 — Decide: proceed or stop

Check findings against "What counts as a blocker" at the top of this file.

**No blocker → proceed to Step 5.** Report MEDIUM/INFO (gitignore gaps, no upstream) inside the DONE box. Being on `main` for a simple change is normal: list the branch as a plain `branch  main → origin/main` field in the DONE box, the same way you'd list any other branch.

**Any blocker → stop once, via `AskUserQuestion`.** Show the blocker box first:

```
┌─ PUSH BLOCKED
│ [HIGH] remote 2 commits ahead — push rejected
│ [HIGH] .env file staged
│ staged  3 files, +42 −7
│ remote  origin → git@github.com:user/repo.git
└─
```

Modal options depend on the blocker:
- diverged → **Pull --rebase then push** / **Abort** (never offer force push by default)
- secret/.env → **Unstage & push rest** / **Push anyway** / **Abort**

Honor the choice, then continue or stop.

---

## Step 5 — Commit

If `$ARGUMENTS` is provided → use it verbatim (treat it as final).

Otherwise draft a Conventional Commits message per `git-guard/references/core.md` → "git-stack.core.commit" and use it. Only stop to ask (via `AskUserQuestion`) if the diff is too ambiguous to summarize confidently.

```bash
git add -u   # only if user opted to include unstaged changes
git commit -m "<message>"
```

(If working tree was already clean — push only — skip this step.)

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

Show the DONE box, with the pre-flight results as a labelled `[CLEAN]`/`[INFO]` checklist:

```
┌─ PUSHED
│ commit     abc1234  fix: correct auth token refresh
│ branch     feature/auth → origin/feature/auth
│ files      3 changed, +42 −7
│ remote     git@github.com:user/repo.git
│ pre-flight [CLEAN] secrets · [CLEAN] paths · [CLEAN] large files · [CLEAN] remote in sync
└─
```

---

## Notes

- This command and `/commit` share Step 2 by design. Patterns live in `git-guard/references/core.md` — update there, both inherit.
- For force-push scenarios, see `git-guard/references/decisions.md` → "I need to force push" (always `--force-with-lease`, never to shared branches).
