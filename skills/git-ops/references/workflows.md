# Multi-operation contracts

Use this when: a release, hotfix, integration, stacked-work, or wrap-up sequence
shares one completion boundary.

## Release

1. Resolve the version and verified release branch; ask once if impact is truly
   ambiguous.
2. Preview `git-stack.sh tag --version X.Y.Z` for cleanliness and tag availability.
3. Route changelog writing to `update-docs`.
4. Preview/apply `bump-manifests.sh`, then run `check-manifests.sh`; the post-write
   audit is the version gate.
5. For plugin bundles, run `validate-distribution.mjs --native` plus the project gate.
6. Stage only release files; commit/push through the focused fast path when the
   requested release includes publication.
7. Recheck and create the local annotated tag. Publish it with `--publish-tag`,
   and create/publish the GitHub Release, only when each provider effect is included.

Done: commit, version sites, tag, requested remote refs, validations, and GitHub
Release agree. Re-run the bumper once on drift; persistent drift blocks release.

## Hotfix

Use the production/release base named by local policy. Preserve the current
feature tree, normally with a separate worktree. Prefer a fast reviewed PR; when
stability demands rollback, revert first and diagnose separately. Done: the
production-bound history contains the verified fix/revert and temporary state is
retained intentionally or safely removed.

## Integration, clean merge, and stacked work

1. **Stack & Base Verification**: Identify dependency order and each intended base.
   Check whether child branches subsume parent commits in stacked series
   (`A -> B -> C`).
2. **Merge Strategy Selection**:
   - *Fast-Forward (`--ff-only`)*: Preferred for linear stacks or rebased feature branches onto `main`.
   - *Merge Commit (`--no-ff`)*: For preserved historical branch boundaries or multi-author features.
   - *Squash Merge*: For noisy single-feature WIP PRs.
3. **Safety Pre-conditions**: Ensure working tree is clean (`git-stack.sh state`),
   upstream is fresh, and all tests/manifests pass before merging.
4. **Post-Merge Verification & Cleanup**:
   - Verify target HEAD contains the source commit(s).
   - Identify newly merged branches (`git branch --merged <target>`).
   - Offer safe local branch cleanup (`git branch -d <branch>`) for fully subsumed branches.
   - Never use `-D` on branch cleanup unless unmerged commit loss is explicitly authorized.

Done: target contains source, tests pass, no merge conflicts remain, and subsumed
branches are safely pruned or reported.

## Session wrap-up

Preserve requested work and report residual state; wrap-up does not imply release.
Push only when the user asked to publish/back up. Report commit/ref, remote state,
remaining changes, blocked checks, and one next action.
