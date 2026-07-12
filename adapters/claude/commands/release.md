---
description: Prepare, commit, push, and tag a release with script-backed gates.
version: 2.1.0
allowed-tools: Bash, Read, Edit, AskUserQuestion
argument-hint: "[version] (e.g. 1.2.0 — omit to infer)"
---

# /release

Run inline; do not delegate the routine release path.

1. Resolve `VERSION` from `$ARGUMENTS` (strip `v`). If absent, inspect only the
   latest tag and commit subjects. Infer semver; ask once only if ambiguous.
2. Require a clean tree on the default branch:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/git-stack.sh" tag --version "$VERSION"
   ```
3. Promote `[Unreleased]` in `CHANGELOG.md`, or draft a concise dated entry from
   commits since the last tag.
4. Bump and audit manifests:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/bump-manifests.sh" "$VERSION" --dry-run
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/bump-manifests.sh" "$VERSION"
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/check-manifests.sh"
   ```
   Re-run the bumper once on drift; stop if the audit still fails.
5. Validate cross-harness packaging before any release write:
   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/validate-distribution.mjs" --native
   ```
   Stop if any static or available native validator fails.
6. Stage only the changelog and changed manifests. Commit and push through the
   script using `chore: release v$VERSION`. If default-branch policy blocks the
   release commit, ask once for the explicit `--allow-main` override.
7. Re-run the tag check, then create and push the annotated tag:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/git-ops/scripts/git-stack.sh" tag \
     --version "$VERSION" --execute
   ```
8. Report version, commit, tag, remote, manifest count, validator results, and
   the platform-specific refresh actions from `docs/DISTRIBUTION.md`.

Read `skills/git-ops/references/workflows.md` only for ambiguous versioning,
release-branch, CI, or GitHub Release decisions.
