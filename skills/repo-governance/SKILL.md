---
name: repo-governance
description: Route agent-handled Git or GitHub requests through repository-aware judgment before anything changes. Use for any Git or GitHub work — commit, push, branch, worktree, stash, merge, rebase, PR, tag, release, repository policy, or recovery — including plain "commit this" and "push" requests, dirty or unfamiliar repos, and any request that would rewrite history (rebase, amend, reset, force-push). Selects the right workstream, prevents file collisions and concurrent-work conflicts, classifies history ownership, and stops safely on surprising state. Do not use for non-repository file work, general programming tasks unrelated to version control, or read-only questions about Git concepts.
metadata:
  version: "0.3.0"
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
explicit target. It reports facts, never a route. Decision-relevant fields:
`STASHES` counts saved-but-unapplied work that a reset or checkout could strand;
`TARGET_<n>_OVERLAP` names local branches carrying unmerged commits that touch
each target — changed-file overlap, the strongest workstream evidence. When the
helper is unavailable
or direct inspection is cheaper, inspect Git directly; absence of an optimization
is not a blocker.

Completion: every fact capable of changing the immediate route is known or
marked `UNKNOWN` with its consequence; no mutation has occurred.

## 3. Choose one route

Check the fast map first; fall through to the full table only when no row matches.

| Situation | Route |
|---|---|
| Plain commit/push request; staged or disjoint work; clean or understood state | `execute` (silent fast lane) |
| Dirty tree with unrelated work, target path already modified elsewhere, or `TARGET_<n>_OVERLAP` is non-`NONE` | `plan-work` |
| Any rewrite requested (rebase/amend/reset/force-push) and history ownership not yet classified | `plan-work` — classify first |
| Merge/rebase/cherry-pick/bisect in progress, diverged history, or work that looks lost | `recover` |
| Branch protection, CI policy, environments, secrets posture, enforcement | `guardrails` |
| Cleanup, documentation, release notes, README presentation | `specialist` |

| Condition | Route | Load or hand off |
|---|---|---|
| Target and atomic operation are clear; quick guard exposes no decision-changing ambiguity | `execute` | Hand off to `git-ops` for its focused validation and execution. |
| New work needs a home, existing work may match, or branch/worktree/history ownership is unclear | `plan-work` | Read [orient.md](references/orient.md), then [workstreams.md](references/workstreams.md). |
| State is unexpected, contradictory, damaged, or a normal action could lose work | `recover` | Read [orient.md](references/orient.md), then [recover.md](references/recover.md). |
| Request concerns repository protections, CI policy, environments, secrets posture, or enforcement | `guardrails` | Route to `repo-guardrails` when available; otherwise state the missing specialist and use `git-ops` only for checks it already supports. |
| Request concerns cleanup, documentation, release, or README presentation | `specialist` | Route to `repo-hygiene`, `update-docs`, `git-ops`, or `repo-prettifier`. |

Load only the selected route. Re-run the quick guard if the target, ownership,
working tree, or requested effect changes.

The `ROUTE` value is exactly one of: `execute | plan-work | recover |
guardrails | specialist`. This is the only route vocabulary in the bundle;
references and reports reuse these values and never invent routes. When no
route can proceed safely, stop after reporting — do not name a new route.

Handoff mechanism: skills share one model context; "hand off" means continuing
under the named skill's procedure, loading its SKILL.md by name through the
host's skill system (`git-ops`, `repo-guardrails`, `repo-hygiene`,
`update-docs`, `repo-prettifier`). If the host cannot load a sibling skill,
proceed with native Git/GitHub and apply this bundle's safety rules inline.
A missing specialist never blocks routine work.

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
