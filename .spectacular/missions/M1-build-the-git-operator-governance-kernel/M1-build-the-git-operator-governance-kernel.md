---
type: Mission
id: 019ff873-e260-72c2-a713-484b19508282
title: Build the Git Operator governance kernel
status: active
created: "2026-08-21T16:42:28Z"
updated: "2026-08-21T16:51:08Z"
activation:
    at: "2026-08-21T16:42:28Z"
    by: Alex
    fingerprint: sha256:f4e7f9adf6fcaec2a0d8c2946ea3c3b7fad9f527c4d68e422d158cd9cb0850a4
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
    branch: feat/repo-governance-kernel
    commit: a8bfe1dfcf26abccbf8821e4ef2060803d3705ec
completion:
    - claim: universal-progressive-routing
      pass_boundary: '`repo-governance` is a model-invoked universal entry point for Git and GitHub requests; it fast-routes an unambiguous safe atomic operation to `git-ops` and earns deeper orientation only when observed state or intent can change the decision.'
      proof_requirement: Human-review prompt fixtures cover a staged commit fast path, unfamiliar new work, an occupied or dirty checkout, an unambiguous direct Git operation, a guardrail request, and specialist routing; each produces the expected route without loading unrelated procedures.
    - claim: collision-aware-workstreams
      pass_boundary: Before recommending a new path, branch, or worktree, governance checks applicable local authority, existing target paths, current modifications, linked worktrees, and changed-file overlap with plausible active workstreams; it distinguishes branch history isolation from worktree concurrency isolation.
      proof_requirement: Table-driven prompt fixtures reproduce an attempted overwrite of an existing file, a concurrent session editing overlapping files, a branch held by another worktree, overlapping side work that belongs on an active branch, and genuinely disjoint work that earns separate isolation.
    - claim: history-risk-and-authority
      pass_boundary: Governance classifies history as `PRIVATE`, `PUBLISHED_SOLO`, `SHARED`, or `UNKNOWN`, attaches orthogonal risk flags, continues unrelated non-destructive work under uncertainty, and asks one concrete authorization question before structural, destructive, provider, or shared-history effects.
      proof_requirement: Review fixtures assert classification, risk flags, allowed continuation, and approval behavior for local work, pushed solo work, open PRs, dependent branches, protected or release-bound branches, occupied worktrees, divergence, and incomplete evidence.
    - claim: executable-recovery-and-review
      pass_boundary: The orient, workstream, and recover references are executable procedures with ordered inputs, compact outputs, failure recovery, safe resume behavior, and checkable completion criteria; every previously recorded Skill Forge blocker is resolved and verified without turning the skill into a Git tutorial or command wrapper.
      proof_requirement: Skill Forge structural validation passes, three dominant/risky/near-miss prompt tests exist, and an issue-scoped fresh-context verifier closes `RG-INVOCATION-POLICY`, `RG-ROUTE-CONTRADICTION`, `RG-ORIENT-IS-PROMISSORY`, `RG-WORKSTREAM-IS-PROMISSORY`, `RG-RECOVERY-IS-PROMISSORY`, `RG-APPROVAL-UNSPECIFIED`, and `RG-COMPLETION-TOO-WEAK` with no original blocker remaining.
contract:
    fingerprint: sha256:802030ebc7ab61f13e3d9d35076ebc71938bf88d9158c9368ba17bb9880d631b
    ref: Contract:01a02533-1526-7162-8bc1-ce702b45ef40
dependencies: []
gaps: []
objectives:
    - claims:
        - universal-progressive-routing
        - collision-aware-workstreams
      file: objectives/O1-freeze-the-minimum-preflight-evidence-routing-result-authority-order-failure-model-and-script-versus-model-inclusion-rule.md
      id: 019ff873-e260-7ade-a9a0-f849c113c993
      outcome: Freeze the minimum preflight evidence, routing result, authority order, failure model, and script-versus-model inclusion rule.
      ref: O1
      status: implemented
    - after:
        - O1
      claims:
        - collision-aware-workstreams
        - history-risk-and-authority
        - executable-recovery-and-review
      file: objectives/O2-implement-executable-orientation-workstream-selection-history-classification-approval-and-diagnostic-recovery-procedures.md
      id: 019ff873-e260-77ff-97b4-5003d22f0dac
      outcome: Implement executable orientation, workstream selection, history classification, approval, and diagnostic recovery procedures.
      ref: O2
      status: implemented
    - after:
        - O2
      claims:
        - universal-progressive-routing
        - executable-recovery-and-review
      file: objectives/O3-add-only-mechanical-support-that-proves-quicker-more-precise-or-safer-than-direct-model-use-preserving-the-canonical-src-scripts-synchronization-contract.md
      id: 019ff873-e260-7c70-a39c-cc8ee4d5e8d4
      outcome: Add only mechanical support that proves quicker, more precise, or safer than direct model use, preserving the canonical `src/scripts/` synchronization contract.
      ref: O3
      status: implemented
    - file: objectives/O4-run-focused-fixtures-mechanical-checks-and-the-pending-issue-scoped-independent-verification-repair-only-scoped-failures-and-leave-the-next-campaign-blocks-ready.md
      id: 019ff873-e260-74bc-a647-14b943133483
      ref: O4
outcome: Every Git and GitHub request enters a cheap repository-aware decision path, while ambiguous or risky work receives evidence-based workstream, history, approval, and recovery judgment before mutation.
owner: Alex
ref: M1
repair_budget: 2
review: independent
run:
    current_objective: O1
    id: 019ff873-e260-7b5d-8636-d61672caae89
    operator: Alex
    ref: R1
    repairs: 1
    started_at: "2026-08-21T16:42:28Z"
    status: active
scope:
    mechanical:
        - .spectacular/
        - .skill-forge/repo-governance.md
        - skills/repo-governance/
        - src/scripts/git-stack.sh
        - src/sync-scripts.mjs
        - focused governance fixtures and generated script copies when earned
    semantic:
        - Universal Git and GitHub request routing through `repo-governance`.
        - Progressive orientation, collision prevention, workstream selection, branch/worktree isolation, history ownership, approval, and diagnostic recovery behavior.
        - Boundary contracts with `git-ops`, future `repo-guardrails`, and existing specialist skills.
        - The rule that models retain Git judgment while scripts exist only for faster, more precise, or safer repeated mechanics.
start_key: sha256:a2446cbcefd561f1f2f91bc9c8673e72eef3a6f3de5e3f66169036cd3c2609db
stops:
    - Universal activation cannot be encoded portably without breaking existing host distribution.
    - The quick preflight becomes materially heavier than direct operation-specific inspection.
    - Concurrency or ownership behavior requires claiming knowledge not exposed by repository evidence or owner statements.
    - A proposed helper merely wraps ordinary Git without measurable speed, precision, or safety value.
    - Existing user changes overlap in a way that cannot be preserved without changing the approved outcome or scope.
validation:
    mode: cli
    schema: mission.v2
---
# Origin and rationale

This Mission comes from the owner-led exploration of Git Stack's evolution toward
Git Operator. Real agent failures included overwriting an existing file without
inspection and editing the same files as a concurrent session without selecting
separate branch and worktree boundaries. Earlier review also found the
`repo-governance` scaffold architecturally sound but too promissory to execute.

A capable model already knows Git. The Mission therefore builds an intervention
layer around decision-changing repository evidence rather than another command
wrapper. Deterministic mechanics are earned only when they reduce repeated work,
increase precision, or prevent costly mistakes.

# Execution plan

## O1 — Decision contract

- Reconcile the accepted exploration decisions with the current scaffold and
  forge record.
- Define the minimum local, network-free quick preflight and its compact result.
- Define routing, authority, completion, and fallback behavior without duplicating
  operation-specific enforcement from `git-ops`.

Checkpoint: present the stable decision contract and whether a shared state helper
earned implementation.

## O2 — Executable governance

- Rewrite `orient.md`, `workstreams.md`, and `recover.md` as ordered procedures.
- Encode existing-path checks, changed-file overlap, worktree occupancy, history
  classification, orthogonal risk flags, mixed continuation, and authorization.
- Keep recovery diagnostic in v1; guided repair remains a later capability.

Checkpoint: present the executable routing and edge-case behavior before mechanics.

## O3 — Earned mechanics

- Implement only stable repeated facts whose direct collection is noisier, slower,
  or more error-prone.
- If earned, extend `src/scripts/git-stack.sh` and synchronize generated copies;
  do not create a competing wrapper or edit generated copies directly.
- Preserve direct read-only fallback when the helper is unavailable.

## O4 — Verification and handoff

- Add dominant, risky, and near-miss prompt fixtures.
- Run Skill Forge mechanical validation and relevant repository gates.
- Dispatch the already-due issue-scoped verifier and repair within budget.
- Record remaining work for the `git-ops` refactor and `repo-guardrails`
  introduction without implementing those Campaign blocks inside M1.

Checkpoint: return verified claim evidence and the next Campaign-block plan.

# Execution mode

Checkpoints at the three named boundaries above. Owner gates and stop conditions
apply throughout.

# Review instructions

The independent reviewer must test the skill as a cold reader, distinguish actual
procedures from promises, and verify that universal routing stays cheap. It should
reject both underbuilt judgment and unnecessary Git-command narration.
