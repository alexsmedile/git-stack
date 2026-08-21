# Recover

Use this when: orientation finds unexpected, contradictory, interrupted, lost,
or potentially destructive repository state.

Recovery acts as an actionable flight director: it diagnoses safely, preserves all
uncommitted and recent state, identifies exact recovery points (e.g. reflog hashes),
and presents a concrete 3-part repair proposal for one-click authorization.
Once authorized, `git-ops` executes the repair.

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
| `SUSPECTED_LOST_HISTORY` | Reflog entries (`HEAD@{1}`, `refs/stash`, etc.) and unreachable/dangling object evidence needed to identify a candidate recovery point. |
| `SECRET_EXPOSURE` | Whether the secret is only local or reached a remote; affected paths/commits without printing the value. |
| `UNKNOWN` | Evidence needed for another class is unavailable or contradictory. |

Do not fetch, contact GitHub, or inspect remote policy unless local evidence
cannot answer whether published consumers change the safe repair.

Completion: exactly one primary class is selected, secondary risks are flags,
and the evidence collection has not changed refs, index, files, or worktrees.

## 2. Establish containment and recovery point

State what must remain untouched, the last verified good ref (e.g. `HEAD@{1}`) or filesystem state
when observable, and the smallest additional fact needed to choose a repair.
For a suspected secret, redact the value and prioritize revocation/rotation when
remote exposure is possible.

If no safe recovery point can be established, stop after the diagnostic report
with `APPROVAL: NOT_READY` and no route, rather than offering a speculative
destructive command.

Completion: the report names protected state, a verified recovery point or
`UNKNOWN`, and the consequence of proceeding without it.

## 3. Present the actionable recovery proposal

Structure the recovery stop with full diagnostic clarity and an actionable 3-part repair plan:

```text
OUTCOME: preserve work and recover <expected state>
CLASS: <recovery class>
FACTS: <read-only evidence>
PROTECT: <files/refs/worktrees that must not change>
RECOVERY_POINT: <ref/path/state | UNKNOWN>
RISK: <flags and affected consumers>
PROPOSAL:
  1. DIAGNOSIS: <what happened and what is safely preserved>
  2. RECOMMENDED_PATH: <exact safe action / CLI command (e.g., git rebase --abort, conflict resolution)>
  3. ESCAPE_PATH: <fallback non-destructive alternative (e.g., backup branch or reset to verified ref)>
APPROVAL: REQUIRED: execute <RECOMMENDED_PATH>
ROUTE: <execute | recover | guardrails | specialist>
NEXT: <exact authorized execution action or one clarifying inspection>
```

`ROUTE` uses the vocabulary pinned in SKILL.md. When no safe recovery point can
be established, stop after the report with `APPROVAL: NOT_READY` and no route —
never offer a speculative destructive command.

Prompt the user for authorization:
```text
State: <diagnostic summary>.
Protected: <what is preserved, including recovery ref>.
Recommended: <exact recommended command/repair>.
Escape path: <alternative option>.
Authorize me to execute the recommended path? (Y/N)
```

Rerunning recovery is safe: repeat orientation, compare facts with the prior
report, and replace stale conclusions. Never infer that unchanged output proves
another process is inactive.

Completion: every field is populated, normal execution remains stopped until approved,
and the user is provided an unambiguous, safe path to restore working order.
