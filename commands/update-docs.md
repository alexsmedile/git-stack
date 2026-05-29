---
description: Update CHANGELOG.md and project docs after changes. Writes [Unreleased] or a versioned entry, and asks whether to scope edits to internal docs (CLAUDE/AGENTS/GEMINI/specs) only or also external docs (README, public docs). Resolves symlinks, edits the real file.
version: 1.2.0
allowed-tools: Bash, Read, Edit, Write, Glob, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit for [Unreleased])"
---

# /update-docs — Changelog + Docs Update

Draft a CHANGELOG entry and patches for all relevant project docs, then write them.

## Operating principle — don't re-ask for consent

The user typed `/update-docs`. That **is** the instruction to update the docs.

- **Scope is the one thing to clarify up front:** update **internal docs only** (specs, CLAUDE.md, AGENTS.md, GEMINI.md) or **internal + external** (also README.md and any released/public documentation). Internal docs are safe to keep current freely; external docs are user-facing, so changing them is a publishing decision. Ask via `AskUserQuestion` when scope isn't already implied (see Step 5.5).
- **Scope clear + docs resolve cleanly → just write them.** No further confirm step. Show the DONE box after.
- **Stop ONLY when something is truly off:** a doc symlink with no target, a missing/erroring file, or the diff is impossible to classify confidently.
- When you must stop or clarify, surface it through the **`AskUserQuestion` interactive modal** (keep all confirmations in the modal, never in inline text).
- Recap / blocker / done go in a **left-border box**: top/bottom rule + left `│` only, no right border, no corners (so it never misaligns).

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

## Step 4 — Determine the changelog heading: `[Unreleased]` or `[X.Y.Z]`

The CHANGELOG entry targets either an **unreleased** section or a **released** version. Pick from the argument:

- **`$ARGUMENTS` carries a version** (e.g. `1.2.0`) → released entry `## [1.2.0] — YYYY-MM-DD`. Strip a leading `v` for the entry; keep it for the tag suggestion.
- **No version argument** → write/extend the **`## [Unreleased]`** section. This is the default — docs describe work-in-progress that isn't tagged yet. No date, no tag suggestion.

Inferred bump *level* (only to suggest a version when releasing later): Breaking → major · Added only → minor · Fixed/Changed only → patch. A missing version is **not** a blocker — it just means `[Unreleased]`.

**Promotion:** if `## [Unreleased]` already exists and a version is now given, rename it `## [X.Y.Z] — YYYY-MM-DD`, merge any new items in, and leave a fresh empty `[Unreleased]` above it.

---

## Step 5 — Draft CHANGELOG entry

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Heading per Step 4 — `## [Unreleased]` (no date) when no version was given, or `## [X.Y.Z] — YYYY-MM-DD` (today's date) when releasing.

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

---

## Step 5.5 — Clarify scope: internal-only or internal + external

Docs split into two tiers:

| Tier | Files | Nature |
|---|---|---|
| **Internal** | specs, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, contributor/architecture notes | agent- and contributor-facing; keep current freely |
| **External** | `README.md`, released / public documentation, doc sites | user-facing; editing them is a publishing decision |

The CHANGELOG is always in scope (it records the change regardless of tier).

Decide the scope:
- **Argument or context already implies it** (e.g. the user said "just internal", or the only changed docs are internal) → use that, don't ask.
- **Otherwise ask once, via `AskUserQuestion`:**
  - **Internal only** — specs + CLAUDE/AGENTS/GEMINI + CHANGELOG. Leave README and public docs untouched.
  - **Internal + external** — also patch README and released documentation.

Carry the chosen scope into Steps 6–7: discover and patch only the docs in scope.

---

## Step 6 — Discover and resolve in-scope docs

Scan the repo root for known doc files, filtered to the chosen scope:

```bash
# internal: CLAUDE.md AGENTS.md GEMINI.md (+ any specs you know of)
# external (add only if scope = internal + external): README.md
for f in CLAUDE.md AGENTS.md GEMINI.md README.md; do
  [ -e "$f" ] && echo "$f exists" && readlink "$f" || true
done
```

Drop README.md (and any other external doc) from the list when scope is **internal only**.

For each in-scope file that exists:
- **Symlink** → resolve the real path with `readlink -f <file>`. All edits go to the real path — never edit the symlink itself.
- **Regular file** → edit in place.

Build a list: `[ {file, real_path, is_symlink, tier} ]`. Only include files that actually exist and are in scope.

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

## Step 8 — Decide: write or stop

**Scope chosen + all in-scope docs resolve cleanly → just write (Step 9).** No confirm gate — consent was given by invoking `/update-docs`. (No version → write to `[Unreleased]`; that's a normal path, not a stop.)

**Stop ONLY on a real blocker**, via `AskUserQuestion` (never inline text):
- a doc symlink points nowhere, or a target file errors/missing → modal: **Skip that doc & continue** / **Abort**
- diff impossible to classify confidently → modal with the candidate buckets

When stopping, show context in a left-border box first:

```
┌─ UPDATE-DOCS BLOCKED
│ AGENTS.md → broken symlink (no target)
│ scope     internal + external
└─
```

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
Then, per Step 4:
- **`[Unreleased]`** (no version) → if an `## [Unreleased]` section exists, merge new items into its buckets; otherwise create it at the top, below the header.
- **`[X.Y.Z]`** (version given) → insert the dated entry at the top below the header. If promoting from `[Unreleased]`, rename that section and leave a fresh empty `[Unreleased]` above it.

### Project docs (CLAUDE, AGENTS, GEMINI — and README only if external scope)
For each in-scope doc with confirmed patches:
- Always write to the **real path** (resolved in Step 6) — never the symlink
- Apply only the patches confirmed in Step 7
- Limit edits to the confirmed patches; leave every other section untouched
- Skip external docs entirely when scope is **internal only**

---

## Step 10 — Report

Left-border box. Left `│` only, no right border. Title shows the heading written and the scope used.

Released, internal + external:
```
┌─ DOCS UPDATED · v1.2.0 · internal + external
│ CHANGELOG  [1.2.0] entry — 3 items
│ README     2 lines patched
│ AGENTS     1 line  (via symlink → agents_db/git-stack/AGENTS.md)
│ CLAUDE     3 lines (via symlink → vault/.claude/CLAUDE.md)
│ next       git tag v1.2.0 && /push
└─
```

Unreleased, internal only:
```
┌─ DOCS UPDATED · [Unreleased] · internal only
│ CHANGELOG  [Unreleased] — 2 items added
│ AGENTS     1 line  (via symlink → agents_db/git-stack/AGENTS.md)
│ CLAUDE     3 lines (via symlink → vault/.claude/CLAUDE.md)
│ README     skipped — external, out of scope
│ next       release later with /wrap-up <version>
└─
```

Do not commit or tag automatically.
