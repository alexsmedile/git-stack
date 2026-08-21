# Feedback

## Nothing says which branch new work belongs on

`skills/git-ops/SKILL.md:177` covers switching branches safely ("check for
uncommitted changes before switching — stash or commit first"). Nothing covers the
decision one step earlier: **given a task, which branch should it go on.**

That gap produced a real mess in a Spectacular session.

### What happened

An active feature branch (`m7-derived-state`) was mid-Mission, with commits landing
throughout the session. A side task came up: rewrite the prose of `SKILL.md` and
its references.

The reasonable-looking move was a clean branch off `main`, so the docs could ship
as an isolated PR without the feature branch's ~4,800 lines of Go. That is exactly
what the "small focused PR" instinct recommends.

It was wrong, because **both branches then edited the same files.** The feature
branch kept committing its own changes to `SKILL.md` while the docs branch
rewrote it. Result:

- `main` and the feature branch diverged 23 commits vs 3
- the feature branch carried *pre-rewrite* copies of eight reference files
- merging it without care would have silently reverted the entire rewrite
- three conflicts had to be resolved by hand, two of them in one file

Isolation only pays off when the file sets are disjoint. When they overlap, a
separate branch does not avoid the merge — it schedules a worse one for later.

### The rule that was missing

Before starting work on a new branch, check whether an active branch already
modifies those files. If it does, work there.

```bash
git status --short <paths>              # already in flight in this tree?
git diff --stat main <branch> -- <paths>  # does another branch already touch them?
```

Cheap to run, and it answers the only question that matters: *is anyone else
editing these lines right now.*

### A second trap: worktrees hold their branch

The docs work was done in a worktree, which was correct — the main tree had
uncommitted changes and could not check out `main`. But the worktree was left in
place, and later:

```
fatal: 'main' is already used by worktree at '/private/tmp/.../skills-wt'
```

A worktree holds its branch exclusively. Nothing warned about this, and nothing
prompted cleanup. `references/core.md` does say "clean up when done
(`git il remove`)" — but only inside the worktree section, not as a check that runs
when a later checkout fails.

Worth surfacing the reverse mapping: when `checkout <branch>` fails with "already
used by worktree", the fix is `git worktree list` → `git worktree remove <path>`,
not `--force` on the checkout.

### A third: where to resolve a divergence

Once two branches have diverged on the same file, the safe order is:

1. Merge `main` **into** the feature branch
2. Resolve there, keeping both sides deliberately
3. Verify (run the repo's gate)
4. Only then fast-forward `main`

Resolving on `main` instead means a bad resolution is already published. Nothing
in `references/core.md` states the direction.

### Suggested change

Add a pre-flight to the branch/commit path, as a decision rather than a safety
check:

| Question | Action if yes |
|---|---|
| Does an active branch already modify these files? | Work on that branch, not a new one |
| Is a worktree holding the branch I need? | `git worktree list`, then remove it |
| Have two branches diverged on the same file? | Merge into the feature branch, resolve, verify, then ff `main` |

The general principle worth stating once: **a branch is cheap, a conflict is not.**
Optimize for disjoint file sets, not for tidy-looking diffs.

### Where the existing worktree guidance lives

`references/core.md` already documents the worktree flow and says to clean up when
done. The gap is placement, not absence: that advice only appears inside the
worktree section, so an agent that hits the failure later — during a checkout it
did not connect to a worktree it created earlier — never sees it.

## Manifest checks miss the Agent Plugins root `plugin.json`

`check-manifests.sh` and `bump-manifests.sh` detect plugin manifests by looking for
**vendor sidecar directories** — `.claude-plugin/`, `.codex-plugin/`,
`.cursor-plugin/`. Neither knows about a root-level `plugin.json`.

That was fine while every host had its own format. It is now a gap: **Agent Plugins
1.0.0** (https://agent-plugins.org, launched August 2026, TSC of AWS, Cursor,
Microsoft, OpenAI, Vercel, with Google as Core Maintainer) puts a required manifest
at the **repository root**, not in a namespaced directory:

```
plugin-name/
├── plugin.json          ← required, root-level, carries an optional "version"
├── skills/<name>/SKILL.md
└── mcp.json
```

Supported at launch by ChatGPT, Codex, Cursor, GitHub Copilot, Kiro, and VS Code,
so this layout is going to become common rather than rare.

### What happened

Releasing `skizl` v1.10.0 and again at v1.10.1. The repo carries a conformant root
`plugin.json` with `"version"`, alongside the usual `.claude-plugin/` and
`.codex-plugin/` sidecars — seven version sites in total.

`bump-manifests.sh 1.10.0 --dry-run` planned **four** writes and reported success:

```
1.9.0 → 1.10.0  .claude-plugin/plugin.json
1.9.0 → 1.10.0  .claude-plugin/marketplace.json
1.9.0 → 1.10.0  .codex-plugin/plugin.json
1.9.0 → 1.10.0  README.md
✓ Bumped 4 file(s) (skipped 0 already-aligned).
```

`check-manifests.sh` then reported `✓ Project-level versions aligned (1.10.0 across
6 locations)` — a clean audit while the root manifest still said `1.9.0`.

The release only stayed correct because that repo installs a `git-guard` pre-commit
hook that scans all seven sites and blocks on drift. Without it, both releases would
have shipped a root manifest one version behind, silently. The post-write audit is
documented as "the real release gate" (safety rule 16), but it cannot gate a file it
does not look at.

Same miss on both releases, so it reproduces reliably.

### Why it is easy to miss

Every other detection in these scripts keys off a **directory** (`.claude-plugin/`,
`.codex-plugin/`). A bare root file has no such marker, and `plugin.json` at the root
is indistinguishable by name from the sidecar manifests one level down.

### Suggested change

Add a detection block alongside the existing ones, in both scripts. It should key on
the `$schema` value rather than the filename, so an unrelated root `plugin.json`
(for example Antigravity's older private schema) is not swept up:

```bash
# Agent Plugins (root manifest) ----------
if [ -r plugin.json ]; then
  schema=$(jq -r '."$schema" // empty' plugin.json 2>/dev/null)
  case "$schema" in
    https://agent-plugins.org/schemas/*)
      mark_detected "Agent Plugins"
      # "version" is OPTIONAL in the closed schema — only record when present,
      # or every manifest without one reports as drift.
      v=$(json_top_version plugin.json)
      [ -n "$v" ] && add_proj "plugin.json" "$v"
      ;;
  esac
fi
```

Two constraints worth respecting:

- **`version` is optional.** The Agent Plugins schema requires only `$schema` and
  `name`. Treat a missing `version` as "nothing to check", never as drift.
- **The schema is closed** (`additionalProperties: false`). The bumper must not add
  a `version` field to a manifest that omits one — writing an absent key is legal
  here, but adding any *other* key would fail validation downstream.

### Wider point

The sidecar-directory heuristic assumes per-vendor packaging. The industry is moving
to one shared root manifest, so it is worth revisiting the detection model generally
rather than adding Agent Plugins as a one-off — the next standard-conformant layout
will have the same shape.

The snippet above was exercised against four cases before filing:

| Case | Result |
|---|---|
| Conformant manifest with `version` (skizl 1.10.1) | detected, version recorded |
| Conformant manifest without `version` | detected, skipped — no false drift |
| Antigravity's older private `$schema` | correctly ignored |
| Unrelated root `plugin.json`, no `$schema` | correctly ignored |
