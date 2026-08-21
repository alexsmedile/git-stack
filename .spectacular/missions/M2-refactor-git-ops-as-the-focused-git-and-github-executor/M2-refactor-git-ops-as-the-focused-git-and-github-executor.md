---
type: Mission
id: 01a025c7-56c0-7cc7-85f2-175e16225ef3
title: Refactor git-ops as the focused Git and GitHub executor
status: active
created: "2026-08-21T19:26:17Z"
updated: "2026-08-21T19:36:13Z"
activation:
    at: "2026-08-21T19:26:17Z"
    by: Alex
    fingerprint: sha256:c3c1117441c782738f8eae12058cecffd3719ace546830392527c7716f41f0a3
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
    branch: feat/git-ops-executor
    commit: cc538880838a3ff2981a34701bed87252f90be81
completion:
    - claim: executor-boundary
      pass_boundary: '`git-ops` owns operation-local choice, validation, execution, and verification for Git core and GitHub operations while universal workstream selection, repository policy auditing, and specialist outcomes remain routed to their owners without duplicated enforcement.'
      proof_requirement: Cold routing fixtures cover direct commit, branch and worktree creation, rebase, merge, PR, tag, release, ambiguous new work, policy configuration, hygiene, documentation, and recovery; each loads only the operation or specialist context required and identifies one owner for every check.
    - claim: proportional-operation-contracts
      pass_boundary: Commit, push, branch, worktree, rebase, merge, PR, tag, and release paths each define required input state, decision-changing checks, authority boundary, execution choice, failure recovery, and an observable done condition without narrating basic Git knowledge.
      proof_requirement: A table-driven operation matrix and dominant, risky, and near-miss prompt fixtures demonstrate the exact validation depth, approval behavior, recovery route, and completion evidence for every supported operation family.
    - claim: earned-mechanics-and-compatibility
      pass_boundary: Existing fast paths and distribution behavior remain compatible; scripts are retained or extended only for compact repeated facts or costly exact invariants, and direct native Git remains valid when no helper improves speed, precision, or safety.
      proof_requirement: Existing script, manifest, synchronization, distribution, commit, push, tag, and release checks pass; representative scratch repositories exercise changed mechanics and compare compact helper output with direct Git fallback behavior.
    - claim: reviewed-executor-skill
      pass_boundary: The patched `git-ops` package is progressively disclosed, contains no material duplication or no-op Git tutorial prose, preserves relevant pre-existing user edits, and has no unresolved Skill Forge or independent-review blocker.
      proof_requirement: Skill Forge portable validation passes, a fresh-context full review returns pass with a right-sized verdict after at most one scoped repair verification, and independent FROST review verifies the committed tree and all three behavioral claim families.
contract:
    fingerprint: sha256:802030ebc7ab61f13e3d9d35076ebc71938bf88d9158c9368ba17bb9880d631b
    ref: Contract:01a02533-1526-7162-8bc1-ce702b45ef40
dependencies:
    - M1 completed with independent review and owner acceptance.
gaps: []
objectives:
    - claims:
        - executor-boundary
        - reviewed-executor-skill
      id: 01a025c7-56c0-7773-87fb-6e79fb86e89d
      outcome: Recover the existing executor architecture, preserve pre-existing user edits, and freeze one ownership and routing matrix across repo-governance, git-ops, repo-guardrails, and specialist skills.
      ref: O1
      status: implemented
    - claims:
        - executor-boundary
        - proportional-operation-contracts
      id: 01a025c7-56c0-7c5b-9366-1c46757bf3ac
      outcome: Refactor git-ops procedures and progressive references into explicit operation contracts with proportional judgment, authority, recovery, and completion behavior.
      ref: O2
      status: implemented
    - claims:
        - earned-mechanics-and-compatibility
      id: 01a025c7-56c0-7df8-bd18-8019ea336966
      outcome: Retain, remove, or extend deterministic helpers according to measured value and validate compatibility across canonical and generated distributions.
      ref: O3
      status: implemented
    - claims:
        - executor-boundary
        - proportional-operation-contracts
        - earned-mechanics-and-compatibility
        - reviewed-executor-skill
      id: 01a025c7-56c0-7b9d-aeca-31ce16f084c8
      outcome: Run focused fixtures, Skill Forge gates, full repository verification, and independent review; repair only scoped failures and leave the repo-guardrails mission ready.
      ref: O4
      status: pending
outcome: '`git-ops` accepts a repository-governance decision or a direct unambiguous operation, applies only operation-specific judgment and proportional validation, executes through native Git or earned deterministic helpers, and returns a verified result or a precise recovery handoff.'
owner: Alex
ref: M2
repair_budget: 2
review: independent
run:
    current_objective: O1
    id: 01a025c7-56c0-72d0-b413-a8ec9b2d1d72
    operator: Alex
    ref: R1
    repairs: 0
    started_at: "2026-08-21T19:26:17Z"
    status: active
scope:
    mechanical:
        - .spectacular/
        - .skill-forge/git-ops.md
        - skills/git-ops/
        - src/scripts/ and synchronized generated copies only when an earned mechanic changes
        - focused git-ops fixtures and repository validation records
    semantic:
        - The executor input and return contract between repo-governance and git-ops.
        - Operation-specific judgment, validation, execution, recovery handoff, and completion evidence for Git core and GitHub v1.
        - Progressive disclosure and removal of duplicated governance or generic Git narration.
        - Preservation and integration of the existing uncommitted git-ops report-format work without absorbing unrelated dirty files.
start_key: sha256:2a5fb4c10d7a61eab2c5eb316e7d51621164baacb32d54fa17ca4140bdcb17ec
stops:
    - The refactor requires changing the accepted repo-governance ownership boundary or implementing repo-guardrails inside M2.
    - An existing user edit must be overwritten rather than preserved or deliberately reconciled.
    - A helper proposal merely wraps ordinary Git without demonstrated speed, precision, or safety value.
    - Compatibility requires a public rename, installation, synchronization, push, merge, or release.
validation:
    mode: cli
    schema: mission.v2
---
# Origin and rationale

M1 established the universal governance kernel and its boundary with the focused executor. This Mission closes the next Campaign block: make `git-ops` a compact operation specialist rather than a second universal policy layer or Git tutorial. Existing user edits to the report format are treated as input and preserved where they remain coherent.

# Execution plan

## O1 — Executor contract

- Read the whole `git-ops` package and every disclosed reference.
- Map every check and route to exactly one owner.
- Record the Skill Forge Update/extend architecture and regression surface.

## O2 — Operation procedures

- Refactor the top-level skill and references around operation contracts.
- Keep native model judgment primary and make validation proportional to risk.
- Route ambiguous work back to governance, policy work to guardrails, specialist outcomes to specialists, and surprising state to recovery.

## O3 — Earned mechanics

- Exercise existing fast paths and identify only repeated or fragile mechanics worth retaining or changing.
- Edit canonical scripts first and synchronize generated copies when a change is earned.

## O4 — Verification

- Add focused operation and routing fixtures.
- Run Skill Forge mechanical validation, representative script tests, synchronization, manifests, and distribution checks.
- Run fresh-context Skill Forge review and independent FROST review within the repair budget.
- Leave the `repo-guardrails` entry contract ready for M3 without implementing it here.

# Execution mode

Autopilot through reversible in-scope work and local commits. Owner gates and stop conditions remain active.

# Review instructions

Reviewers must reject duplicated universal governance, generic Git-command narration, unconditional heavy preflight, scripts without an earned advantage, or loss of existing fast-path compatibility. They must inspect the exact committed tree and primary fixture evidence.
