---
name: git-ops
description: >
  Execute and validate a selected Git or GitHub operation—commit, push, branch,
  worktree, merge, rebase, pull request, tag, release, or session wrap-up. Use
  after repo-governance selects the workstream, or immediately for a direct
  unambiguous operation. Not for ambiguous work placement, repository policy
  audits, cleanup, documentation, or README presentation.
metadata:
  version: "1.11.0"
---

# git-ops

Execute the requested operation with local judgment. Native `git` and `gh` are
the default; use a bundled helper only for compact repeated evidence or an exact
invariant it enforces more reliably.

## Entry contract

Accept either a governance result naming workstream, branch/worktree boundary,
history class, flags, authority, and next operation; or a direct operation whose
target and repository state are already unambiguous.

Return ambiguous workstream selection to `repo-governance`. Route repository
policy to `repo-guardrails`, cleanup to `repo-hygiene`, documentation to
`update-docs`, and README positioning to `repo-prettifier`. If execution reveals
an interrupted operation, unexpected divergence, occupied worktree, or evidence
contradicting the input, stop and return to governance recovery with the facts.

## Execute proportionally

1. Identify the exact operation, targets, requested effect, and local authority.
   Completion: one operation contract is selected.
2. Read only the decision-changing facts in
   [references/operations.md](references/operations.md), plus
   [references/github.md](references/github.md) for GitHub effects. Completion:
   required facts are known or explicitly `UNKNOWN`.
3. Separate requested effects from newly discovered structural, destructive,
   provider, or shared-history effects. Continue requested routine effects when
   focused checks pass; ask one exact authorization question for the rest.
   Completion: every effect is classified as authorized, denied, or awaiting
   that one approval; execution starts only when none is awaiting.
4. Execute with native Git/GitHub or an earned fast path. On failure, preserve
   state, diagnose read-only, and follow the contract's recovery route.
   Completion: execution succeeds, or preserved state, diagnosis, and the
   selected recovery route are recorded.
5. Verify the observable postcondition—not merely exit code—and emit one compact
   result box. Completion: target state matches the request, or a blocked result
   names the factual cause and one safe next action.

## Earned fast paths

```bash
GIT_STACK="${CLAUDE_SKILL_DIR:-<skill-directory>}/scripts/git-stack.sh"
bash "$GIT_STACK" commit
bash "$GIT_STACK" push
bash "$GIT_STACK" tag --version 1.2.3
bash "$GIT_STACK" scan
```

Exit `0` means clean/done, `1` blocked, and `2` nothing to do. `BLOCKED` reports
every blocker and warning once; `NOTHING_TO_DO` stops; `CLEAN` permits the
explicit `--execute` pass. Never add unapproved paths or infer permission for
`--allow-main`, `--allow-large`, or a force push.

In this source repository, skill scripts are generated from `src/scripts/`.
Edit canonical sources and run `node src/sync-scripts.mjs`; installed standalone
copies may execute their bundled scripts directly.

### Commit

Run `git-stack.sh commit`. On `CLEAN`, use the user's message verbatim or inspect
the staged diff and draft an imperative Conventional Commit subject up to 72
characters. Execute with `commit --execute --message "…"`; verify the commit and
report residual work. Do not push.

### Push

Run `git-stack.sh push`. Staged work is residual state, not commit authority:
push only existing commits and leave the index untouched. Execute
`push --execute`, verify the tracking ref, and report the staged count as
remaining work. Never force-push through this path.

### Tag and release

Preview and execute `tag --version X.Y.Z` only from the verified release branch;
this creates a local annotated tag. Add `--publish-tag` only when remote tag
publication is explicitly authorized.
For a release, read [references/workflows.md](references/workflows.md). Changelog,
manifest bump/audit, distribution validation, commit, tag, and GitHub Release are
one contract but remain separately verifiable effects.

## Report format

Emit one left-border box inside a fenced `text` block. Keep facts under 80
characters, align labels, omit markdown inside the box, and explain afterward.

```text
┌─ COMMITTED · feat/login · 3 files
│ commit   a1b2c3d  feat: add password reset flow
│ files    3 changed, +82 -14
│ warning  1  .env.example is untracked
│ next     push when requested
└─
```

## Hard guardrails

- Preserve shared history. Rewrite only `PRIVATE` or deliberately authorized
  `PUBLISHED_SOLO` history; use lease protection for published rewrites.
- Stage only named/approved paths. The commit runner owns staged secret and
  large-file checks.
- Rotate an exposed secret before history repair.
- Resolve and verify conflicts on the feature/integration branch before
  advancing a protected/default branch.
- Provider authentication gates provider effects, not unrelated local work.
- Installation, hooks, aliases, and repository settings are explicit setup
  effects; preview and apply only when requested.

When an identity, secret, clean-filter, or hook blocker appears, load
[references/core.md](references/core.md) for its focused recovery procedure.

Routine Git execution stays in the current agent. Independent review assesses
the work product; it is not a substitute for running Git.

Maintainers use [evals/prompts.md](evals/prompts.md) for cold routing and
operation-contract checks; [evals/results.md](evals/results.md) retains the
attributable M2 run. Runtime operations load neither file.
