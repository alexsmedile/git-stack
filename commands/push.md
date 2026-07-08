---
description: Safe commit + push with full pre-flight checks. Reviews secrets, paths, gitignore, large files, branch safety, and remote state before committing and pushing.
version: 2.3.0
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[commit message]"
---

# /push — Safe Commit + Push

Thin orchestrator. Sequence and confirmation flow. Details in `skills/git-ops/references/core.md` (canonical rules/severity).

Goal: pre-flight → commit → push.

## Delegate the mechanical work (default)

To keep the noisy `git status`/`diff`/scan output and the git writes off your
context, delegate to the **`git-stack-runner`** subagent (Sonnet) via the Task
tool. Pass: `operation: push`, the absolute repo path, the commit message (if
given), and any allowed non-noreply emails. It runs the full sequence below
headlessly and returns a one-line verdict:
- **`VERDICT: DONE`** → relay the PUSHED/COMMIT/PREFLIGHT lines to the user in the DONE box. Finished.
- **`VERDICT: BLOCKED`** → the agent stopped without writing. Take its BLOCKERS list and run the `AskUserQuestion` modal yourself (the agent can't ask the user), then act on the choice.
- **`VERDICT: NOTHING-TO-DO`** → report clean, nothing to push.

Run the steps below inline only if the agent is unavailable or the user asks to
see each check. Blocker decisions ALWAYS stay with you — the agent never
resolves a HIGH blocker.

## Operating Principles
- **Consent**: The slash command is implicit consent; auto-run without confirming if clean/valid.
- **Blockers**: Stop and ask only for high-severity issues (see Blocker list) using `AskUserQuestion` modal.
- **Box Style**: Format recaps/blockers/done using left-border only (`┌─`, `│`, `└─`). No right border/corners.
- **Simplicity Test**: A change on `main` is "simple" if it is self-contained, non-breaking, and verified. If simple, commit + push silently.

### What counts as a blocker (reasons to stop)
- **All /commit blockers**: Branch not on `main`/`master` (unless simple), breaking/unverified, staged secrets, `.env` files, hardcoded `/Users/` or `/home/` paths, stale folders, errors, missing files, commit message ambiguity.
- **Remote blockers**:
  - Diverged history (local behind remote; would need force push) — HIGH blocker. Do NOT force push.
  - No remote configured — HIGH blocker.

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
Run all checks from `/commit` Step 2 (including `2h` author-email on the staged identity), plus:
- **2i. Author-email leak on outgoing commits** (WARNING): check the actual commits about to be pushed, not just config — this catches a leaking *committer* field and old emails that a rewrite/rebase left behind.
  ```bash
  bash "${CLAUDE_SKILL_DIR}/scripts/check-author-email.sh" --range "@{upstream}..HEAD" 2>/dev/null \
    || bash "${CLAUDE_SKILL_DIR}/scripts/check-author-email.sh"
  ```
  Exit `1` = a leak in an outgoing commit's author or committer. Surface it and offer the fix; don't hard-block. See `core.md` → "Author-email leak check".
- **2j. Manifest alignment**: Run `${CLAUDE_SKILL_DIR}/scripts/check-manifests.sh` from repo root. Severity: WARNING (informational for `/push`; blocking for `/release` and `/wrap-up`).

---

## Step 3 — Remote state
```bash
git fetch --dry-run 2>&1 || git fetch origin 2>&1
git status -sb
```
Identify diverged history (HIGH blocker), no remote (HIGH blocker), or no upstream (not blocker; use `--set-upstream`).

---

## Step 4 — Decide: proceed or stop
- **No blocker** → proceed to Step 5. Report warnings/info in DONE box.
- **Any blocker** → stop once via `AskUserQuestion` modal.
  Modal options:
  - Diverged: **Pull --rebase then push** / **Abort**
  - Secrets/`.env`: **Unstage & push rest** / **Push anyway** / **Abort**

---

## Step 5 — Commit
If `$ARGUMENTS` is provided → use verbatim.
Otherwise, draft a Conventional Commits message per `core.md`.
```bash
git add -u   # only if user opted to include unstaged changes
git commit -m "<message>"
```
(If working tree was already clean, skip this step.)

---

## Step 6 — Push
```bash
git push
# or, if no upstream:
git push --set-upstream origin <branch>
```
If push fails:
- Rejected: `git pull --rebase` then re-push. Do not force-push to shared branches.
- Auth error: check credentials (`gh auth status`).

Show the DONE box:
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
- Patterns and remote decisions live in `git-ops/references/core.md` and `decisions.md`.
- For force-push scenarios, see `git-ops/references/decisions.md` (always use `--force-with-lease`).
