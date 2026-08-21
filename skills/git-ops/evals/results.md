# Git Ops cold evaluation results

Evaluator: `/root/m2_cold_eval`, fresh context, read-only, did not implement M2. Input: `evals/prompts.md` plus runtime skill descriptions/files selected per prompt. Date: 2026-08-21.

| ID | Route/owner | Files loaded after entry | Authority/recovery/done evidence | Verdict |
|---|---|---|---|---|
| T01 | git-ops commit | SKILL, operations | commit only; exact paths/residual; remote untouched | PASS |
| T02 | repo-governance plan | governance SKILL, orient, workstreams | no branch/write; overlap-based matching plan | PASS |
| T03 | planned repo-guardrails | governance SKILL; git-ops SKILL/github to confirm boundary | no setting mutation; specialist absent in M2 | FAIL |
| T04 | repo-hygiene | hygiene SKILL | read first; exact deletion gate; preserve protected/unsynced | PASS |
| T05 | update-docs | update-docs SKILL | edit changelog only; no Git publication | PASS |
| T06 | repo-prettifier | prettifier SKILL | positioning/rewrite contract | PASS |
| T07 | governance recovery | governance SKILL, orient, recover | preserve rebase; diagnose before commit resumes | PASS |
| C01 | git-ops commit | SKILL, operations | commit approved staged set; verify residual | PASS |
| C02 | git-ops commit | SKILL, operations; core conditional | preserve `.env`; secret block; no commit | PASS |
| P01 | git-ops push | SKILL, operations | freshness; remote ref equals local | PASS |
| P02 | git-ops push | SKILL, operations | existing commit only; HEAD/index unchanged; staged residual | PASS |
| B01 | git-ops branch | SKILL, operations | exact base/ref; tree intact | PASS |
| B02 | governance plan | governance SKILL, orient, workstreams | overlapping workstream; no competing branch | PASS |
| W01 | git-ops worktree | SKILL, operations | occupancy/path; mapping exists; source intact | PASS |
| W02 | git-ops worktree | SKILL, operations | inspect held branch; no force/removal | PASS |
| R01 | git-ops rebase | SKILL, operations | fetch; PRIVATE rewrite; checks/no marker | PASS |
| R02 | governance + git-ops | governance SKILL/workstreams; git-ops SKILL/operations | SHARED/STACK_BASE; no rebase | PASS |
| M01 | git-ops merge | SKILL, operations | feature-side resolution; checks; main unchanged | PASS |
| M02 | git-ops → recovery | SKILL, operations; recover conditional | no main resolution; preserve/abort safely | PASS |
| PR01 | git-ops PR | SKILL, operations, github | auth/diff/base/checks; URL/draft postcondition | PASS |
| PR02 | git-ops PR merge | SKILL, github | protection/review wins; remains unmerged | PASS |
| G01 | git-ops tag | SKILL, operations | local annotated tag; remote absent | PASS |
| G02 | git-ops tag | SKILL, operations | wrong branch/provider publication blocked | PASS |
| L01 | git-ops + update-docs | SKILL, operations, github, workflows; update-docs | separately verified release effects | PASS |
| L02 | git-ops release | SKILL, operations, github, workflows | drift/CI blocks commit, tag, release | PASS |
| X01 | git-ops provider recovery | SKILL, github | query after ambiguous write; no duplicate retry | PASS |

## Coverage and ownership

Dominant plus risky/near-miss coverage passed for commit, push, branch, worktree,
rebase, merge, PR, tag, and release. Provider recovery passed X01. No duplicated
check or unrelated runtime file was found. Ownership was distinct: governance
owns workstream/history/recovery; git-ops owns focused execution/postconditions;
hygiene, docs, and presentation own their specialist outcomes.

The evaluator returned overall `FAIL` solely because T03's named owner,
`repo-guardrails`, is intentionally not implemented until M3. It found the route
and confirmed git-ops does not invent policy, but required an executable
specialist contract. M2 retains this as a campaign-boundary limitation rather
than misreporting it as passing runtime policy execution.

## Baseline contrast

The risky cases encode the failures unskilled direct execution can infer:
competing branch creation, committing staged residual work during push, rewriting
shared history, resolving on main, publishing a tag implicitly, bypassing release
gates, or retrying a provider mutation after an ambiguous timeout. The evaluated
skill routes or blocks each of those behaviors; T03 defers to M3.
