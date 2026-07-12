---
description: Repo hygiene scan — surface dead/stale/unsynced branches, junk, stashes, and reclaim space. Read-only by default; --deep runs safe gc/prune; history rewrites stay behind a hard warning.
version: 1.0.0
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[--deep | --purge]"
---

# /cleanup — Repo Hygiene & Space Reclaim

Thin orchestrator. Owns the **sequence and confirmation flow**. Delegates **what
to check** to the `git-ops` skill — load `skills/git-ops/references/cleanup.md`
and apply the tiers and severity rules defined there.

## Operating principle — report first, delete never (by default)

The user typed `/cleanup`. That **is** consent to *scan and report*. It is **not**
consent to delete anything. Run Tier 1 read-only, print the report, and ask before
any deletion or destructive action.

- **No args → Tier 1 only** (read-only report). Always safe. Show the report box.
- **`--deep` → Tier 1 + Tier 2** (adds safe `git gc` / `remote prune` after the report).
- **`--purge` → unlocks Tier 3** (big-blob purge / squash) behind a hard `AskUserQuestion` gate. Never runs without it, even with the flag.
- All output that needs the user's eyes goes in a **left-border box** (see Box style).

### Box style

```
┌─ TITLE · context
│ label   value
└─
```
Left border only — no right `│`, no corners (they break on padding).

---

## Step 1 — Repo state

```bash
git rev-parse --is-inside-work-tree 2>/dev/null || echo "not a git repo"
git fetch --quiet 2>/dev/null
```
Not a git repo → stop, tell the user.

---

## Step 2 — Tier 1 scan (always)

Run every Tier 1 check from `cleanup.md` (1a–1f). **Collect all findings first,
then print one report box.** Nothing is deleted in this step.

```
┌─ CLEANUP REPORT · /Users/alex/repo · main
│ merged branches   2   feature/login, fix/typo        (safe to delete)
│ stale branches    1   wip/experiment  (4 months old)
│ unsynced          1   feature/api  ahead 3 / behind 0 (unpushed)
│ untracked junk    3   .DS_Store, dist/, *.pyc         (suggest gitignore)
│ stale stashes     1   stash@{0}  3 weeks ago
│ repo size         .git 142 MB · 1,204 loose objects
│ big blobs         old-data.zip 88 MB  (Tier 3 — needs --purge to remove)
└─
```

If everything is clean → say so in the box and stop. Nothing to do.

---

## Step 3 — Offer safe actions

From the report, offer the **safe** actions via `AskUserQuestion` (multi-select):

- Delete merged branches (1a, via `git branch -d` — refuses unmerged work)
- Drop a named stale stash (after `git stash show -p`)
- Append suggested lines to `.gitignore` (1d)

Each is reversible or guarded. Apply only what the user picks. Diverged branches
(1c WARN) are **reported, not touched** — that's a merge decision, not cleanup.

---

## Step 4 — Tier 2 (only with `--deep`)

If `--deep` was passed, after Step 3 run the safe housekeeping from `cleanup.md`
Tier 2: `git gc --prune=now`, `git remote prune origin`, `git worktree prune`.
Announce each, then show before/after `git count-objects -vH`. No per-item confirm
needed — these don't lose history.

---

## Step 5 — Tier 3 (only with `--purge`, behind a hard gate)

Only if `--purge` was passed. Tier 3 **rewrites history and requires a force-push
that breaks every existing clone** (git-ops rules #2, #3).

1. Show the big-blob report (3a — read-only).
2. Present the warning via `AskUserQuestion`, default = **Abort**:

```
┌─ ⚠ HISTORY REWRITE — DESTRUCTIVE
│ This rewrites all commit SHAs after the affected blob.
│ A force-push is required. Every existing clone/fork BREAKS.
│ Confirm you control all clones and have a backup (git clone --mirror).
└─
```

`AskUserQuestion` options: **Abort (recommended)** / **Purge big blob** / **Squash old commits**.

- **Purge** → `git filter-repo --invert-paths --path <file>` then `--force-with-lease` (per `cleanup.md` 3b). Requires `git-filter-repo`; if missing, tell the user to `brew install git-filter-repo` and stop.
- **Squash** → state plainly it's cosmetic and saves no meaningful space; if still wanted, use the orphan-branch technique in `core.md` → "History rewriting".

Never proceed past this gate without an explicit non-Abort choice.

---

## Step 6 — Done box

```
┌─ CLEANUP DONE
│ deleted    2 merged branches
│ gitignore  +2 lines (.DS_Store, dist/)
│ gc         .git 142 MB → 54 MB · 1,204 → 0 loose objects
│ skipped    feature/api (unpushed) · 1 diverged branch (needs merge)
└─
```

---

## Notes

- Tiers, commands, and severity live in `git-ops/references/cleanup.md`. If this command drifts from it, cleanup.md wins.
- Space reality: `git gc` (Tier 2) is the safe space win. Squashing commits is cosmetic. Only a Tier 3 blob purge reclaims `.git` bloat — at the cost of a force-push.
