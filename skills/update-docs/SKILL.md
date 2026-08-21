---
name: update-docs
description: >
  Update project documentation after changes — CHANGELOG.md entries (Keep a
  Changelog, [Unreleased] or versioned), README, STATUS.md, AGENTS/CLAUDE/GEMINI
  files, and docs/. Use for "update the changelog", "write a changelog entry",
  "update the docs", "document these changes", or doc refresh before a release.
  Resolves symlinks and edits the real file. Does not commit, push, or tag.
allowed-tools: Bash, Read, Edit, Write, Glob, AskUserQuestion
metadata:
  version: "2.0.0"
---

# update-docs

Draft and write a CHANGELOG entry and patches for the project docs affected by
recent changes. Documentation only — never commit, push, or tag. Hand Git
operations to the `git-ops` skill.

## Operating principles

- **Consent**: a request to update docs is consent to write them. Proceed when
  changes classify cleanly; do not add a confirmation gate.
- **Scope**: ask only when internal-vs-external scope is not implied (Step 4).
- **Blockers**: stop only for high-severity issues — broken symlinks, missing
  files, or a diff that cannot be classified confidently.
- **Changelog-only requests**: when the user asks for a changelog entry
  specifically, run Steps 1–3 and 6–7 and skip the doc-patching steps entirely.
- **Box style**: left border only (`┌─`, `│`, `└─`), always inside a
  `text`-tagged code fence. Full rules: `git-ops` SKILL.md → "Report format".

## Step 1 — Baseline and change shape

```bash
bash "${CLAUDE_SKILL_DIR:-<skill-directory>}/scripts/git-stack.sh" scan
```

Returns `SINCE`, `COMMITS`, per-type counts (`FEAT`, `FIX`, `DOCS`, …), and
`BREAKING=yes` when present. `VERDICT=NOTHING_TO_DO` → nothing since the last
tag; report and stop. Resolve `<skill-directory>` to this skill's directory on
runtimes that do not set `CLAUDE_SKILL_DIR`; in a Claude plugin install, use
`${CLAUDE_PLUGIN_ROOT}/skills/update-docs/scripts/git-stack.sh`.

Read the current changelog head only:

```bash
head -60 CHANGELOG.md 2>/dev/null
```

If the newest CHANGELOG entry is ahead of `SINCE`, use it as the baseline.

## Step 2 — Collect and classify

Pull subjects only when the scan counts are not enough to write entries:

```bash
git log <baseline>..HEAD --format='%s'
```

Skip `--stat` unless a change resists classification. Bucket each change:

| Bucket | Triggers |
|---|---|
| **Breaking** | renamed/removed skill or command, changed invocation syntax |
| **Added** | new skill, new command, new reference file, new script |
| **Changed** | updated instructions, restructured content, behavior change |
| **Fixed** | broken symlink, wrong path, typo in instructions |
| **Removed** | deleted skill, command, or archived content |

Skip empty buckets.

## Step 3 — Draft the CHANGELOG entry

Follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). One line per
item under its bucket heading (`### Added`, `### Fixed`, …), focused on
user-facing impact.

- **Version given** → `## [X.Y.Z] — YYYY-MM-DD`. If `## [Unreleased]` already
  exists, rename it to this and leave a new empty `[Unreleased]` above.
- **No version given** → write or extend `## [Unreleased]`. A missing version is
  not a blocker.
- Bump level, when inferring: Breaking → major · Added → minor · Fixed/Changed →
  patch.

## Step 4 — Clarify doc scope

Skip this step for changelog-only requests.

- **Internal**: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, specs (agent-facing).
- **External**: `README.md`, `STATUS.md`, `docs/`, public documentation
  (user-facing).

Ask which scope applies when it is not implied by the request or context:
internal only, or internal + external.

## Step 5 — Discover, resolve, and patch docs

Filter files by the chosen scope, then resolve symlinks and edit the **real
paths** — never the symlink:

```bash
for f in CLAUDE.md AGENTS.md GEMINI.md README.md STATUS.md; do
  [ -e "$f" ] && echo "$f exists" && readlink -f "$f"
done
```

Typical updates:

- **README.md** — skill/command tables, version badges, feature lists
- **STATUS.md** — current state, blockers, next steps
- **AGENTS.md** — agent/skill rosters, capability descriptions
- **CLAUDE.md** / **GEMINI.md** — skill references, structure tables
- **docs/** — any page describing changed behavior

Preview the changes. Skip files needing no change. On a blocker, ask whether to
skip that doc and continue, abort, or retry.

## Step 6 — Write

- **CHANGELOG.md**: create it with a standard Keep a Changelog header if
  missing, then insert or merge the drafted entry at the top.
- **Project docs**: apply the confirmed patches to resolved real paths only.

## Step 7 — Report

Emit one box inside a fenced code block tagged `text`. One line per file
touched: name, then what changed. Never narrate the doc contents in the box.

```text
┌─ DOCS UPDATED · v1.2.0 · internal + external
│ CHANGELOG  [1.2.0] entry — 3 items
│ README     2 lines patched
│ AGENTS     1 line  (symlink → agents_db/git-stack/AGENTS.md)
│ CLAUDE     3 lines (symlink → vault/.claude/CLAUDE.md)
│ next       tag and push via the git-ops release flow
└─
```

Formatting rules are in the `git-ops` skill under "Report format" — always
fenced, left border only, no markdown inside the box, aligned label column.

A summary of *what the docs now say* is prose: put it after the fence as plain
sentences, never as `│`-prefixed lines. The box lists files and line counts only.

Never run the tag, commit, or push yourself — report them as next actions.

## Notes

`scripts/git-stack.sh` is a generated copy of `src/scripts/git-stack.sh` in the
git-stack repository, distributed here so this skill runs standalone. Edit the
source and run `node src/sync-scripts.mjs`; never edit the copy.
