---
description: Draft and write a CHANGELOG.md entry for changes since the last tag — to [Unreleased] by default, or a versioned entry when a version is given. No README patches, no commit, no push.
version: 1.1.0
allowed-tools: Bash, Read, Edit, Write, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit for [Unreleased])"
---

# /changelog — Write Changelog Entry

Draft a Keep a Changelog entry for changes since the last tag, then write it. Changelog only — no docs, no commit, no push.

## Operating principle — don't re-ask for consent

The user typed `/changelog`. That **is** the instruction to write the entry — treat it as consent already given and proceed.

- **Changes classify cleanly → draft and write.** No confirm gate. Show the DONE box after.
- **Stop ONLY when the diff is impossible to classify confidently** — then ask via the `AskUserQuestion` modal (keep confirmations in the modal, never inline text).
- A missing version is **not** a blocker — it means write to `## [Unreleased]`.
- Recap / done go in a **left-border box**: top/bottom rule + left `│` only, no right border, no corners.

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

## Step 3 — Heading: `[Unreleased]` or `[X.Y.Z]`

- **`$ARGUMENTS` carries a version** → released entry `## [X.Y.Z] — YYYY-MM-DD` (strip a leading `v`).
- **No version** → write/extend `## [Unreleased]` (no date). This is the default.

Inferred bump *level* (only to suggest a version when releasing later): Breaking → major · Added → minor · Fixed/Changed → patch.

**Promotion:** if `## [Unreleased]` exists and a version is now given, rename it `## [X.Y.Z] — YYYY-MM-DD`, merge new items in, and leave a fresh empty `[Unreleased]` above.

---

## Step 4 — Draft + write entry

Format per [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Heading per Step 3.

```markdown
## [Unreleased]          ← or  ## [X.Y.Z] — YYYY-MM-DD

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

Write straight away — consent was given by invoking `/changelog`. Stop only if the diff can't be classified confidently; then ask via `AskUserQuestion` with the candidate buckets.

If CHANGELOG.md does not exist, create it with a standard header first:

```markdown
# Changelog

All notable changes are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---
```

Then:
- **`[Unreleased]`** → merge new items into the existing section's buckets, or create it at the top below the header.
- **`[X.Y.Z]`** → insert the dated entry at the top below the header (promoting `[Unreleased]` if present).

---

## Step 5 — Report

Left-border box. Left `│` only, no right border.

```
┌─ CHANGELOG UPDATED · [Unreleased]
│ entry   [Unreleased] — 3 items (1 added, 2 fixed)
│ next    release later with /wrap-up <version>
└─
```

Released variant:
```
┌─ CHANGELOG UPDATED · v1.2.0
│ entry   [1.2.0] — 3 items
│ next    git tag v1.2.0 && /push
└─
```

Do not commit, tag, or push.
