# Repository profiles and overrides

Use this when: a guardrail run must choose default desired posture or reconcile
repository-local overrides.

Profiles minimize repeated judgment; they are not mandates.

Profile rows map to stable IDs in [controls.md](controls.md). The catalog decides
completeness/applicability; this file supplies default desired posture.

| Control family | SOLO default | TEAM default | PRODUCTION default |
|---|---|---|---|
| default-branch direct writes | recommended against | required against | enforced against |
| pull-request review | optional/recommended by risk | required | enforced with named reviewers/owners |
| required CI checks | recommended when CI exists | required | enforced, strict, deployment-relevant |
| force-push/deletion on protected branches | recommended against | required against | enforced against |
| secret scanning/push protection | recommended for public/host-supported | required | enforced |
| dependency/security automation | recommended | required where supported | enforced with triage ownership |
| environments and scoped secrets | not applicable without deployments | recommended by deployment risk | required/enforced per stage |
| deployment approvals | not applicable without deployments | recommended for sensitive stages | enforced for production |
| signed/provenance requirements | optional | recommended/required by policy | required where supply-chain risk warrants |

## Precedence

Apply in this order, later entries winning:

1. observed provider/repository state;
2. inferred profile defaults;
3. adopted repository instructions/configuration;
4. explicit local override or owner decision for this repository.

An override states control ID, desired state, scope, rationale, and source. A
temporary exception also states expiry/exit condition. Conflicting sources at
the same authority remain `UNKNOWN` and produce one decision request.

## NOT_APPLICABLE vs UNKNOWN

Use `NOT_APPLICABLE` when the control has no relevant surface: deployment
approval in a repository with no deployments, for example. Use `UNKNOWN` when
the surface may exist but evidence is unavailable: GitHub protection with no
authentication. Absence of evidence is not evidence of absence.
