---
name: repo-governance
description: Universal repository governance front door. Evaluates Git/GitHub requests through repository-aware judgment: fast-routes atomic operations, orients dirty/unfamiliar state, selects/resumes workstreams, prevents file & worktree collisions, classifies history before rewrites, or halts for diagnostic recovery.
metadata:
  version: "0.3.0"
  status: current
  category: devtools
  target: portable-agent-skill
  invocation: model-invoked
---

# Repo Governance

Universal entry point for repository judgment before modifying files, history, or remotes.

## 1. Frame & Quick Guard

- **Frame**: Identify outcome, operation, target paths, and explicit user authorizations. Target check: exists $\rightarrow$ inspect tracked/dirty. Never assume absent. Action request $\neq$ unstated branch/worktree/stash/rewrite authorization.
- **Quick Guard**: Read-only local inspection (`bash scripts/git-stack.sh state --path <target>`). Resolves root, branch, clean status, linked worktrees, and `TARGET_OVERLAP` (changed-file overlap across branches). Absence of script degrades to direct git read commands.

## 2. Route Selection

| Situation / Evidence | Route | Action / Reference |
|---|---|---|
| Plain commit/push/merge; staged or disjoint work; clean state | `execute` | Silent fast-lane $\rightarrow$ hand off directly to `git-ops` |
| Dirty tree, target path modified elsewhere, `TARGET_OVERLAP` $\neq$ `NONE`, or unclassified history rewrite | `plan-work` | Read [orient.md](references/orient.md) $\rightarrow$ [workstreams.md](references/workstreams.md) |
| Interrupted op (merge/rebase/cherry-pick), divergence, or suspected lost work | `recover` | Read [orient.md](references/orient.md) $\rightarrow$ [recover.md](references/recover.md) |
| Branch protections, CI policies, environments, secret scanning posture | `guardrails` | Hand off to `repo-guardrails` |
| Cleanup, changelog/doc sync, release packaging, README positioning | `specialist` | Route to `repo-hygiene`, `update-docs`, `git-ops`, or `repo-prettifier` |

## 3. Return or Continue

- **Fast Lane (`ROUTE: execute`, `APPROVAL: NOT_NEEDED`)**: Proceed immediately and silently to `git-ops`. Output only the final `git-ops` execution box.
- **Halt / Delegation**: Emit full structured block when halting for authorization, entering `recover`, or delegating:

```text
OUTCOME: <intended repository result>
FACTS: <root; branch/status; upstream; worktrees; targets>
CLASS: <PRIVATE | PUBLISHED_SOLO | SHARED | UNKNOWN | NOT_NEEDED>
RISK: <flags or NONE>
ROUTE: <execute | plan-work | recover | guardrails | specialist>
DECISION: <why this route and boundary fit>
APPROVAL: <NOT_NEEDED | REQUIRED: exact effect>
NEXT: <one safe action>
```

- **Unrequested Mutation Guard**: Before unrequested structural, destructive, provider, or shared-history changes, halt and prompt: `Observed: <facts> | Proposed: <effect> | Risk/Recovery: <point> | Authorize? (Y/N)`.

## Invariants

- Repository-local authority (`AGENTS.md`, repo configs) outranks generic defaults.
- Changed-file overlap outranks branch-name or issue similarity.
- Branch = history/review boundary; Worktree = concurrent filesystem/hands boundary.
- Unknown ownership blocks only dependent history rewrites; non-destructive work continues.
