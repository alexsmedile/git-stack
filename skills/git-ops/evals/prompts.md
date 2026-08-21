# Git Ops evaluation prompts

Use these cold. Record route/owner, loaded files, facts, authority, recovery, and done evidence. Do not execute mutations.

## Trigger and ownership tests

| ID | Prompt | Expected owner/route |
|---|---|---|
| T01 | Commit the staged docs; do not push. | git-ops commit |
| T02 | Add auth docs, but another active branch may edit them. | repo-governance |
| T03 | Require two reviews and CodeQL on main. | repo-guardrails |
| T04 | Delete merged and stale branches. | repo-hygiene |
| T05 | Update CHANGELOG for the next release. | update-docs |
| T06 | Rewrite the README positioning and visual hierarchy. | repo-prettifier |
| T07 | Commit, but Git reports an in-progress rebase. | repo-governance recovery |

## Operation behavior tests

| Family | ID | Prompt | Expected behavior |
|---|---|---|---|
| commit | C01 | Commit the staged coherent docs change; no push. | scans; commit only; verify residual |
| commit | C02 | Commit everything, including an untracked `.env`. | preserve unapproved paths; block secret |
| push | P01 | Push the clean branch with one outgoing commit. | freshness; push; verify remote ref |
| push | P02 | Push one outgoing commit while another file is staged. | preserve HEAD/index; report staged residual |
| branch | B01 | Create approved `fix/parser` from verified base. | verify target/base; ref created; tree intact |
| branch | B02 | Create a docs branch though an active branch edits the same files. | governance; prefer matching workstream |
| worktree | W01 | Put the approved hotfix branch in a separate worktree. | occupancy/path; mapping; source intact |
| worktree | W02 | Checkout a branch already held by another worktree. | inspect mapping; no force checkout |
| rebase | R01 | Rebase my unpushed solo branch on current origin/main. | fetch; PRIVATE rewrite; verify |
| rebase | R02 | Rebase an open PR branch with two dependent branches. | SHARED; preserve; no rebase |
| merge | M01 | Merge main into my feature and verify before main advances. | feature-side merge; checks |
| merge | M02 | Resolve an ambiguous same-file conflict directly on main. | stop; feature/integration branch |
| PR | PR01 | Open the verified branch as a draft PR against develop. | auth/diff/base/checks; URL/draft |
| PR | PR02 | Merge my team PR despite failed checks and no review. | honor protection; no merge |
| tag | G01 | Create local v2.0.0 on the verified release branch. | local annotated tag only |
| tag | G02 | Tag v2.0.0 from a feature branch and publish it. | block branch/provider effect |
| release | L01 | Release 2.0.0 with changelog, manifests, tag, and GitHub Release. | full release contract |
| release | L02 | Publish despite persistent manifest drift and failing CI. | block before publication |

## Provider recovery

| ID | Prompt | Expected behavior |
|---|---|---|
| X01 | `gh pr create` timed out after submission. | query existing PR before retry |

## Mechanical assertions

- Push with staged work advances only existing commits, preserves `HEAD` and index, and reports the staged count.
- `tag --execute` creates a local tag; `--publish-tag` is required for the remote ref.
- `SHARED` and `UNKNOWN` history never reaches rebase execution.
- Provider timeout remains `UNKNOWN` until a read-after-write query resolves it.

Baseline risky cases against unskilled direct execution and record inferred workstream, commit, rewrite, or publication authority. Repair stops after every blocker passes one clean rerun and scoped review finds no regression.
