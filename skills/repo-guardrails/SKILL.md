---
name: repo-guardrails
description: >
  Guard a named Git/GitHub operation against material repository policy; audit
  repository posture; propose exact changes from selected findings; or apply an
  explicitly approved set of named proposal item IDs. Covers branch protection,
  reviews, checks, secret scanning, push protection, environments, scoped-secret
  metadata, and security automation. Not for executing Git operations, generic
  configuration requests without selected findings, cleanup, documentation, or
  ambiguous workstream selection.
metadata:
  version: "0.1.0"
---

# repo-guardrails

Target: portable Agent Skill, intentionally model-invoked so policy requests and
operation guards route here instead of expanding `git-ops`.

Treat profiles as defaults and findings as evidence, not scores. Repository-local
instructions and explicit overrides outrank the profile. `git-ops` still owns
operation validation/execution; this skill owns policy posture.

## Select one mode

| Mode | Trigger | Output | Mutation |
|---|---|---|---|
| `guard` | A named Git/GitHub operation needs only material policy facts. | Compact applicable findings and handoff. | None. |
| `audit` | User asks for posture, public/team readiness, gaps, or policy review. | Complete applicable findings by category. | None. |
| `propose` | User wants a concrete improvement plan or selected findings converted to changes. | Exact changes, trade-offs, dependencies, authority, verification. | None. |
| `apply` | User explicitly approves named proposal items. | Per-item applied/blocked/unknown result plus read-after-write proof. | Approved subset only. |

Completion: exactly one mode is selected; `apply` additionally names every
approved item before any write.

## Establish authority and profile

1. Read repository instructions, adopted policy/config, forge/provider, default
   branch, visibility, collaborators/deployments when observable, and explicit
   owner statements. Use no network for a local-only guard.
2. Choose the closest default from
   [references/profiles.md](references/profiles.md): `SOLO`, `TEAM`, or
   `PRODUCTION`. Add context flags such as `PUBLIC`, `PRIVATE`, or `RELEASED`
   without inventing another profile.
3. Apply repository-local overrides last. A direct local rule wins; conflicting
   or incomplete authority becomes `UNKNOWN`, not an averaged compromise.

Completion: the result names profile, evidence for choosing it, applicable
overrides, unresolved conflicts, and which provider facts are unavailable.

The finite v1 control surface is
[references/controls.md](references/controls.md). Load it for every mode; it is
the source of stable IDs, applicability, category, and owning skill.

## Run the selected mode

- For `guard`, read [references/guard.md](references/guard.md) and inspect only
  controls capable of changing the named operation.
- For `audit` or `propose`, read [references/audit.md](references/audit.md); load
  GitHub categories only when GitHub is the observed/configured forge.
- For `apply`, read [references/apply.md](references/apply.md) before any effect.

Every finding uses `STATE` as its overall disposition; `EVIDENCE` remains purely
observational and `DESIRED` carries the normative profile/override posture:

```text
CONTROL=<stable control id>
STATE=ENFORCED|REQUIRED|RECOMMENDED|NOT_APPLICABLE|UNKNOWN
EVIDENCE=<observed fact and source>
DESIRED=<profile/override posture>
OWNER=<repo-guardrails|git-ops|specialist|human/provider>
AUTHORITY=<already requested|approval required|unavailable>
VERIFY=<read-after-write or local postcondition>
```

Completion: every applicable control has exactly one state and owner; evidence
and desired posture are distinct; UNKNOWN names the missing fact.

## Return proportionally

`guard` returns only blockers/material recommendations and one `git-ops` handoff.
`audit` returns all applicable findings grouped by category. `propose` returns
stable proposal item IDs. `apply` returns one result for every approved ID:
`APPLIED`, `ALREADY_SATISFIED`, `BLOCKED`, or `UNKNOWN`.

Use one left-border box inside a fenced `text` block (`┌─`, `│`, `└─`; no right
border or markdown inside). Keep it factual and put rationale after it.
Completion: the result can be resumed without reinterpreting
which controls, proposal items, or effects were selected.

## Boundaries

- Missing or unauthenticated `gh` yields local findings plus provider `UNKNOWN`;
  it does not turn the repository into a failed audit.
- A recommendation never authorizes application. Batch the selected proposal
  IDs into one concrete authorization request.
- Read-after-write verification decides success. A successful API exit without
  matching observed state is `UNKNOWN` or `BLOCKED`, never `APPLIED`.
- Provider timeouts after writes require a read before retry.
- Secret values are never requested or printed. Environment-secret proposals
  name secret identifiers and scope; credential entry remains owner-performed.

Maintainers use [evals/triggers.md](evals/triggers.md) and
[evals/behavior.md](evals/behavior.md) without exposing
[evals/oracle.md](evals/oracle.md) to the evaluator. The attributable paired run
is retained in [evals/results.md](evals/results.md). Runtime operations load none
of these files.
