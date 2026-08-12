# git-stack / cleanup — Repo Hygiene & Space Reclaim

Canonical checks and severity rules for repo cleanup. Owned here; the `/cleanup`
command is a thin orchestrator that runs these in order and asks before deleting.

Three tiers by blast radius. **Tier 1 is read-only and always safe. Tier 2 is
safe native housekeeping. Tier 3 rewrites history — never default, hard warning,
explicit opt-in only.**

```
Tier 1  report only        — list dead/stale/unsynced branches, junk, stashes
Tier 2  safe housekeeping  — git gc, remote prune (the real space win)
Tier 3  history rewrite    — purge big blobs, squash old commits (DESTRUCTIVE)
```

**The space-saving truth:** Git stores compressed deltas, not per-commit
overhead. Squashing commits saves a few KB and is **cosmetic**. Real `.git`
bloat comes from large blobs committed once and never removed — only a history
rewrite (Tier 3) reclaims that, and only at the cost of a force-push. `git gc`
(Tier 2) reclaims loose/unreachable objects safely and is what you want 95% of
the time.

---

## Tier 1 — Surface report (read-only, never destructive)

Run all checks, collect findings, print one report. No deletions in this tier —
deletions happen only after the user picks them from the report.

### 1a. Merged branches (safe to delete)
Local branches already merged into the default branch:
```bash
git branch --merged main | grep -vE '^\*|  (main|master)$'
```
Severity: INFO. These are safe to delete — their commits live on in `main`.

### 1b. Stale branches (age, not merge status)
Branches with no commit activity in N months (default 3):
```bash
# branch name + last-commit date, sorted oldest first
git for-each-ref --sort=committerdate refs/heads/ \
  --format='%(committerdate:relative)%09%(refname:short)'
```
Severity: INFO. Old + unmerged = ask before touching; the work may be unfinished.

### 1c. Unsynced branches (ahead / behind / diverged)
Branches whose local state differs from their upstream:
```bash
git fetch --quiet
for b in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
  up=$(git rev-parse --abbrev-ref "$b@{upstream}" 2>/dev/null) || continue
  counts=$(git rev-list --left-right --count "$b...$up" 2>/dev/null)
  echo "$b  ahead/behind vs $up: $counts"
done
```
Read as `ahead<TAB>behind`. Severity: INFO (ahead = unpushed work — never delete),
WARN if diverged (both nonzero — needs a rebase/merge decision, not cleanup).

### 1d. Untracked junk
Untracked files that look like noise and aren't gitignored:
```bash
git status --porcelain --untracked-files=all | grep '^??' | \
  grep -iE '(\.DS_Store|Thumbs\.db|\.swp$|~$|node_modules/|__pycache__/|\.pyc$|/(dist|build|out|target)/)'
```
Severity: MEDIUM. Suggest gitignore lines rather than deleting — the file may matter.

### 1e. Stale stashes
```bash
git stash list --format='%gd  %cr  %s'
```
Severity: INFO. List with age; old stashes are usually forgotten WIP. Never drop
without showing the user what's in each (`git stash show -p stash@{N}`).

### 1f. Repo size snapshot (motivates Tier 2/3)
```bash
git count-objects -vH | grep -E 'size-pack|count|in-pack'
```
Report total `.git` size and loose-object count so the user can judge if Tier 2/3
is worth it.

---

## Tier 2 — Safe housekeeping (native git, no history loss)

Reversible-by-nature operations. Safe to run without per-item confirmation, but
still announce what each does first.

### 2a. Garbage-collect & repack
```bash
git gc --prune=now
```
Compresses loose objects, removes unreachable ones past their grace window. **This
is the real, safe space reclaim.** Preview the win with `git count-objects -vH`
before and after.

### 2b. Prune stale remote-tracking refs
```bash
git remote prune origin          # preview: git remote prune origin --dry-run
```
Removes `origin/*` refs for branches deleted on the remote. Local branches untouched.

### 2c. Prune stale worktree refs
```bash
git worktree prune
```
Cleans references to worktrees whose directories are gone.

### 2d. Delete the merged branches from 1a (only the ones the user picked)
```bash
git branch -d <branch>           # -d refuses if not merged; never use -D here
```
Use `-d` (safe), never `-D`, in cleanup — `-d` is a built-in guard against
deleting unmerged work.

---

## Tier 3 — History rewrite (DESTRUCTIVE · opt-in only · hard warning)

**STOP. Everything below rewrites history → new SHAs → force-push required →
breaks every existing clone/fork.** Per git-ops safety rules #2 and #3: never
on a shared branch without explicit confirmation. Run `git fetch` first, confirm
you control all clones, and present the warning via `AskUserQuestion` before any
command here. Default answer is always "don't."

### 3a. Find the big blobs (read-only — safe to always show)
Largest objects in history, so the user can decide if a purge is worth it:
```bash
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  awk '/^blob/ {print $3, $4}' | sort -rn | head -20
```
This is the only Tier 3 step that's safe by default — it just reports. Reclaiming
the space needs 3b.

### 3b. Purge a big file from all history
Requires `git-filter-repo` (`brew install git-filter-repo`) — safer and faster
than `filter-branch`.
```bash
git filter-repo --invert-paths --path path/to/bigfile.zip
git push --force-with-lease origin main      # rewrites remote history
```
**Guardrails:** back up the repo first (`git clone --mirror`); every collaborator
must re-clone afterward; tags pointing at rewritten commits move SHAs — re-verify.

### 3c. Squash old commits (COSMETIC — advise against)
Merging small/untagged old commits into fewer commits. **Near-zero space gain,
full history-rewrite risk.** Only do this for a pre-publish cleanup of a repo you
fully control, and prefer the orphan-branch technique in `core.md` → "History
rewriting — squash all commits into one clean root" over interactive rebase.
When the user asks for this, state plainly: it doesn't save meaningful space and
breaks shared history — confirm they still want it before proceeding.

---

## Severity summary

| Finding | Tier | Severity | Default action |
|---|---|---|---|
| Merged branch | 1a | INFO | offer delete (`-d`) |
| Stale unmerged branch | 1b | INFO | list, ask |
| Diverged branch | 1c | WARN | report, don't touch (not cleanup) |
| Untracked junk | 1d | MEDIUM | suggest gitignore line |
| Stale stash | 1e | INFO | list with age, ask |
| Loose objects / bloat | 2a | INFO | `git gc` (safe) |
| Stale remote refs | 2b | INFO | `git remote prune` (safe) |
| Big blob in history | 3a/3b | HIGH | report; purge only on explicit opt-in |
| Old/untagged commits | 3c | LOW | advise against — cosmetic, breaks history |
