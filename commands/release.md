---
description: Tag a release version, update CHANGELOG.md, and push the tag to remote. Runs /update-docs first if CHANGELOG needs updating.
version: 1.0.0
allowed-tools: Bash, Read, Edit, Write
argument-hint: "[version]"
---

# /release — Tag a Release

Create a git tag for a release version, update CHANGELOG.md, and push the tag.

---

## Step 1 — Determine version

If `$ARGUMENTS` is provided, use it as the version (strip leading `v` for changelog entry, keep for tag).

If no argument:
- Run `git tag --sort=-version:refname | head -5` to see recent tags
- Run `git log --oneline -10` to review recent commits
- Infer the next version based on changes since last tag:
  - Breaking changes → bump **major**
  - New features / commands → bump **minor**
  - Fixes / docs only → bump **patch**
- Show the inferred version and ask: **"Tag as vX.Y.Z? (yes / edit)"**

---

## Step 2 — Verify clean state

```bash
git status -sb
git branch --show-current
```

- If there are uncommitted changes: warn and ask **"You have uncommitted changes — commit first or proceed anyway? (commit first / proceed / abort)"**
- If not on `main` or the designated release branch: warn **"You are on branch <name>, not main — tag here anyway? (yes / abort)"**

---

## Step 3 — Update CHANGELOG.md

```bash
cat CHANGELOG.md 2>/dev/null | head -10 || echo "NO_CHANGELOG"
```

Check if the top entry already matches the target version:
- **Already has this version**: show it and ask **"CHANGELOG already has [vX.Y.Z] — looks good? (yes / edit / skip)"**
- **Missing or outdated**: collect commits since last tag:
  ```bash
  git log $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD --oneline
  ```
  Draft a changelog entry using Keep a Changelog format, then ask: **"Add this entry to CHANGELOG.md? (yes / edit / skip)"**

If writing a new entry, insert it at the top (below the header, above existing entries). Use today's date.

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

```
RELEASED
────────
Tag:    vX.Y.Z
Commit: <hash>
Remote: https://github.com/user/repo

Next steps:
  gh release create vX.Y.Z --generate-notes   # optional GitHub release
  /plugin marketplace update <plugin-name>     # if this is a Claude Code plugin
```

If the repo has a `.claude-plugin/` directory, remind the user to also bump `version` in `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `.codex-plugin/plugin.json` if not already done.
