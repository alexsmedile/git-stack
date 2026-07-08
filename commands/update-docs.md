---
description: Update CHANGELOG.md and project docs after changes. Writes [Unreleased] or a versioned entry, and asks whether to scope edits to internal docs (CLAUDE/AGENTS/GEMINI/specs) only or also external docs (README, public docs). Resolves symlinks, edits the real file.
version: 1.3.0
allowed-tools: Bash, Read, Edit, Write, Glob, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit for [Unreleased])"
---

# /update-docs — Changelog + Docs Update

Draft and write a CHANGELOG entry and patches for relevant project docs.

## Operating Principles
- **Consent**: The slash command is implicit consent; auto-run without confirming if clean/valid.
- **Scope Clarification**: Ask via `AskUserQuestion` only if the scope (internal docs only vs internal + external) is not implied (see Step 5.5).
- **Blockers (Stop & Ask)**: Stop only for high-severity issues (e.g. broken symlinks, missing files, or unclassifiable diff) using `AskUserQuestion` modal.
- **Box Style**: Format recaps/blockers/done using left-border only (`┌─`, `│`, `└─`). No right border/corners.

---

## Step 1 — Repo state
```bash
git tag --sort=-version:refname | head -5
git log --oneline -20
git branch --show-current
cat CHANGELOG.md 2>/dev/null | head -60
```
Identify last tag/branch. If the most recent CHANGELOG version is newer than the last tag, use it as the diff baseline.

---

## Step 2 — Collect changes
```bash
git log <last-tag>..HEAD --oneline
git diff <last-tag>..HEAD --stat
```
(If no tags, use `git log --oneline` and `git diff HEAD~10..HEAD --stat`.)

---

## Step 3 — Classify changes
Scan diff and commits. Classify changes into these buckets:
- **Breaking**: renamed/removed skill or command, changed syntax.
- **Added**: new skill, command, reference, or script.
- **Changed**: updated instructions, restructured content, behavior change.
- **Fixed**: corrected symlink, wrong path, typo.
- **Removed**: deleted skill or command.

---

## Step 4 — Determine heading
- **Version given** (e.g., `1.2.0`) → `## [1.2.0] — YYYY-MM-DD`. Rename `## [Unreleased]` to this if it already exists, leaving a new empty `[Unreleased]` above.
- **No version given** → Write/extend `## [Unreleased]`.
- Inferred bump level: Breaking → major · Added → minor · Fixed/Changed → patch.

---

## Step 5 — Draft CHANGELOG entry
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Heading per Step 4. One line per item under appropriate bucket headings (`### Breaking`, `### Added`, etc.). Focus on user-facing impact.

---

## Step 5.5 — Clarify scope
- **Internal**: Specs, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (agent-facing).
- **External**: `README.md`, public documentation (user-facing).
Ask via `AskUserQuestion` if not implied by arguments or context:
- **Internal only** (Specs + CLAUDE/AGENTS/GEMINI + CHANGELOG)
- **Internal + external** (Also README and public docs)

---

## Step 6 — Discover & resolve docs
Filter files by chosen scope:
```bash
for f in CLAUDE.md AGENTS.md GEMINI.md README.md; do
  [ -e "$f" ] && echo "$f exists" && readlink "$f" || true
done
```
Resolve symlinks using `readlink -f <file>`. Edit the **real paths**, never the symlinks.

---

## Step 7 — Propose patches
Identify required updates:
- **README.md**: Skill/command tables, version badges, feature lists.
- **AGENTS.md**: Agent/skill rosters, capability descriptions.
- **CLAUDE.md** / **GEMINI.md**: Skill/command references, structure tables.
Preview changes. Skip files with no changes needed.

---

## Step 8 — Decide: write or stop
- **No blocker** → Write (Step 9).
- **Blocker** (broken symlink, missing file, unclassifiable diff) → stop via `AskUserQuestion`.
  Modal options: **Skip that doc & continue** / **Abort** / **Retry**.

---

## Step 9 — Write
- **CHANGELOG.md**: Create if missing (using standard Keep a Changelog header). Insert or merge the drafted entry at the top under `Changelog` header.
- **Project docs**: Apply confirmed patches to the resolved **real paths** only.

---

## Step 10 — Report
Show a left-border report of updated files, symlink resolutions, and next actions.
```
┌─ DOCS UPDATED · v1.2.0 · internal + external
│ CHANGELOG  [1.2.0] entry — 3 items
│ README     2 lines patched
│ AGENTS     1 line  (via symlink → agents_db/git-stack/AGENTS.md)
│ CLAUDE     3 lines (via symlink → vault/.claude/CLAUDE.md)
│ next       git tag v1.2.0 && /push
└─
```
