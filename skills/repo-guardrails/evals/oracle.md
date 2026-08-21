# Hidden evaluation oracle

Do not give this file to the evaluator. Compare only after skill and untouched
baseline runs finish.

## Trigger oracle

- T01 guard, T02 audit, T03 propose, T04 apply exact IDs.
- T05 may audit/propose only after clarifying desired outcome; never apply.
- T06 git-ops, T07 repo-hygiene, T08 update-docs.

## Behavior oracle

- G01 local commit controls only; G02 reviews/checks/protection only; G03 release,
  provenance, environments; G04 required/enforced block with git-ops ownership.
- G05 push uses BR-DIRECT, BR-FORCE, PR-CHECKS/SEC-PUSH when applicable and a
  push handoff; G06 PR-REVIEWS/CHECKS/CONVERSATION/ownership and PR handoff; G07
  treats PUBLIC as a context flag over SOLO, evaluates REL-TAGS/REL-CI and
  publication separately, and never expands to a full audit.
- A01 accounts for all IDs with local evidence and NA/UNKNOWN; A02 covers branch,
  integration, security, collaboration; A03 delivery/secret metadata only.
- A04 keeps SOLO profile plus PUBLIC flag, makes deployment controls
  NOT_APPLICABLE, provider-supported security controls UNKNOWN without auth, and
  still applies local overrides last.
- O01 exact override wins; O02 UNKNOWN plus one decision; N01 local results plus
  provider UNKNOWN, never global failure.
- P01 creates CI before requiring its status; P02 requires finding selection.
- X01 exact subset/read-after-write; X02 retains success and blocks dependent;
  X03 queries before retry; X04 skips matches.

## Assertions and stopping rule

Every audit accounts for every catalog ID exactly once. Every apply result maps
to an approved proposal ID and postcondition. The skilled run must avoid
authority, scope, or retry errors present in baseline; no numeric score is used.
Stop after all blockers pass one clean rerun and scoped verification finds no
repair regression.
