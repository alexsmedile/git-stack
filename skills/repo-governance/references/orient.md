# Orient

Use this when: new or resumed work needs a repository home, or recovery needs a
verified local baseline before diagnosis.

Orient is read-only and network-free. It establishes only evidence capable of
changing the workstream or recovery decision.

## Procedure

1. **Resolve the repository and intent.** Establish the repository root, intended
   outcome, named target paths, and expected branch or workstream when supplied.
   If the path is not in a Git worktree, return `ROUTE: specialist` or ask for the
   intended repository; do not manufacture Git state.

2. **Resolve applicable authority.** Use repository instructions already supplied
   by the host, then inspect relevant root-to-target anchors such as `AGENTS.md`,
   contributor guidance, and workflow or release documentation when they can
   change this decision. Record missing or unreadable authority as `UNKNOWN`; do
   not replace explicit local policy with a generic convention.

3. **Protect target paths.** For every intended create, replace, move, or delete,
   determine whether the path exists, whether Git tracks it, and whether it has
   working changes. An existing path becomes evidence for update/merge/stop, not
   permission to overwrite.

4. **Collect local Git facts.** Establish current branch or detached state,
   staged/unstaged/untracked state, upstream presence and local ahead/behind when
   available without fetching, linked worktrees, and visible interrupted
   merge/rebase/cherry-pick/revert/bisect state. Do not fetch merely to orient.

5. **Decide what deeper evidence is earned.** Workstream planning proceeds to
   [workstreams.md](workstreams.md). Surprising or unsafe state proceeds to
   [recover.md](recover.md). Remote PR, protection, or CI facts are collected only
   after the route establishes that they can change the answer.

## Orient result

```text
OUTCOME: <requested result>
ROOT: <absolute repository root | NOT_A_REPOSITORY>
AUTHORITY: <files/rules used | NONE_FOUND | UNKNOWN: reason>
TARGETS: <path: absent|tracked|modified|untracked|unknown>
BRANCH: <name | DETACHED | UNKNOWN>
STATUS: <clean | staged=N unstaged=N untracked=N | UNKNOWN>
UPSTREAM: <ref and local ahead/behind | NONE | NOT_NEEDED | UNKNOWN>
WORKTREES: <relevant branch/path/dirty evidence | ONE_CURRENT | NOT_NEEDED | UNKNOWN>
INTERRUPTED: <operation | NONE | UNKNOWN>
NEXT_ROUTE: <plan-work | recover | execute | specialist>
```

Mark unavailable facts explicitly and state which decision they prevent. Re-run
the procedure safely whenever the repository, targets, or working state changes;
it performs no mutation and creates no persistent record.

Completion: every result field is populated, every target path is accounted for,
and `NEXT_ROUTE` follows from cited evidence rather than an assumed clean state.
