---
name: repo-governance
description: Route every agent-handled Git or GitHub request through repository-aware judgment: fast-route a clear atomic operation, orient unfamiliar or dirty state, select or resume a branch/worktree, prevent existing-file and concurrent-work collisions, classify history before rewriting it, or stop for recovery. Use before Git/GitHub work, including commit, push, branch, worktree, merge, rebase, PR, release, repository policy, and recovery requests. Do not use for non-repository file work or when a human is deliberately running Git without agent help.
metadata:
  version: "0.2.0"
  status: draft
  category: devtools
  target: portable-agent-skill
  invocation: model-invoked
---

# Repo Governance

Choose what repository work should happen and where it belongs before an
operation changes files, history, collaboration state, or provider settings.
This is a portable, model-invoked front door because the agent must reach it for
every Git/GitHub request. `git-ops` retains operation-specific judgment and
execution; this skill does not teach or wrap ordinary Git.

## 1. Frame the request

Identify the intended outcome, named operation, target paths or refs, and effects
the user already authorized. Before creating or replacing a path, establish
whether it exists and whether it contains tracked, modified, or untracked work.
A request for the task outcome does not authorize an unstated branch, worktree,
stash, rewrite, or provider effect.

Completion: the intended outcome, relevant targets, and already-authorized
effects are explicit; an existing target is never silently treated as absent.

## 2. Run the quick guard

Use local, read-only evidence only:

- confirm the repository root and applicable repository instructions;
- establish the current branch and whether the working tree is clean;
- inspect linked worktrees when branch choice, checkout, or concurrent work can
  affect the request;
- note any interrupted Git operation or surprising state visible locally.

Collect no remote facts unless the chosen route needs GitHub collaboration or
policy state. When bundled scripts are available, resolve this skill's directory
and run `bash scripts/git-stack.sh state`, adding `--path <target>` for each
explicit target. It reports facts, never a route. When the helper is unavailable
or direct inspection is cheaper, inspect Git directly; absence of an optimization
is not a blocker.

Completion: every fact capable of changing the immediate route is known or
marked `UNKNOWN` with its consequence; no mutation has occurred.

## 3. Choose one route

| Condition | Route | Load or hand off |
|---|---|---|
| Target and atomic operation are clear; quick guard exposes no decision-changing ambiguity | `execute` | Hand off to `git-ops` for its focused validation and execution. |
| New work needs a home, existing work may match, or branch/worktree/history ownership is unclear | `plan-work` | Read [orient.md](references/orient.md), then [workstreams.md](references/workstreams.md). |
| State is unexpected, contradictory, damaged, or a normal action could lose work | `recover` | Read [orient.md](references/orient.md), then [recover.md](references/recover.md). |
| Request concerns repository protections, CI policy, environments, secrets posture, or enforcement | `guardrails` | Route to `repo-guardrails` when available; otherwise state the missing specialist and use `git-ops` only for checks it already supports. |
| Request concerns cleanup, documentation, release, or README presentation | `specialist` | Route to `repo-hygiene`, `update-docs`, `git-ops`, or `repo-prettifier`. |

Load only the selected route. Re-run the quick guard if the target, ownership,
working tree, or requested effect changes.

Completion: exactly one route is selected with the fact that selected it and
the next owning skill or reference.

## 4. Return or continue

For a routine operation already requested by the user where `APPROVAL: NOT_NEEDED`
and `ROUTE: execute`, continue immediately and silently to `git-ops` without
emitting the full governance diagnostic block, presenting only the focused
`git-ops` result upon completion.

When halting for user approval, entering `recover`, planning non-trivial workstreams,
or delegating across subagent/process boundaries, emit the full structured result:

```text
OUTCOME: <intended repository result>
FACTS: <root; authority; branch/status; upstream if relevant; worktrees if relevant>
CLASS: <history ownership or NOT_NEEDED>
RISK: <flags or NONE>
ROUTE: <execute | plan-work | recover | guardrails | specialist>
DECISION: <why this route and boundary fit>
APPROVAL: <NOT_NEEDED | REQUIRED: exact effect>
NEXT: <one safe action>
```

Before an unrequested structural, destructive, provider, or shared-history
effect, halt and return one authorization question containing:

1. observed facts;
2. proposed effect and exact target;
3. principal risk and recovery point;
4. a yes/no request to proceed.

Completion: every field is present when structured output is required, facts are
separated from judgment, and `NEXT` is executable by the named owner without
rediscovering the decision.

## Invariants

- Repository-local authority outranks generic conventions.
- Changed-file overlap is stronger workstream evidence than branch-name or issue
  similarity.
- A branch separates history and review; a worktree separates concurrent hands
  and filesystem state. Assess both.
- Unknown ownership blocks only operations whose safety depends on ownership;
  unrelated non-destructive work may continue.
- Scripts earn inclusion only when they make repeated work quicker, more precise,
  or materially safer than direct model use.

Maintainers validate routing and trigger changes against
[evals/prompts.md](evals/prompts.md) before review.
