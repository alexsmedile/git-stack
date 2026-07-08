---
description: Close out a session — commit + push the edits so far, then optionally tag a release. Runs /commit + /push always; adds /update-docs + version bump + tag only when releasing.
version: 2.2.0
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit to auto-detect)"
---

# /wrap-up — Session Wrap-Up

Pipeline orchestrator. Reuses the exact logic of `/commit`, `/push`, and `/update-docs`.

```
/commit  →  /push                                   ← always (save session)
            ↘  /update-docs  →  bump  →  tag         ← optional release path
```

## Operating Principles
- **Consent**: The slash command is implicit consent; auto-run without confirming if clean/valid.
- **Blockers**: Stop and ask only for high-severity issues (see Blocker list) using `AskUserQuestion` modal.
- **Box Style**: Format recaps/blockers/done using left-border only (`┌─`, `│`, `└─`). No right border/corners.
- **Simplicity Test**: A release/save of a simple, verified change on `main` runs end-to-end silently.

### What counts as a blocker (reasons to stop)
- Inherits all `/commit` and `/push` blockers (safety, remote, stale folders, etc.).
- **Release-specific**: Manifest mismatch that won't auto-fix after re-running the bumper.

---

## Phase 1 — Repo snapshot (silent)
```bash
git status
git diff --stat
git status --porcelain
git log --oneline -10
git tag --sort=-version:refname | head -5
git branch --show-current
git remote -v
```
Capture files (NEW vs EDITED), pre-flight status, and current versions.
If clean and no unpushed commits → exit (nothing to do).

---

## Phase 2 — Release or just-save?
- **Version given** (e.g., `/wrap-up 1.2`) → Release path. Set `RELEASE=yes`, `VERSION=1.2.0`. Go to Phase 3.
- **No version given** → Just-save path. Set `RELEASE=no`. Run save pipeline (Phase 3), then ask at Phase 6.

---

## Phase 3 — Save the session (always runs)
- **3a. Run `/commit`**: Pre-flight checks and commit.
  - Message if `RELEASE=yes`: `chore: release vX.Y.Z — <summary>`
  - Message if `RELEASE=no`: Conventional Commit message.
- **3b. Run `/push`**: Push to remote.
  ```bash
  git push   # or --set-upstream origin <branch>
  ```

---

## Phase 4 — Update docs for the release *(release path only)*
Run `/update-docs` for `VERSION` to draft CHANGELOG and patch internal (+ external if in scope) docs.

---

## Phase 5 — Bump manifests *(release path only)*
```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-ops}/scripts/bump-manifests.sh" "$VERSION"
```
Audit versions:
```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-ops}/scripts/check-manifests.sh"
```
If drift found: re-run bump-manifests once. If still drifting: block and ask.
Commit docs + manifest changes (`docs: release vX.Y.Z`).

---

## Phase 6 — Tag decision
- **If `RELEASE=yes`** → tag directly:
  ```bash
  git tag vX.Y.Z
  git push origin vX.Y.Z
  ```
- **If `RELEASE=no`** → Ask user via `AskUserQuestion`:
  - **Tag <suggested>** (infer major/minor/patch from commits)
  - **Tag a different version**
  - **No tag, just close**
  If user opts to tag, run Phases 4 → 5 first, then create and push tag.

---

## Phase 7 — Final report
Show recap using a left-border box containing:
- **VERSION**: Version + bump level or `[Unreleased]`
- **NEW / EDITED**: Summarized list of files created/edited
- **COMPONENTS / MANIFESTS**: Bumped components/manifest files (`old → new`)
- **CHANGELOG**: Top entry summary
- **COMMIT / TAG / PUSH**: Hash, message, tags, and branch destination
- **PRE-FLIGHT**: Checklist results (`[CLEAN]`/`[INFO]`)
- **NOTES**: Warnings, untracked files left, etc.

Example:
```
┌─ WRAPPED UP · v1.9.0
│ VERSION     1.9.0  (minor — new capability)
│ NEW         docs/versioning.md
│ EDITED      SKILL.md
│ COMPONENTS  SKILL.md  1.8.4 → 1.9.0 ✓
│ MANIFESTS   package.json  1.8.4 → 1.9.0
│ COMMIT      abc1234  docs: add versioning — release v1.9.0
│ TAG         v1.9.0 → origin
│ PUSH        main → origin/main  +  tag
│ PRE-FLIGHT  [CLEAN] secrets · [CLEAN] paths · [INFO] on main
└─
```
