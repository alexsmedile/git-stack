---
type: Anchor
id: 01a0252d-092a-7130-baa3-549757ae3dfc
human_ref: ARCHITECTURE
title: Git Operator Architecture
updated: "2026-08-21T16:42:00Z"
direction: Separate universal repository judgment, operation-specific execution, policy governance, specialist outcomes, and deterministic mechanics.
boundaries:
  - "`repo-governance` owns universal routing, progressive orientation, workstream selection, history classification, and recovery stops."
  - "`git-ops` owns operation-local judgment, exact safety validation, and Git/GitHub execution."
  - "`repo-guardrails` owns `guard`, `audit`, `propose`, and explicitly authorized `apply` modes."
  - "`repo-hygiene`, `update-docs`, and `repo-prettifier` own maintenance, documentation, and presentation respectively."
  - "`src/scripts/` owns deterministic facts and invariants shared by installed skill copies."
constraints:
  - Every Git request may enter governance, but only ambiguity or risk earns deep orientation.
  - The quick preflight must be cheaper than the work it prevents or accelerates.
  - Operation-specific enforcement remains in `git-ops`; governance does not duplicate it.
  - Filesystem collision, changed-file overlap, worktree occupancy, history ownership, and repository authority are distinct signals.
  - Unknown ownership blocks dependent history rewrites, not unrelated non-destructive work.
  - Provider mutations and destructive or shared-history operations require explicit authorization.
---

# Architecture

## Runtime flow

```text
Git or GitHub request
    -> repo-governance quick preflight
        -> obvious and safe: git-ops fast lane
        -> ambiguous or risky: progressive orientation and decision
        -> policy or hosting: repo-guardrails
        -> specialist outcome: specialist skill
        -> surprising state: diagnostic recovery stop
```

Routing is required to keep the universal entry point cheap. A single monolithic
skill would load commit, recovery, collaboration, release, documentation,
cleanup, presentation, and GitHub policy guidance for every request. The router
instead establishes the minimum shared facts, then loads only the branch whose
workflow, permissions, output, and validation differ.

`repo-governance` answers what work should happen, where it belongs, and what
authority it needs. `git-ops` answers how the selected Git or GitHub operation is
performed and validated. Specialists own outcomes whose context and checks are
materially different.

The model may use native Git directly when no bundle-specific mechanism improves
the result. Scripts exist for repeated evidence collection, compact reporting,
and high-value enforcement—not to replace capable model reasoning.

## Governance evidence

Progressive orientation considers, only as needed:

- applicable repository instructions and adopted policies;
- whether a target path already exists before writing or overwriting it;
- current staged, unstaged, and untracked changes;
- linked worktrees and whether a required branch is already held;
- changed-file overlap with plausible active branches before creating a new one;
- upstream, divergence, PR, reviewer, dependency, protection, and release state;
- concurrent operators or project records when the repository exposes them.

Changed-file overlap is stronger evidence of a matching workstream than similar
branch names, issue numbers, or tidy conceptual separation.

## History ownership

Governance starts with four classifications:

| Class | Meaning | Rewrite posture |
|---|---|---|
| `PRIVATE` | No observed external consumer | Rewrite after checking workspace state. |
| `PUBLISHED_SOLO` | A remote branch exists, with evidence of one owner and no dependent work | Rewrite deliberately with lease protection. |
| `SHARED` | Other people, automation, branches, reviews, or releases consume the history | Preserve history; prefer additive correction. |
| `UNKNOWN` | Evidence is incomplete or contradictory | Treat as shared for operations that depend on ownership. |

Orthogonal flags such as `PROTECTED`, `DIRTY`, `OCCUPIED`, `DIVERGED`,
`STACK_BASE`, `PR_OPEN`, `RELEASE_BOUND`, and `SECRET_EXPOSED` refine the
decision without multiplying ownership classes.

## Guardrail model

Repository profiles provide defaults for `SOLO`, `TEAM`, and `PRODUCTION`
contexts. Repository-local authority may refine those defaults. Findings use:

```text
ENFORCED
REQUIRED
RECOMMENDED
NOT_APPLICABLE
UNKNOWN
```

The quick `guard` mode reports only material findings for the requested
operation. `audit` inspects the full posture, `propose` names exact changes and
trade-offs, and `apply` performs only the approved subset.

## Approval boundary

Routine requested operations continue when their focused checks pass. Governance
stops for a concrete decision before changing branch or worktree boundaries,
stashing or discarding state, rewriting or force-pushing history, modifying
remotes, publishing ambiguous integration, or changing repository and GitHub
guardrails.
