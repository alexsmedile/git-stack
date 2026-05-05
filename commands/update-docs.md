---
description: Update CHANGELOG.md and project docs (README, AGENTS.md, CLAUDE.md, GEMINI.md) after major changes. Auto-detects which docs exist, resolves symlinks and edits the real file. Confirms before writing anything.
allowed-tools: Bash, Read, Edit, Write, Glob
argument-hint: "[version] (e.g. 1.2.0 — omit to auto-detect)"
---

# /update-docs — Changelog + Docs Update

Draft a CHANGELOG entry and patches for all relevant project docs. Confirm before writing anything.

---

## Step 1 — Repo state

```bash
git tag --sort=-version:refname | head -5
git log --oneline -20
git branch --show-current
```

Identify: last tag, current branch. If no tags, use first commit as baseline.

Read current CHANGELOG.md:
```bash
cat CHANGELOG.md 2>/dev/null | head -60
```
If the most recent version entry in CHANGELOG.md is newer than the last tag, use that as the diff baseline instead.

---

## Step 2 — Collect changes since last tag

```bash
git log <last-tag>..HEAD --oneline
git diff <last-tag>..HEAD --stat
```

If no tags: `git log --oneline` and `git diff HEAD~10..HEAD --stat`.

---

## Step 3 — Classify changes

Scan diff and commit messages. Bucket each change:

| Bucket | Triggers |
|---|---|
| **Breaking** | renamed/removed skill or command, changed invocation syntax |
| **Added** | new skill, new command, new reference file, new script |
| **Changed** | updated instructions, restructured content, behavior change |
| **Fixed** | corrected broken symlink, wrong path, typo in instructions |
| **Removed** | deleted skill, command, archived content |

Skip empty buckets.

---

## Step 4 — Determine version

If `$ARGUMENTS` provided, use it (strip leading `v` for the entry, keep for the tag suggestion).
Else infer from highest-severity bucket:
- Breaking → bump **major**
- Added only → bump **minor**
- Fixed/Changed only → bump **patch**

---

## Step 5 — Draft CHANGELOG entry

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

One line per item. Focus on what the user needs to know, not implementation detail. Skip empty sections.

---

## Step 6 — Discover and resolve project docs

Scan for known doc files in the repo root:

```bash
for f in README.md AGENTS.md CLAUDE.md GEMINI.md; do
  [ -e "$f" ] && echo "$f exists" && readlink "$f" || true
done
```

For each file that exists:
- If it is a **symlink**: resolve the real path with `readlink -f <file>`. All edits must go to the real path — never edit the symlink itself.
- If it is a **regular file**: edit in place.

Build a list: `[ {file, real_path, is_symlink} ]`. Only include files that actually exist.

---

## Step 7 — Propose patches per doc

For each discovered doc, read it and identify sections that need updating based on the classified changes:

### README.md
- Skill/command tables — add, remove, or rename rows
- Version badge — bump if present
- Feature list — update for new capabilities

### AGENTS.md
- Agent/skill roster tables — add, remove, or rename entries
- Capability descriptions — update for behavior changes
- Version or status fields

### CLAUDE.md
- Skill/command references — update names, paths
- Structure tables — reflect added/removed/renamed items
- Any version or compatibility notes

### GEMINI.md
- Same as CLAUDE.md — update skill/command references and structure tables

For each doc, show a diff-style preview:

```
AGENTS.md  (real: /Users/username/projects/my-repo/AGENTS.md)
────────────────────────────────────────────────────────────
Line 18: old-skill-name  →  new-skill-name
Line 42: | v1.1.0 |      →  | v1.2.0 |

README.md  (real: README.md — not symlinked)
─────────────────────────────────────────────
Line 7:  old-skill-name  →  new-skill-name
```

If a doc exists but has no sections that need updating, note it as "no changes needed" and skip it.

---

## Step 8 — Confirm

Present a single summary before any writes:

```
UPDATE-DOCS PLAN
────────────────
Version:    1.2.0  (minor — 1 skill added)
Changelog:  1 Breaking, 1 Added, 1 Fixed

Docs to patch:
  README.md    — 2 lines  (not symlinked)
  AGENTS.md    — 1 line   (symlink → /Users/username/projects/my-repo/AGENTS.md)
  CLAUDE.md    — 3 lines  (symlink → /Users/username/.claude/CLAUDE.md)
  GEMINI.md    — no changes needed

Proceed? (yes / edit / abort)
```

- **yes** → write all changes (Step 9)
- **edit** → show each draft, let user adjust inline, re-confirm
- **abort** → stop, write nothing

---

## Step 9 — Write

### CHANGELOG.md
If it does not exist, create with standard header:
```markdown
# Changelog

All notable changes are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---
```
Insert new entry at top, below header, above existing entries.

### Project docs (README, AGENTS, CLAUDE, GEMINI)
For each doc with confirmed patches:
- Always write to the **real path** (resolved in Step 6) — never the symlink
- Apply only the patches confirmed in Step 7
- Do not rewrite sections that weren't in scope

---

## Step 10 — Report

```
DONE
────
CHANGELOG.md  — added [1.2.0] entry (3 items)
README.md     — patched 2 lines
AGENTS.md     — patched 1 line  (via symlink → agents_db/git-stack/AGENTS.md)
CLAUDE.md     — patched 3 lines (via symlink → vault/.claude/CLAUDE.md)

Suggested next step: git tag v1.2.0 && /push
```

Do not commit or tag automatically.
