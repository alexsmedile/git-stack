# Identity and secret recovery

Use this when: an operation reports an author-identity, secret, clean-filter, or
hook blocker. Ordinary Git operations do not load it.

## Identity

Use the user's verified GitHub noreply alias when attribution/privacy requires
it. Accept an existing `@users.noreply.github.com` address; never construct the
account-specific alias. The commit/push runner calls `check-author-email.sh`.
Use `--staged`, `--range`, or `--all` only for focused diagnosis. Fix future
identity with scoped `git config`; existing-history repair needs authorization.

## Secret response

The commit runner owns staged added-lines scanning and uses `gitleaks` when
available. A finding blocks until removed, made fixture-safe, or allowlisted by
exact fingerprint after confirming it is not real.

If a real secret entered remote/shared history: rotate or revoke first, establish
affected refs/consumers, choose additive removal or a coordinated authorized
rewrite, then verify refs and notify collaborators when SHAs changed. Deleting a
working-tree value does not unpublish it.

For a requested full audit, prefer `gitleaks detect --redact -v`. Otherwise
source `scripts/secret-patterns.sh` and scan tracked files, relevant config, and
`git log --all -p`. Networked credential verification is deliberate, not routine.

## Clean filters and hooks

For intentionally secret-bearing versioned files, use a repository-owned clean
filter plus `.gitattributes`, set it required, re-stage, and verify the index blob.
Prefer generated config or a secret manager unless this is established policy.

When explicitly asked for commit protection, run `scripts/install-hooks.sh
<repo>` as a preview. Apply only the approved copy/symlink method and never
overwrite an existing hook.
