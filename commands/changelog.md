---
description: Draft and write a CHANGELOG.md entry for changes since the last tag. Confirms before writing. No README patches, no commit, no push.
version: 1.0.0
allowed-tools: Bash, Read, Edit, Write
argument-hint: "[version] (e.g. 1.2.0 — omit to auto-detect)"
---

# /changelog — Write Changelog Entry

Draft a Keep a Changelog entry for changes since the last tag. Confirm, then write. Nothing else.

---

## Step 1 — Baseline

```bash
git tag --sort=-version:refname | head -5
git log --oneline -20
```

Identify the last tag. If none, use the first commit as baseline.

Read current CHANGELOG.md:
```bash
cat CHANGELOG.md 2>/dev/null | head -60
```

If the most recent version entry in CHANGELOG.md is newer than the last tag, use that as the diff baseline instead.

---

## Step 2 — Collect changes

```bash
git log <last-tag>..HEAD --oneline
git diff <last-tag>..HEAD --stat
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

---

## Step 3 — Determine version

If `$ARGUMENTS` provided, use it (strip leading `v`).
Else infer from highest-severity bucket:
- Breaking → **major** bump
- Added → **minor** bump
- Fixed or Changed → **patch** bump

---

## Step 4 — Draft entry

Format per [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Use today's date.

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

Show the draft to the user and ask: **"Write this entry? (yes / edit / abort)"**

- **abort** → stop, write nothing
- **edit** → show draft, let user adjust inline, then confirm once more
- **yes** → write (Step 5)

---

## Step 5 — Write

If CHANGELOG.md does not exist, create it with a standard header:

```markdown
# Changelog

All notable changes are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---
```

Insert the new entry at the top, below the header, above any existing entries.

---

## Step 6 — Report

```
DONE
────
CHANGELOG.md  updated  (v1.2.0 entry, 3 items)
```

Do not commit, tag, or push.
