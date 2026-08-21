# Quick operation guard

Use this when: a named operation needs a cheap policy decision before `git-ops`.

1. Start from the governance result and selected operation. Do not repeat its
   workstream, history, or collision analysis.
2. Read local instructions/config first. Query cached/local facts. Use GitHub
   only when the operation depends on live provider policy and auth is available.
3. Select controls from the table; inspect no unrelated category.
4. Return only `ENFORCED`/`REQUIRED` controls that affect execution,
   `RECOMMENDED` controls material to this operation, and `UNKNOWN` facts whose
   absence changes safety.

| Operation | Material controls |
|---|---|
| commit | protected/default direct-write policy, required local hooks/scans, signing/identity override |
| push | protected branch/ruleset, force-push, required checks before publish, push protection |
| rebase/history rewrite | protected/shared-history policy, force-push/ruleset, dependent automation |
| PR open/ready | target ruleset, required checks/reviews, conversation resolution, ownership requirements |
| PR merge | approvals, required checks, merge strategy, conversation resolution, deployment gate |
| tag/release | release branch/tag policy, CI/provenance, environment/deployment approvals, secret scope |

Completion: every returned control can change the named operation, missing
provider access is explicit, and the handoff states `PROCEED`, `BLOCKED`, or
`PROCEED_WITH_WARNING` plus the exact `git-ops` operation.

On tool failure, retain collected local evidence and mark only dependent provider
controls UNKNOWN. Rerun safely because guard performs no writes.
