---
description: Tag a release version, update CHANGELOG.md (promoting [Unreleased]), bump manifests, and push the tag. Asks only when something is truly off.
version: 1.3.0
allowed-tools: Bash, Read, Edit, Write, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit to infer)"
---

# /release — Tag a Release

Create a git tag for a release version, update CHANGELOG.md, bump manifests, and push the tag.

## Operating principle — releasing is the consent

The user typed `/release`. That **is** the instruction to cut a release — proceed.

- **Version known + clean state → run end to end**, no confirm gate. Show the DONE box after.
- **Stop ONLY when something is truly off:** uncommitted changes, not on `main`, manifest mismatch that won't auto-fix, or (no arg) the bump level is ambiguous.
- When you must stop, surface it through the **`AskUserQuestion` interactive modal** (keep confirmations in the modal, never inline text).
- Recap / blocker / done go in a **left-border box**: top/bottom rule + left `│` only, no right border, no corners.

Unlike `/changelog` and `/update-docs`, a release **needs a version** — there's no `[Unreleased]` outcome here. If no version is given, infer one; ask only if the level is ambiguous.

---

## Step 1 — Determine version

If `$ARGUMENTS` is provided, use it (strip leading `v` for the changelog entry, keep for the tag).

If no argument:
- `git tag --sort=-version:refname | head -5` and `git log --oneline -10`.
- Infer the next version from changes since last tag: Breaking → major · new features/commands → minor · fixes/docs → patch.
- **Unambiguous → use it and proceed.** **Ambiguous** (changes don't point to one level) → blocker. Modal: **Patch X.Y.Z** / **Minor X.Y.0** / **Major X.0.0** (computed).

---

## Step 2 — Verify clean state

```bash
git status -sb
git branch --show-current
```

- **Uncommitted changes** → blocker. Modal: **Commit first** / **Proceed anyway** / **Abort**.
- **Not on `main`** (or the designated release branch) → blocker. Modal: **Tag here anyway** / **Abort**. A non-default branch is outside the simple release path.
- **Clean + on `main`** → proceed silently.

---

## Step 2.5 — Bump manifests + audit against target

`/release` owns version alignment end-to-end. Two passes: bump everything, then verify.

### 2.5a. Dry-run preview
```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/bump-manifests.sh" "$VERSION" --dry-run
```

Show the planned writes. If exit 2 (no manifests detected), note "no project-level manifests — only CHANGELOG/tag will change" and skip 2.5b/2.5c. Otherwise proceed to the bump — invoking `/release` is consent to bump manifests to the target.

### 2.5b. Execute bump
```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/bump-manifests.sh" "$VERSION"
```

- **Exit 0**: continue.
- **Exit 1**: a write failed. Surface stderr and **abort** — some files may be partially updated, do not commit or tag in this state.

### 2.5c. Post-write audit (the real gate)
```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/git-guard}/scripts/check-manifests.sh"
```

Verify every reported version equals `$VERSION`:

- **All entries == `$VERSION`** → ✓ continue.
- **Some entry ≠ `$VERSION`** (CHANGELOG top entry gets written in Step 3, or a manifest the bumper doesn't know about) → **auto-fix**: re-run `bump-manifests.sh "$VERSION"`, then re-audit once.
  - Now aligned → continue.
  - Still drifting → blocker. Show offenders in a box, then modal: **Ship with mismatch** / **Abort**.
- **Exit 2 (nothing found)**: continue.

Component-level versions (per-skill / per-command frontmatter) are shown for visibility only — they evolve independently and never block.

---

## Step 3 — Update CHANGELOG.md

```bash
cat CHANGELOG.md 2>/dev/null | head -10 || echo "NO_CHANGELOG"
```

Resolve the entry for `$VERSION` (consent already given — write it, no per-entry confirm):

- **`[Unreleased]` section exists** → **promote it**: rename `## [Unreleased]` → `## [X.Y.Z] — YYYY-MM-DD`, and leave a fresh empty `[Unreleased]` above. This is the common path — the work was logged unreleased and is now being cut.
- **Top entry already `[X.Y.Z]`** → leave it as-is, continue.
- **Neither** → collect commits since last tag and draft a dated entry:
  ```bash
  git log $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD --oneline
  ```
  Insert it at the top (below the header, above existing entries), today's date.

Stop here only if the diff can't be classified confidently → `AskUserQuestion` with candidate buckets.

---

## Step 4 — Commit changelog (if changed)

If CHANGELOG.md was updated:
```bash
git add CHANGELOG.md
git commit -m "chore: release vX.Y.Z"
git push
```

---

## Step 5 — Tag and push

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

Report: tag name, commit it points to, remote URL.

---

## Step 6 — Report

Left-border box. Left `│` only, no right border.

```
┌─ RELEASED · v1.2.0
│ VERSION    1.2.0  (minor — new capability, backward-compatible)
│ COMPONENTS cli/spectacular 1.1.3 → 1.2.0 ✓  ·  SKILL.md 1.1.4 → 1.2.0 ✓
│ MANIFESTS  .claude-plugin/plugin.json       1.1.4 → 1.2.0
│            .claude-plugin/marketplace.json  1.1.4 → 1.2.0  (.metadata + .plugins[])
│            .codex-plugin/plugin.json         1.1.4 → 1.2.0
│            README.md badge                   1.1.4 → 1.2.0
│ CHANGELOG  [1.2.0] (promoted from [Unreleased])
│ COMMIT     abc1234  chore: release v1.2.0
│ TAG        v1.2.0 → origin
│ PRE-FLIGHT [CLEAN] clean tree · [CLEAN] manifests aligned · [INFO] on main
│ REMOTE     https://github.com/user/repo
│ NEXT       gh release create v1.2.0 --generate-notes
│            /plugin marketplace update <plugin-name>   (if a CC plugin)
└─
```

Collapse MANIFESTS to a count (`6 bumped → 1.2.0`) only when there are more than ~6.

All version-bearing manifests were bumped in Step 2.5. Manifest files added outside the bumper's detection (rare) need manual alignment.
