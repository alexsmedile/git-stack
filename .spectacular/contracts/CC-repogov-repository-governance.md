---
type: Contract
id: 01a02533-1526-7162-8bc1-ce702b45ef40
ref: CC-repogov
title: Repository governance entry point
status: current
owner: Alex
created: "2026-08-21T16:41:39Z"
updated: "2026-08-21T16:41:39Z"
contract_version: "1"

purpose: Make repository-aware judgment occur before preventable Git, filesystem, concurrency, history, and policy mistakes without wrapping ordinary model capability.
outcome: Every Git and GitHub request reaches a cheap governance decision, safe atomic work continues quickly, and ambiguity or risk earns only the evidence and specialist procedure needed to resolve it.

applies_when:
  - An agent is asked to inspect, plan, modify, integrate, recover, maintain, publish, or configure work in a Git repository or GitHub project.
  - Repository state, existing work, concurrent hands, history ownership, local policy, or provider effects can change the safe action.
does_not_apply_when:
  - A human deliberately runs Git commands without invoking an agent.
  - Work has no Git repository or GitHub consequence and no repository boundary must be selected.
does_not_provide:
  - Basic Git instruction, a wrapper for every command, proof of an unreported external session, or universal branch, commit, PR, and release policy.

required_behavior:
  - Route every agent-handled Git and GitHub request through `repo-governance` while keeping unambiguous safe atomic operations on a cheap path to `git-ops`.
  - Read repository-local authority and observed state before substituting generic conventions.
  - Check whether a target path already exists and whether current or plausible active workstreams modify the intended files before creating or overwriting work.
  - Treat branch choice as a history and review boundary and worktree choice as a concurrent-hands and filesystem boundary.
  - Prefer a verified matching workstream over a competing branch; changed-file overlap is stronger evidence than branch-name or issue similarity.
  - Classify history as `PRIVATE`, `PUBLISHED_SOLO`, `SHARED`, or `UNKNOWN` and keep protection, occupancy, divergence, PR, stack, release, and secret risk as orthogonal flags.
  - Let uncertainty block only operations whose safety depends on the unknown fact; continue unrelated non-destructive work.
  - Ask one concrete authorization question before structural, destructive, provider, or shared-history effects not already explicit in the owner's request.
  - Route surprising or apparently damaged state to read-only diagnosis and a recovery stop before normal execution.
  - Route operation-specific judgment and enforcement to `git-ops`; route guard, audit, proposal, and approved application of policy to `repo-guardrails`; route specialist outcomes to their owning skills.
  - Use scripts only when deterministic facts or enforcement are demonstrably quicker, more precise, or safer than direct model inspection.
  - Keep the quick preflight local, read-only, compact, and network-free; earn remote GitHub inspection from a collaboration or policy question.
  - Fall back to direct read-only Git inspection when an optimization helper is absent instead of blocking ordinary work.

conformance_checks:
  - Prompt fixtures cover safe atomic routing, unfamiliar work, dirty or occupied state, existing-path collision, overlapping and disjoint workstreams, history classes, recovery, guardrails, and specialist routes.
  - Skill procedures have ordered evidence, explicit outputs, failure recovery, safe resume behavior, and checkable completion criteria.
  - Skill Forge mechanical validation passes and the recorded blocking review issues are closed by scoped independent verification.
  - Any new state helper proves a concrete speed, precision, or safety advantage and respects the `src/scripts/` synchronization contract.

gaps: []
---

# Repository governance entry point

This Contract defines the behavioral boundary for the Git Operator judgment
kernel. It deliberately leaves operation-level Git mechanics to `git-ops` and
future repository-policy implementation to `repo-guardrails`.
