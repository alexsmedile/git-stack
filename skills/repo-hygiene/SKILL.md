---
name: repo-hygiene
description: >
  Repo hygiene and space reclaim — surface dead, stale, and unsynced branches,
  untracked junk, forgotten stashes, and .git bloat, then clean up safely. Use
  for "clean up this repo", "prune branches", "why is .git so big", "reclaim
  space", or repo triage before publishing. Read-only by default; history
  rewrites stay behind an explicit destructive-action gate.
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
metadata:
  version: "1.0.1"
---

# repo-hygiene

Repo cleanup in three tiers by blast radius. Read `references/tiers.md` for the
canonical checks, commands, and severity rules — this file owns the sequence and
the confirmation gates.

```text
Tier 1  report only        — dead/stale/unsynced branches, junk, stashes  (always safe)
Tier 2  safe housekeeping  — git gc, remote/worktree prune                (the real space win)
Tier 3  history rewrite    — purge big blobs, squash                      (DESTRUCTIVE)
```

## Operating principle — report first, delete never by default

Being asked to clean up a repo is consent to **scan and report**. It is not
consent to delete. Run Tier 1, print the report, and ask before any deletion.

- **Default → Tier 1 only.** Read-only. Always safe.
- **`--deep` / "deep clean" → Tier 1 + Tier 2.** Adds safe `gc` and prune passes
  after the report.
- **`--purge` / an explicit request to reclaim `.git` space → unlocks Tier 3**
  behind a hard confirmation gate. Never runs without it, even when asked.

## Step 1 — Scan (always)

One read-only call returns every Tier 1 count. It fetches and prunes first, and
never writes. The script ships inside this skill:

```bash
bash "${CLAUDE_SKILL_DIR:-<skill-directory>}/scripts/git-stack.sh" cleanup
```

Resolve `<skill-directory>` to this skill's directory on runtimes that do not
set `CLAUDE_SKILL_DIR`; in a Claude plugin install, use
`${CLAUDE_PLUGIN_ROOT}/skills/repo-hygiene/scripts/git-stack.sh`.

Keys: `BRANCHES_MERGED`, `BRANCHES_STALE`, `BRANCHES_UNSYNCED`, `BRANCHES_GONE`,
`STASHES`, `OLDEST_STASH`, `PACKED_SIZE`, `LOOSE_SIZE`, `LOOSE_OBJECTS`,
`TRACKED_JUNK`. `BLOCKER=not-a-git-repository` → stop.

`VERDICT` reflects only what needs a human decision — branches, stashes, tracked
junk. It deliberately ignores loose objects, which git creates on every commit
and packs on its own schedule. `VERDICT=CLEAN` → say so and stop, **unless**
`SUGGEST=gc` is also present.

`SUGGEST=gc` (emitted above 500 loose objects) is a tier-2 maintenance hint, not
dirt: offer `git gc`, but do not describe the repo as needing cleanup on its
account. It can accompany either verdict.

Tune the stale window with `--stale-days <n>` (default 90).

## Step 2 — Report

Print one box from the counts above. Do **not** re-run raw git scans to build
it. Fetch names only for categories the user chooses to act on in Step 3 — e.g.
`git branch --merged main` when they accept the merged-branch deletion.

```text
┌─ CLEANUP REPORT · ~/code/example-repo · main
│ merged branches   2   feature/login, fix/typo        (safe to delete)
│ stale branches    1   wip/experiment  (4 months old)
│ unsynced          1   feature/api  ahead 3 / behind 0 (unpushed)
│ untracked junk    3   .DS_Store, dist/, *.pyc         (suggest gitignore)
│ stale stashes     1   stash@{0}  3 weeks ago
│ repo size         .git 142 MB · 1,204 loose objects
│ big blobs         old-data.zip 88 MB  (Tier 3 — needs explicit opt-in)
└─
```

Always inside a fenced code block tagged `text` — outside a fence the renderer
reflows the border into a broken ladder. Left border only, no right `│`, no
closing corners. Full rules: `git-ops` SKILL.md → "Report format".

If everything is clean, say so in the box and stop.

## Step 3 — Offer safe actions

From the report, offer the **safe** actions as a multi-select:

- Delete merged branches (via `git branch -d`, which refuses unmerged work)
- Drop a named stale stash (after showing `git stash show -p`)
- Append suggested lines to `.gitignore`

Each is reversible or guarded. Apply only what the user picks. Diverged branches
are **reported, not touched** — that is a merge decision, not cleanup.

## Step 4 — Tier 2 (only on an explicit deep clean)

Run the safe housekeeping from `references/tiers.md` Tier 2: `git gc
--prune=now`, `git remote prune origin`, `git worktree prune`. Announce each,
then show before/after `git count-objects -vH`. No per-item confirmation needed
— these do not lose history.

## Step 5 — Tier 3 (only on explicit opt-in, behind a hard gate)

Tier 3 **rewrites history and requires a force-push that breaks every existing
clone.** Never reach this tier from a generic cleanup request.

1. Show the big-blob report (read-only) so the user can judge whether a purge is
   worth it.
2. Present this warning and require an explicit non-abort choice:

```text
┌─ ⚠ HISTORY REWRITE — DESTRUCTIVE
│ This rewrites all commit SHAs after the affected blob.
│ A force-push is required. Every existing clone/fork BREAKS.
│ Confirm you control all clones and have a backup (git clone --mirror).
└─
```

Offer **Abort (recommended)** / **Purge big blob** / **Squash old commits**,
defaulting to Abort.

- **Purge** → `git filter-repo --invert-paths --path <file>`, then push with
  `--force-with-lease`. Requires `git-filter-repo`; if it is missing, tell the
  user to `brew install git-filter-repo` and stop.
- **Squash** → state plainly that it is cosmetic and saves no meaningful space.
  If still wanted, use the orphan-branch technique in the `git-ops` skill's
  `references/core.md` → "History rewriting".

Never proceed past this gate without an explicit non-abort choice. Prefer
`--force-with-lease` over `--force`; it fails safely if the remote has moved.

## Step 6 — Done box

```text
┌─ CLEANUP DONE
│ deleted    2 merged branches
│ gitignore  +2 lines (.DS_Store, dist/)
│ gc         .git 142 MB → 54 MB · 1,204 → 0 loose objects
│ skipped    feature/api (unpushed) · 1 diverged branch (needs merge)
└─
```

## Notes

- Tiers, commands, and severity live in `references/tiers.md`. If this file
  drifts from it, `tiers.md` wins.
- Space reality: `git gc` (Tier 2) is the safe space win. Squashing commits is
  cosmetic. Only a Tier 3 blob purge reclaims `.git` bloat — at the cost of a
  force-push.
- Requires the `git` CLI. Tier 3 purge additionally requires `git-filter-repo`.
- `scripts/git-stack.sh` is a generated copy of `src/scripts/git-stack.sh` in
  the git-stack repository, distributed here so this skill runs standalone. Edit
  the source and run `node src/sync-scripts.mjs`; never edit the copy.
