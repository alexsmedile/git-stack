---
type: Mission
id: 01a025df-14e0-7113-ac9a-3526005b8f5b
title: Introduce fast repository guardrails for Git and GitHub
status: active
created: "2026-08-21T19:50:32Z"
updated: "2026-08-21T20:17:42Z"
activation:
    at: "2026-08-21T19:50:32Z"
    by: Alex
    fingerprint: sha256:3ad3627fd6cdc72e88aefff9c3c5bce625aaca154912ee32a7eaaaacef8f6faa
authority:
    operator:
        - inspect
        - edit-in-scope
        - choose-reversible-implementation
        - run-checks
        - generate-derived-files
        - bounded-repair
        - commit-local
    requires_owner:
        - change-outcome-or-completion
        - expand-scope
        - push
        - merge
        - release
        - irreversible-change
        - destructive-data
        - secret-change
baseline:
    branch: feat/repo-guardrails
    commit: 566476916141a209565b73fe2e3d61517d42d5df
completion:
    - claim: quick-operation-guard
      pass_boundary: '`guard` evaluates only material controls for the selected Git/GitHub operation, begins from repository-local authority and a SOLO, TEAM, or PRODUCTION profile, applies local overrides, returns compact ENFORCED, REQUIRED, RECOMMENDED, NOT_APPLICABLE, or UNKNOWN findings, and routes operation enforcement to `git-ops` without duplicating it.'
      proof_requirement: Cold prompt fixtures for commit, push, rebase, PR, merge, tag, and release demonstrate bounded context loading, exact finding states, profile/override precedence, and a token-light result with no full audit when the focused operation is clear.
    - claim: progressive-policy-modes
      pass_boundary: '`audit` inventories the applicable local and GitHub posture, `propose` converts selected findings into exact reversible changes and trade-offs, and `apply` executes only an explicitly approved subset with read-after-write verification and partial-failure recovery.'
      proof_requirement: Paired dominant and risky fixtures cover local-only audit, unauthenticated GitHub fallback, team and production profiles, branch/ruleset protection, reviews/checks, secret scanning/push protection, environments/scoped secrets, dependency/security automation, approval batching, provider timeout, partial application, and idempotent rerun.
    - claim: profile-and-override-governance
      pass_boundary: Profiles provide defaults rather than universal mandates; repository instructions and explicit local overrides outrank them, conflicts remain UNKNOWN or require one decision, and every finding cites observed evidence, desired posture, owner, authority, and verification method.
      proof_requirement: Table-driven profile/override cases demonstrate precedence and NOT_APPLICABLE behavior across solo, team, public, and production repositories without treating missing GitHub access as policy failure.
    - claim: reviewed-guardrails-package
      pass_boundary: The portable model-invoked skill is progressively disclosed, scripts exist only for compact deterministic evidence or fragile exact effects, GitHub is the first provider implementation without obscuring Git core portability, and no Skill Forge or independent-review blocker remains.
      proof_requirement: Portable Skill Forge validation, representative helper fixtures if a helper is earned, synchronization/manifests/distribution gates, fresh-context full review with scoped verification as needed, and independent FROST review pass on the committed tree.
contract:
    fingerprint: sha256:802030ebc7ab61f13e3d9d35076ebc71938bf88d9158c9368ba17bb9880d631b
    ref: Contract:01a02533-1526-7162-8bc1-ce702b45ef40
dependencies:
    - M1 completed the governance kernel.
    - M2 completed the focused executor and retained a failing T03 fixture that names repo-guardrails as the missing policy owner.
gaps: []
objectives:
    - claims:
        - quick-operation-guard
        - profile-and-override-governance
        - reviewed-guardrails-package
      id: 01a025df-14e0-7678-8602-f88885907294
      outcome: Freeze the guardrail finding schema, profile/override precedence, mode boundaries, ownership matrix, authority model, and smallest package plan.
      ref: O1
      status: implemented
    - claims:
        - quick-operation-guard
        - progressive-policy-modes
        - profile-and-override-governance
      id: 01a025df-14e0-749b-acc1-79eb6739aa18
      outcome: Implement guard, audit, propose, and apply as progressively disclosed procedures with Git-core portability and GitHub v1 policy coverage.
      ref: O2
      status: implemented
    - claims:
        - quick-operation-guard
        - progressive-policy-modes
        - reviewed-guardrails-package
      id: 01a025df-14e0-76b1-979c-25fd1baf9db2
      outcome: Add only earned compact mechanics, focused fixtures, and explicit read-after-write verification for fragile policy effects.
      ref: O3
      status: implemented
    - claims:
        - quick-operation-guard
        - progressive-policy-modes
        - profile-and-override-governance
        - reviewed-guardrails-package
      id: 01a025df-14e0-7157-8587-de6f120990de
      outcome: Run Skill Forge and repository gates, repair scoped findings, retain evidence, and complete independent review.
      ref: O4
      status: implemented
outcome: '`repo-guardrails` provides a cheap operation guard and progressively deeper audit, proposal, and explicitly authorized application modes using repository profiles, local overrides, compact findings, and exact Git/GitHub verification.'
owner: Alex
ref: M3
repair_budget: 2
review: independent
reviews:
    - file: reviews/RV1-independent-frost-repair-review-of-m3.md
      id: 01a025df-ff40-74e2-ad88-af5819ae4509
      ref: RV1
      verdict: pass
run:
    current_objective: O1
    id: 01a025df-14e0-7366-a9c2-80cf087e8dc1
    operator: Alex
    ref: R1
    repairs: 0
    started_at: "2026-08-21T19:50:32Z"
    status: active
scope:
    mechanical:
        - .spectacular/
        - .skill-forge/repo-guardrails.md
        - skills/repo-guardrails/
        - src/scripts/ and synchronized generated copies only when an earned guardrail mechanic changes
        - focused guardrail fixtures and validation evidence
        - distribution manifests only when adding the new skill requires them
    semantic:
        - Quick focused guard behavior and the ENFORCED, REQUIRED, RECOMMENDED, NOT_APPLICABLE, UNKNOWN finding model.
        - SOLO, TEAM, and PRODUCTION defaults with repository-local instructions and overrides taking precedence.
        - Audit, propose, and explicitly approved apply modes for Git core and GitHub v1.
        - Boundaries with repo-governance, git-ops, repo-hygiene, update-docs, and repo-prettifier.
start_key: sha256:68f53c0e4c1972ed40f0235df74f6bdeb5e7729afbd197e71dc529e0f4340b09
stops:
    - Quick guard becomes a full repository audit or duplicates git-ops operation validation.
    - A profile becomes a universal policy that overrides repository-local authority.
    - Apply cannot separate approved findings or verify partial provider effects safely.
    - A proposed helper merely wraps model-readable Git or GitHub output without measurable speed, precision, or safety value.
    - Completion requires installation, push, merge, release, secrets, or live policy mutation outside disposable fixtures.
validation:
    mode: cli
    schema: mission.v2
---
# Origin and rationale

M1 established universal governance and M2 established focused execution. M2's cold evaluation found the remaining ownerless route: repository and GitHub policy. This Mission introduces that specialist without turning ordinary commits into heavyweight audits.

# Execution plan

## O1 — Contract and architecture

Map guard/audit/propose/apply inputs, permissions, outputs, verification, failure recovery, and resume behavior. Define profiles as defaults, overrides as repository authority, and findings as actionable evidence rather than a score.

## O2 — Progressive procedures

Implement the quick local guard first. Disclose full audit categories, proposal construction, and approved application only when selected. Cover Git core generically and GitHub as the first provider.

## O3 — Earned mechanics and fixtures

Prefer direct `git`/`gh` inspection until repeated parsing or fragile provider writes earn a helper. Add paired dominant/risky cases, including missing auth, provider timeout, partial application, and safe rerun.

## O4 — Verification

Run portable validation, repository distribution gates, fresh-context Skill Forge review, and independent FROST review. Retain primary evidence and repair only within the frozen budget.

# Execution mode

Autopilot through reversible local work and commits. No live repository-policy mutation is authorized; apply mode is specified and tested with dry/read-only or disposable fixtures only.

# Review instructions

Reject a full audit on every Git request, universal policy disguised as profiles, duplicated git-ops enforcement, opaque scoring, provider mutation without explicit per-finding authority, or helpers that add ceremony without deterministic value.
