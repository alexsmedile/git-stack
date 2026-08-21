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

## Integration and stacked work

Identify dependency order and each intended base. Validate each diff against its
immediate base. Rewrite only history whose ownership permits it. Do not advance a
stacked child until the parent's replacement commit is known. Done: every branch
targets the intended base, review diffs remain meaningful, and the integration
gate passes without dropping either side.

## Session wrap-up

Preserve requested work and report residual state; wrap-up does not imply release.
Push only when the user asked to publish/back up. Report commit/ref, remote state,
remaining changes, blocked checks, and one next action.
