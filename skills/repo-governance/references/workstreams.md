# Workstreams

Use this when: choosing or resuming the branch, worktree, and history boundary
for new or existing repository work after orientation.

## 1. Find plausible existing work

Start with the current branch, branches checked out in linked worktrees, branches
named by the user or repository records, and known issue/PR/Mission workstreams.
For the intended target paths, compare:

1. working changes in each relevant worktree when observable;
2. files changed by each candidate branch from its actual merge base;
3. issue, PR, Mission, and stated outcome correspondence;
4. branch-name similarity only as a weak final clue.

Never claim that an external session is live unless repository evidence or the
owner says so. A linked worktree proves occupancy and possible concurrency, not
the identity or activity of its operator.

Completion: every plausible candidate is classified `MATCH`, `DISJOINT`, or
`UNKNOWN`, with changed-file overlap recorded before semantic similarity.

## 2. Select branch and worktree independently

| Evidence | Branch decision | Worktree decision |
|---|---|---|
| Current workstream owns the target files and its outcome includes the task | Reuse it | Reuse its tree if no concurrent hands are indicated. |
| Existing workstream overlaps the files but ownership or intent conflicts | Stop for coordination; do not create a competing branch | Preserve both trees; do not switch, stash, or remove. |
| Work is reviewable and disjoint from active work | Create or reuse a focused branch from the repository-approved base | Add a worktree only when the current tree is occupied or concurrent hands need isolation. |
| Current tree is dirty with unrelated work | Select the task's appropriate branch | Use a separate worktree rather than disturbing the dirty tree. |
| Tiny operation belongs to the current established workstream | Reuse current branch | Reuse current tree. |
| Evidence is insufficient to distinguish overlap | Keep current state | Ask one narrow ownership question before choosing isolation. |

A new branch is not a collision remedy when another branch already changes the
same files. Prefer the matching workstream or coordinate the integration point.

Completion: the plan states one branch decision and one worktree decision, each
supported by its own evidence.

## 3. Classify history ownership

| Class | Evidence | Rewrite posture |
|---|---|---|
| `PRIVATE` | No remote publication, PR, dependent branch, other operator, protected role, or declared consumer is observed | Rewriting may be proposed after workspace checks. |
| `PUBLISHED_SOLO` | A remote branch exists and evidence supports one owner with no dependent work | Rewrite only deliberately; operation-specific execution uses lease protection. |
| `SHARED` | Reviewers, contributors, dependent branches, automation, protected/release role, or explicit shared ownership consume the history | Preserve published history; prefer additive correction or coordinated integration. |
| `UNKNOWN` | Required evidence is unavailable or contradictory | Treat as shared only for the operation that depends on ownership. |

Attach independent flags when observed: `PROTECTED`, `DIRTY`, `OCCUPIED`,
`DIVERGED`, `STACK_BASE`, `PR_OPEN`, `RELEASE_BOUND`, `SECRET_EXPOSED`.
Do not create new ownership classes for these conditions.

Completion: the class cites its decisive evidence, every observed flag is named,
and uncertainty identifies the exact operations it blocks.

## 4. Return the plan and authorization boundary

```text
OUTCOME: <intended result>
MATCH: <existing workstream | NONE | UNKNOWN>
OVERLAP: <files or NONE | UNKNOWN>
BRANCH: <reuse/create/coordinate + ref and base>
WORKTREE: <reuse/create/preserve + path or placement rule>
CLASS: <PRIVATE | PUBLISHED_SOLO | SHARED | UNKNOWN>
RISK: <flags or NONE>
ROUTE: <git-ops | recover | specialist>
APPROVAL: <NOT_NEEDED | REQUIRED: exact effect>
NEXT: <one safe action>
```

Routine work already requested may continue to `git-ops`. Before switching or
creating a branch/worktree, stashing, discarding state, changing remotes,
rewriting history, force-pushing, or publishing an ambiguous integration, ask:

```text
Observed: <facts>.
Proposed: <exact effect and target>.
Risk/recovery: <principal risk and recovery point>.
Authorize me to proceed? (Y/N)
```

An explicit user request for that same effect is authorization; do not ask twice.
"Fix this file" authorizes the edit, not an unstated branch/worktree creation;
"create a branch and worktree for this fix" authorizes both boundaries.
After authorization, hand the exact operation to `git-ops` rather than restating
its command procedure.

`PROTECTED` or `RELEASE_BOUND` history routes additive work to `git-ops`; route
to `repo-guardrails` only when the request is to inspect or change the policy
itself. Under `UNKNOWN`, continue a disjoint non-destructive task only inside an
already-authorized boundary; ask before creating new isolation for it.

Completion: one plan accounts for branch, worktree, history, risks, route, and
approval; `NEXT` preserves all observed work if execution stops here.
