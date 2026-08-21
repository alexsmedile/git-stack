# Recover

Use this when: orientation finds unexpected, contradictory, interrupted, lost,
or potentially destructive repository state.

Recovery v1 diagnoses and stops. It does not reset, stash, abort, rewrite,
force, delete, or remove a worktree. Once the state and intended repair are
known and authorized, `git-ops` owns execution. Guided `/undo` is later scope.

## 1. Preserve and classify

Begin with the complete [orient.md](orient.md) result. Preserve the current
working tree and collect only read-only evidence needed for one class:

| Class | Typical evidence to establish |
|---|---|
| `INTERRUPTED_OPERATION` | Merge, rebase, cherry-pick, revert, or bisect metadata; conflicts; current HEAD. |
| `UNEXPECTED_DIRTY_STATE` | Staged, unstaged, and untracked paths; expected owner or workstream; target collision. |
| `DIVERGED_HISTORY` | Local/remote refs already available, merge base, ahead/behind, shared-history classification. |
| `OCCUPIED_TARGET` | Worktree holding the branch, its path, visible dirty state, and whether removal would affect work. |
| `MISSING_REF_OR_WORKTREE` | Refs, worktree registrations, and repository records that should name the missing target. |
| `SUSPECTED_LOST_HISTORY` | Reflog entries and unreachable/dangling object evidence needed to identify a candidate recovery point. |
| `SECRET_EXPOSURE` | Whether the secret is only local or reached a remote; affected paths/commits without printing the value. |
| `UNKNOWN` | Evidence needed for another class is unavailable or contradictory. |

Do not fetch, contact GitHub, or inspect remote policy unless local evidence
cannot answer whether published consumers change the safe repair.

Completion: exactly one primary class is selected, secondary risks are flags,
and the evidence collection has not changed refs, index, files, or worktrees.

## 2. Establish containment and recovery point

State what must remain untouched, the last verified good ref or filesystem state
when observable, and the smallest additional fact needed to choose a repair.
For a suspected secret, redact the value and prioritize revocation/rotation when
remote exposure is possible.

If no safe recovery point can be established, stop with `ROUTE: owner` rather
than offering a speculative destructive command.

Completion: the report names protected state, a verified recovery point or
`UNKNOWN`, and the consequence of proceeding without it.

## 3. Return the diagnostic stop

```text
OUTCOME: preserve work and recover <expected state>
CLASS: <recovery class>
FACTS: <read-only evidence>
PROTECT: <files/refs/worktrees that must not change>
RECOVERY_POINT: <ref/path/state | UNKNOWN>
RISK: <flags and affected consumers>
REPAIR: <candidate operation category | NEEDS_MORE_EVIDENCE>
APPROVAL: REQUIRED: <exact repair effect> | NOT_READY
ROUTE: <git-ops | owner | security response>
NEXT: <one safe diagnostic or authorized execution action>
```

Rerunning recovery is safe: repeat orientation, compare facts with the prior
report, and replace stale conclusions. Never infer that unchanged output proves
another process is inactive.

Completion: every field is populated, normal execution remains stopped, and the
next step either gathers one missing fact or hands one exact authorized repair to
its owner.
