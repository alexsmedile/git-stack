---
description: Close out a session — commit + push the edits so far, then optionally tag a release. Runs /commit + /push always; adds /update-docs + version bump + tag only when releasing.
version: 2.1.0
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit to auto-detect)"
---

# /wrap-up — Session Wrap-Up

`/wrap-up` **closes out the session: it saves the edits so far** — committed and pushed. Tagging a release (with its docs + version bump) is an *optional* add-on, not the default.

```
/commit  →  /push                                   ← always (the wrap-up)
            ↘  /update-docs  →  bump  →  tag         ← only when the user confirms a release
```

It is a **pipeline**, not a reimplementation. Each stage **reuses the exact logic of the underlying command** — same checks, same blocker rules, same boxes. wrap-up owns only the *sequencing* and the optional *release extras* (version bump + tag).

## Operating principle — wrap-up closes the session; tagging is a release decision

`/wrap-up` means: **close the session and save the work** (commit + push). It does **not** automatically cut a release — the edits so far may not be a version the user wants to stamp. Because there is no dedicated release/tag command, the tag decision lives here, and it **always needs the user's confirmation**.

- **No version argument → close the session (commit + push), then ask whether to tag a release.** Commit + push the edits for a simple change with no questions; then, as the final step, surface the tag decision via `AskUserQuestion` (see Phase 6). Docs + version bump run only if the user then opts to tag.
- **Version argument given (`/wrap-up 1.2`) → that *is* the release signal.** The user naming a version means "yes, tag it 1.2." Run the full pipeline — commit, push, docs, bump, tag — no extra tag question.
- **Stop earlier than the tag step only when something is truly off** — same blocker bar as `/commit` and `/push`, plus the release-specific one (see below).
- When you must stop or ask, surface it through the **`AskUserQuestion` interactive modal** (keep all confirmations in the modal, never in inline text).
- Every recap / blocker / done goes in a **left-border box** — see "Box style".

### What counts as a blocker (the only reasons to stop)

Same guiding rule as `/commit` and `/push`: **what's simple stays simple; what's outside simplicity needs clarity first.** A release of a simple, verified, non-breaking change **on `main`** runs end to end with no questions.

Inherit the blocker list from `/commit` and `/push`:
- **Not on `main`** — any branch other than `main`/`master` → stop, clarify intent via `AskUserQuestion` before tagging/pushing.
- **Breaking / unverified change** — could break the build or other code, or not yet verified → clarify first.
- personal/secret files · stale/outdated folders staged · errors · missing files · diverged remote · genuine ambiguity.

Plus one release-specific one (only relevant once a release is actually happening):
- **Manifest mismatch that won't auto-fix** — version-bearing files still disagree after a re-bump.

Note: a **missing version is not a blocker** — it simply means "just save, don't release" (Phase 2). The tag decision is handled by asking at Phase 6, not by blocking.

Everything else is handled with a sensible default and proceeds: MEDIUM notes get reported in the DONE box; leftover unstaged tracked files get included via `git add -u`. Working on `main` is the normal case: list the branch as a plain `branch  main → origin/main` field in the DONE box, the same way you'd list any other branch.

### Box style

Left-border box for every recap / blocker / done. No right border, no corners — so it never misaligns:

```
┌─ TITLE · context
│ label   value
│ label   value
└─
```

Never draw a right-side `│` or `┐`/`┘` corners — those need exact padding and break.

---

## Phase 1 — Repo snapshot (silent)

```bash
git status
git diff --stat
git status --porcelain          # for NEW vs EDITED classification (see below)
git log --oneline -10
git tag --sort=-version:refname | head -5
git branch --show-current
git remote -v
```

Identify: last tag, current branch, remote URL, uncommitted changes, unpushed commits.

**Capture for the Phase 7 recap** — collect these now so the final box can report them:
- **NEW vs EDITED files** — from `git status --porcelain`: `A`/`??` (that will be staged) = new; `M` = edited. Keep both lists.
- **Pre-flight results** — as the /commit stage (Phase 3a) runs its checks, record each as `[CLEAN]` or `[INFO]/[MEDIUM] …` for the recap.
- **Component versions** — note any per-skill / per-command / cli version strings you bump by hand so they appear under COMPONENTS.
- **Untracked left alone** — any `??` files you deliberately do not stage → NOTES.

**Nothing-to-do exit:** if the working tree is clean AND no unpushed commits — nothing to save. Say so in a box and stop. (Not a consent gate, just an empty result.)

---

## Phase 2 — Release or just-save?

This decides whether the optional release steps (version bump + tag) run at all.

- **`$ARGUMENTS` carries a version** (`/wrap-up 1.2`) → **this is a release.** The user naming a version is explicit "tag it." Set `RELEASE=yes`, `VERSION=1.2.0`, skip the tag question entirely. Go to Phase 3.
- **No version argument** → **default to just-save.** Set `RELEASE=no` for now. Run the save pipeline (Phase 3), then ask the tag decision at Phase 6. Do not bump or tag before that confirmation.

---

## Phase 3 — Save the session (always runs)

This is the core of wrap-up — it runs whether or not this becomes a release.

### 3a. Run /commit
Execute the `/commit` flow. Reuse its preflight + blocker logic exactly — secrets / personal files / stale folders / missing files / branch check all apply. Message:
- `RELEASE=yes` → `chore: release vX.Y.Z — <one-line summary>`
- `RELEASE=no` → a normal Conventional Commits message summarizing the session's edits.

Include unstaged tracked files via `git add -u`, unless a blocker says otherwise. Consent is already given, so a clean preflight commits without a gate.

### 3b. Run /push
Execute the `/push` push step. Reuse its remote-state + blocker logic exactly (diverged remote = blocker, never force push).

```bash
git push        # or --set-upstream origin <branch> if no upstream
```

At this point the session is saved. If `RELEASE=yes`, continue to Phase 4. If `RELEASE=no`, go to Phase 6 to offer the tag.

---

## Phase 4 — Update docs for the release  *(release path only)*

Run the `/update-docs` flow for `VERSION`: draft the CHANGELOG entry and patch project docs (README, AGENTS, CLAUDE, GEMINI — resolving symlinks). Reuse its logic exactly. Write straight through its confirm gate — wrap-up already has consent; stop only on a blocker.

---

## Phase 5 — Bump manifests  *(release path only)*

```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/bump-manifests.sh" "$VERSION" --dry-run
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/bump-manifests.sh" "$VERSION"
```

Writes `VERSION` into every detected manifest (plugin.json, marketplace.json, package.json, pyproject.toml, Cargo.toml, README badge…). Idempotent.
- **Exit 1** (write failed) → surface stderr, **abort before tagging** (partial writes possible).
- **Exit 2** (no manifests) → fine, only CHANGELOG/README changed.

### Alignment audit (the real release gate)
```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/check-manifests.sh"
```
Verify every project-level version equals `VERSION`:
- Aligned → continue.
- Drift → **auto-fix**: re-run `bump-manifests.sh "$VERSION"`, re-check once. Still drifting → blocker. Modal: **Commit as-is** / **Abort**.
- No manifests → continue.

Then commit the docs + manifest changes (`docs: release vX.Y.Z` or fold into the release commit if 3a hasn't run yet for this version) and continue.

---

## Phase 6 — Tag decision

**`RELEASE=yes` (version was given) → tag directly**, no question:
```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```
If the tag already exists, report and skip — never clobber.

**`RELEASE=no` (no version given) → ask via `AskUserQuestion`.** The session is already saved (committed + pushed); tagging a release is a separate decision the user must make, because the edits so far may not be a version they want to stamp. Show context in a box, then the modal:

```
┌─ SESSION SAVED — tag a release?
│ commit   abc1234  <summary>
│ branch   main → origin/main
│ suggest  v1.3.0  (inferred: minor — 1 added)
└─
```

`AskUserQuestion` options:
- **Tag <suggested>** — accept the inferred version (Breaking → major · Added → minor · Fixed/Changed → patch).
- **Tag a different version** — user supplies it.
- **No tag, just close** — done; the session is saved without a release.

If the user opts to tag, run Phases 4 → 5 now (docs + manifest bump for the chosen version), then tag and push the tag.

---

## Phase 7 — Final report

One left-border box — the close-out recap of **what was done**. It must carry the full substance, clearly labelled. Include every section that applies; drop a section only when it has nothing (e.g. no new files). Collapse long lists into a one-line summary with a count.

### Required sections (in this order)

- **VERSION** — the version + bump level + *why* (e.g. `1.9.0  (minor — new capability, backward-compatible)`). On just-save: `[Unreleased] — not tagged`.
- **NEW** — files created this session. If many, summarize: `3 files (docs/, scripts/)`. Omit if none.
- **EDITED** — files updated. Summarize if many: `5 files patched`. Omit if none.
- **COMPONENTS** — component-level bumps (per-skill / per-command frontmatter, cli version strings), each `old → new ✓`. Omit if none.
- **MANIFESTS** — project manifest bumps, listed per file `old → new` (plugin.json, marketplace.json, codex-plugin, package.json, README badge…). Collapse to a count only if more than ~6.
- **CHANGELOG** — the entry written: `[1.9.0] — 1 Added` or `[Unreleased] — 2 items`.
- **COMMIT** — hash + message.
- **TAG** — `v1.9.0 → origin` / `none — not released`.
- **PUSH / BRANCH** — `main → origin/main` (+ tag if pushed).
- **PRE-FLIGHT** — the checklist results: `[CLEAN]` for each check that passed, `[INFO]`/`[MEDIUM]` for anything noted (on `main`, untracked files deliberately left, etc.). This is where the secrets/paths/large-file/gitignore checks report their outcome.
- **NOTES** — anything the user should know: untracked files left alone, manifest files needing manual alignment, etc.

### Release path — full recap
```
┌─ WRAPPED UP · v1.9.0
│ VERSION     1.9.0  (minor — new versioning doc, backward-compatible)
│ NEW         docs/versioning.md · docs/docs.yaml (nav entry)
│ EDITED      SKILL.md
│ COMPONENTS  cli/spectacular  1.8.3 → 1.9.0 ✓   ·   SKILL.md  1.8.4 → 1.9.0 ✓
│ MANIFESTS   .claude-plugin/plugin.json       1.8.4 → 1.9.0
│             .claude-plugin/marketplace.json  1.8.4 → 1.9.0  (.metadata + .plugins[])
│             .codex-plugin/plugin.json         1.8.4 → 1.9.0
│             README.md badge                   1.8.4 → 1.9.0
│ CHANGELOG   [1.9.0] — 1 Added (versioning convention doc)
│ COMMIT      abc1234  docs: add versioning convention — release v1.9.0
│ TAG         v1.9.0 → origin
│ PUSH        main → origin/main  +  tag
│ PRE-FLIGHT  [CLEAN] secrets · [CLEAN] paths · [CLEAN] large files · [INFO] on main
│ NOTES       untracked left alone: FEEDBACKS.md, IDEAS_BRIEF.md
└─
```

### Just-save path (declined tag) — recap
```
┌─ WRAPPED UP · session saved
│ VERSION     [Unreleased] — not tagged
│ EDITED      4 files patched
│ CHANGELOG   [Unreleased] — 2 items (1 added, 1 fixed)
│ COMMIT      abc1234  fix: tighten preflight wording
│ PUSH        main → origin/main
│ PRE-FLIGHT  [CLEAN] secrets · [CLEAN] paths · [INFO] on main
│ NOTES       not released — run /release <version> or /wrap-up <version> to cut a tag
└─
```
