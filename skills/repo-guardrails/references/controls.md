# Canonical v1 control catalog

Use this when: any mode must select, audit, propose, apply, or verify stable
controls. This finite catalog defines v1 completeness.

| ID | Category | Control | Applies when | Owner |
|---|---|---|---|---|
| LOCAL-IGNORE | local | sensitive/generated paths excluded | repository has local files | repo-guardrails |
| LOCAL-HOOKS | local | adopted required local gates present | local policy declares them | repo-guardrails |
| LOCAL-SIGN | local | signing/provenance policy | adopted policy or supply-chain posture requires it | git-ops enforcement; guardrails posture |
| BR-DIRECT | branch | default direct writes restricted | shared/production default branch | repo-guardrails |
| BR-FORCE | branch | force-push/deletion restricted | protected/shared/release branch | repo-guardrails |
| PR-REVIEWS | integration | approvals/code ownership | TEAM/PRODUCTION or override | repo-guardrails |
| PR-CHECKS | integration | required checks exist/pass | CI exists and posture requires | guardrails posture; git-ops check |
| PR-CONVERSATION | integration | conversation resolution | provider/policy supports | repo-guardrails |
| PR-MERGE | integration | merge strategies match history policy | PR integration used | repo-guardrails |
| SEC-SCAN | security | secret scanning enabled | provider supports | repo-guardrails |
| SEC-PUSH | security | secret push protection enabled | provider supports | repo-guardrails |
| SEC-DEPS | security | dependency automation owned | manifests/provider support exist | repo-guardrails |
| SEC-CODE | security | code scanning and triage owner | codebase/profile requires | repo-guardrails |
| ENV-SCOPE | delivery | environments separate stages | repository deploys | repo-guardrails |
| ENV-REVIEW | delivery | sensitive environment reviewers | sensitive/production deploy exists | repo-guardrails |
| ENV-SECRETS | delivery | secret identifiers environment-scoped | deployments use provider secrets | owner enters values; guardrails verifies metadata |
| REL-TAGS | release | release branch/tag policy explicit | versions published | guardrails posture; git-ops enforcement |
| REL-CI | release | release CI/provenance | repository publishes/deploys | guardrails posture; git-ops check |
| COL-OWNERS | collaboration | ownership/reviewer mapping | TEAM/PRODUCTION or override | repo-guardrails |

`guard` selects only IDs capable of changing the named operation. `audit` emits
one finding per catalog ID: applicable disposition or `NOT_APPLICABLE` with
reason; unobservable applicable IDs become `UNKNOWN`. Proposal item IDs remain
separate because several ordered changes may satisfy one control.
