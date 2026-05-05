---
description: Full release wrap-up — version bump, changelog, README patches, pre-flight checks, commit, optional tag, push. One command to close out a session.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
argument-hint: "[version] (e.g. 1.2.0 — omit to auto-detect)"
---

# /wrap-up — Release Wrap-Up

Version bump → changelog + README → pre-flight checks → commit → tag (optional) → push.
One confirm gate before any writes. Nothing is touched until you say yes.

---

## Phase 1 — Repo snapshot (silent)

```bash
git status
git diff --stat
git log --oneline -10
git tag --sort=-version:refname | head -5
git branch --show-current
git remote -v
```

Identify: last tag, current branch, remote URL, uncommitted changes, unpushed commits.

**Stop early** if the working tree is clean AND there are no unpushed commits — nothing to wrap up. Tell the user.

---

## Phase 2 — Classify changes & determine version

Diff since last tag (or first commit if no tags exist):

```bash
git log <last-tag>..HEAD --oneline
git diff <last-tag>..HEAD --stat
```

Read current CHANGELOG.md and README.md:

```bash
cat CHANGELOG.md 2>/dev/null | head -60
cat README.md 2>/dev/null | head -80
```

Bucket each change:

| Bucket | Triggers |
|---|---|
| **Breaking** | renamed/removed skill or command, changed invocation syntax |
| **Added** | new skill, new command, new reference file, new script |
| **Changed** | updated instructions, restructured content, behavior change |
| **Fixed** | broken symlink, wrong path, typo in instructions |
| **Removed** | deleted skill, command, or archived content |

Skip empty buckets.

**Version:** If `$ARGUMENTS` is provided, use it (strip leading `v` for changelog, keep for tag).
Else infer from highest-severity bucket:
- Breaking present → **major** bump
- Added only → **minor** bump
- Fixed or Changed only → **patch** bump

---

## Phase 3 — Draft docs

### CHANGELOG entry

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Use today's date.

```markdown
## [X.Y.Z] — YYYY-MM-DD

### Breaking
- ...

### Added
- ...

### Changed
- ...

### Fixed
- ...

### Removed
- ...
```

One line per item. Focus on what the user needs to know, not implementation detail.

### README patches

Identify lines to update: skill/command table rows, version badge, feature list.
Prepare a diff-style preview — do not write yet.

```
README PATCHES
──────────────
Line 12: github-repo-prettifier  →  git-repo-prettifier
Line 34: v1.1.0                  →  v1.2.0
```

---

## Phase 4 — Pre-flight checks

Collect ALL findings silently — do not interrupt mid-check.

### 4a. Secrets scan
```bash
git diff HEAD | grep -iE "(api_key|api_secret|secret_key|access_token|auth_token|password|passwd|private_key|-----BEGIN|sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]+|AKIA[0-9A-Z]{16})" | head -30
```
Flag matches as **HIGH**.

### 4b. .env files staged
```bash
git diff --cached --name-only | grep -E "^\.env$|\.env\."
```
Flag as **HIGH**.

### 4c. Hardcoded absolute paths
```bash
git diff --cached | grep -E "(/Users/[a-zA-Z]+/|/home/[a-zA-Z]+/)" | grep -v "^---\|^+++" | head -20
```
Flag as **MEDIUM** — ask if intentional.

### 4d. Large files
```bash
git diff --cached --name-only | xargs -I{} find . -name "{}" -size +500k 2>/dev/null
find . -not -path "./.git/*" -size +1M -not -path "./node_modules/*" 2>/dev/null | head -10
```
Flag staged files >500KB. Warn on any file >1MB in the repo.

### 4e. .gitignore coverage
```bash
cat .gitignore 2>/dev/null || echo "NO_GITIGNORE"
```
Flag **MEDIUM** if missing. Check for: `.env`, `node_modules/`, `*.log`, `_archive/`, `_backups/`, `.DS_Store`.

### 4f. Unstaged changes
```bash
git diff --stat
```
If unstaged tracked files exist, note them — will offer `git add -u` at confirm step.

### 4g. Branch safety
```bash
git branch --show-current
```
Warn **MEDIUM** if on `main` or `master`.

### 4h. Remote state
```bash
git fetch origin 2>/dev/null
git status -sb
```
Flag if remote is ahead (diverged) — do not proceed with push until resolved.

---

## Phase 5 — Single confirm gate

Present everything before ANY writes:

```
WRAP-UP PLAN
────────────
Version:    1.2.0  (minor — 1 skill added)
Changelog:  1 Added, 1 Fixed
README:     2 line patches
Commit msg: "chore: release v1.2.0 — add git-repo-prettifier, fix symlink"
Tag:        v1.2.0  (will ask after commit)
Push:       origin/main  →  https://github.com/...

Pre-flight
──────────
[MEDIUM]  on main — committing directly, intentional?
[INFO]    2 unstaged changes on tracked files — include with git add -u?

Proceed? (yes / edit / abort)
```

- **abort** → stop. Nothing is written.
- **edit** → show each draft (changelog entry, README patches, commit message). Let user adjust inline. Re-confirm.
- **yes** → execute phases 6–9.

If any **HIGH** findings exist and user says "yes": ask once more explicitly before proceeding.

---

## Phase 6 — Write docs

### CHANGELOG.md
If it does not exist, create with header:
```markdown
# Changelog

All notable changes are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---
```
Insert new entry at top, below the header, above any existing entries.

### README.md
Apply only the patches confirmed in Phase 3. Do not touch unscoped sections.

---

## Phase 7 — Commit

If user confirmed `git add -u` in Phase 5:
```bash
git add -u
```

```bash
git commit -m "chore: release vX.Y.Z — <one-line summary>"
```

Report: commit hash, branch, files changed.

---

## Phase 8 — Tag (optional)

Ask: **"Tag this commit as vX.Y.Z? (yes / no)"**

- **yes** → `git tag vX.Y.Z`
- **no** → skip. Note: `git tag vX.Y.Z` can be run manually later.

---

## Phase 9 — Push

```bash
git push                       # branch (or git push --set-upstream origin <branch> if no upstream)
git push origin vX.Y.Z         # tag — only if tagged in Phase 8
```

Error handling:
- **Non-fast-forward rejected** → explain remote is ahead, suggest `git pull --rebase`. Do NOT force push.
- **Auth error** → surface raw error, tell user to check credentials or SSH key.
- **No upstream** → use `--set-upstream origin <branch>`.
- **Other** → show raw error, stop.

---

## Phase 10 — Final report

```
DONE
────
CHANGELOG.md  updated  (v1.2.0 entry, 2 items)
README.md     patched  (2 lines)
Commit        abc1234  chore: release v1.2.0
Tag           v1.2.0   pushed to origin
Branch        main     pushed to origin
```
