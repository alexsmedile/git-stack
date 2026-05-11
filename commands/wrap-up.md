---
description: Full release wrap-up — version bump, changelog, README patches, pre-flight checks, commit, optional tag, push. One command to close out a session.
version: 1.2.0
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
Use the canonical pattern from `git-guard/references/core.md` → "Secrets / API key scan". Scan ADDED lines of the staged diff only — cleanup commits that remove a previously-leaked secret must NOT be flagged:
```bash
git diff --cached | grep '^+' | grep -v '^+++' | grep -nE '<SECRET_RE from core.md>' | head -30
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

### 4i. Manifest alignment — pre-state snapshot (informational)
```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/check-manifests.sh"
```

The script detects all version-bearing manifests in the repo and reports current alignment.

- **Exit 0**: pre-bump state already aligned. Note as INFO.
- **Exit 1**: pre-bump state already drifted. Flag as **MEDIUM** — `/wrap-up` will bump everything to the target in Phase 5.5 and re-audit in Phase 7.5, so this only matters as context. Mention it at the confirm gate.
- **Exit 2**: no formal manifests — log as INFO and continue. Phase 5.5 will skip silently.

This check is **not** the release gate. The real gate is Phase 7.5's post-write audit against the target version. Component-level versions (per-skill / per-command frontmatter) are informational only.

---

## Phase 5 — Single confirm gate

Before this gate, also run a **dry-run bump preview** so the user sees exactly which manifests will be rewritten:

```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/bump-manifests.sh" "$VERSION" --dry-run
```

Capture the planned writes — fold them into the confirm block. If exit code is 2 (no manifests detected), note "no project-level manifests — only CHANGELOG/README will change" and continue.

Present everything before ANY writes:

```
WRAP-UP PLAN
────────────
Version:    1.2.0  (minor — 1 skill added)
Changelog:  1 Added, 1 Fixed
README:     2 line patches (badge + table row)
Manifests:  4 files will be bumped 1.1.0 → 1.2.0
              .claude-plugin/plugin.json
              .claude-plugin/marketplace.json (.metadata + .plugins[])
              .codex-plugin/plugin.json
              package.json
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
- **yes** → execute phases 6 → 6.5 → 7 → 8 → 9.

If any **HIGH** findings exist and user says "yes": ask once more explicitly before proceeding.

---

## Phase 6 — Write docs + bump manifests

### 6a. CHANGELOG.md
If it does not exist, create with header:
```markdown
# Changelog

All notable changes are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---
```
Insert new entry at top, below the header, above any existing entries.

### 6b. README.md
Apply only the patches confirmed in Phase 3. Do not touch unscoped sections.

### 6c. Bump every detected manifest
```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/bump-manifests.sh" "$VERSION"
```

The script writes the target version into every detected project-level location (plugin manifests, package.json, pyproject.toml, Cargo.toml, etc., README badge). Idempotent — files already at the target version are skipped.

- **Exit 0**: writes succeeded (or nothing needed bumping).
- **Exit 1**: a write failed. Surface the script's stderr and **abort the wrap-up** before commit. Some files may be partially updated — tell the user to inspect before retrying.
- **Exit 2**: no manifests detected. Continue silently (only CHANGELOG/README changed).

---

## Phase 6.5 — Post-write audit gate (the real release gate)

Re-run the alignment check now that everything has been bumped:

```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/check-manifests.sh"
```

Then verify every reported version equals `$VERSION`:

- **Exit 0 AND every project-level entry equals `$VERSION`** → ✓ aligned. Continue to Phase 7.
- **Exit 0 BUT some entry ≠ `$VERSION`** (e.g. CHANGELOG top entry didn't get bumped, or a manifest the bumper doesn't know about) → drift against target. Show the diff and ask:
  ```
  ⚠ Post-write audit: <N> location(s) still at <old-version>:
      <list>
  Auto-fix by re-running bump-manifests.sh? (yes / abort)
  ```
  - **yes** → re-run bump-manifests.sh, then re-run check-manifests.sh once more. If it still drifts, abort with the offending paths.
  - **abort** → stop before commit. The repo has the new docs + (mostly) bumped manifests but no commit. User can fix manually and retry.
- **Exit 1** (general drift) → same flow as above.
- **Exit 2** (no manifests) → fine, continue to Phase 7.

This is the gate that actually prevents shipping a misaligned release.

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
