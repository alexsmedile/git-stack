# git-stack / decisions — Situational Decision Guide

Use this file when you need to figure out what to do, not how to do it.
The reference files (core.md, github.md, workflows.md) cover the how.
This file is the when and why.

---

## Primary decision tree

Start here. Match your situation to an action.

```
Am I starting or resuming work on a project?
  → git pull first. Always. Don't skip.

Am I about to make a change?
  → Am I on main/master?
      Yes → Stop. Create a branch first.
      No  → Continue on the current branch.

Have I completed a logical unit of work?
  → Does it stand on its own? Can I describe it in one sentence?
      Yes → git commit
      No  → Keep going. Don't commit half-finished work.

Am I ready to share or back this up?
  → git push

Do I want to know if remote has changed, without touching my files?
  → git fetch

Do I want to apply remote changes to my local work?
  → git pull (aware: may cause conflicts if I've also edited locally)

Have I finished a branch and want it in main?
  → Open a PR on GitHub (preferred) or git merge locally.

Is my branch behind main and I want it caught up?
  → git rebase origin/main
  → Only if this branch hasn't been shared with others.

Do I need to pause mid-task without committing?
  → git stash (named, temporary — not long-term storage)

Do I need two branches active simultaneously?
  → git worktree

Am I confused about the current state?
  → git status first, then git log --oneline -10, then git diff
```

---

## Command → risk table

Before running any command, know its risk profile:

| Command | Reversible? | Risk | Notes |
|---------|-------------|------|-------|
| `git status` | N/A | None | Read-only. Always safe. |
| `git log` | N/A | None | Read-only. Always safe. |
| `git diff` | N/A | None | Read-only. Always safe. |
| `git add` | Yes | None | Stage only — nothing permanent yet |
| `git commit` | Yes (locally) | Low | Undo with `reset --soft HEAD~1` |
| `git stash` | Yes | Low | Applied back with `stash pop` |
| `git push` | Hard | Medium | Remote now has your history. Use PRs to manage. |
| `git pull` | Harder | Medium | Merges remote into local. Conflicts possible. |
| `git merge` | Hard | Medium | Creates merge commit. Abort with `--abort`. |
| `git rebase` | Hard | Medium-High | Rewrites history. Abort with `--abort`. Shared branch → High. |
| `git reset --hard` | Very hard | High | Discards uncommitted work permanently. |
| `git push --force` | Very hard | High | Overwrites remote history. Others lose their base. |
| `git push --force-with-lease` | Hard | Medium-High | Safer than --force. Fails if remote has moved. |
| `git branch -D` | Hard | Medium | Force-deletes branch; recoverable via reflog. |
| `git clean -fd` | Very hard | High | Deletes untracked files permanently. |

**Before any High-risk command:**
- Communicate if others could be affected
- Have a rollback plan
- Consider creating a backup branch: `git branch backup/before-rebase`

---

## Fetch vs pull — when to use which

**Use `fetch` when:**
- You want to see what's changed before deciding what to do
- You're in the middle of something and don't want an unexpected merge
- You want to compare your branch to the remote before rebasing

**Use `pull` when:**
- You're starting a fresh work session
- You're certain you want to integrate remote changes now
- You have no uncommitted local changes (cleaner pull)

**The pattern that avoids surprises:**
```bash
git fetch origin
git log HEAD..origin/main --oneline   # see what would come in
git rebase origin/main                # or git merge, your choice
```

---

## Merge vs rebase — when to use which

This is the most common judgment call in daily Git work.

**Use merge when:**
- The branch has been shared with others (pushed to remote, others pulled)
- You want to preserve the exact history (who did what, when)
- You're on a team and want visible integration points
- Working on `main` or a long-lived shared branch

**Use rebase when:**
- The branch is personal and local (or you're the only one using it)
- You want a clean, linear history before opening a PR
- Your branch has drifted far from main and you want it caught up cleanly
- You're squashing messy WIP commits before sharing

**The rule in one line:**
> Rebase before sharing; merge after sharing.

---

## Stash vs branch — when to use which

Both let you "set aside" current work and switch context. They're for different situations.

**Use stash when:**
- You need to switch contexts urgently and will come back soon (minutes to hours)
- The work is too rough for a commit (genuinely mid-sentence)
- It's genuinely temporary

**Create a WIP branch instead when:**
- You might not come back for days
- You want the work to be visible on GitHub
- You want a commit message to remember what you were doing

```bash
# WIP branch approach (more durable than stash)
git switch -c wip/auth-experiment
git add -A
git commit -m "WIP: mid-refactor on auth service"
git push origin wip/auth-experiment
```

---

## Task type → workflow mapping

When given a task, map it to the right workflow first:

| Task type | Signs | Workflow to use |
|-----------|-------|-----------------|
| New feature | "add X", "build Y", "implement Z" | `workflow.feature` |
| Bug fix | "fix X", "broken Y", "error Z" | `workflow.bugfix` |
| Code improvement | "clean up", "refactor", "simplify" | `workflow.refactor` |
| Version release | "ship v1.x", "release", "publish" | `workflow.release` |
| Production emergency | "down", "urgent", "hotfix" | `workflow.hotfix` |
| New project setup | "start", "scaffold", "create repo" | `github.repo-setup` |
| Conflict resolution | "conflicts", "merge failed" | `core.merge` |

---

## Common situation → action guide

**"I'm about to start working on the project"**
→ `git pull origin main` first. Then branch.

**"I need to fix something urgent while mid-feature"**
→ `git stash push -m "WIP: feature X"` → fix on a new branch → come back → `git stash pop`

**"My PR has been approved, how do I merge?"**
→ `gh pr merge --squash --delete-branch` (squash keeps history clean on main)

**"I accidentally committed to main"**
→ Create a branch from current state, reset main to before your commit:
```bash
git branch feat/accidental-main-commit     # save your work
git reset --soft origin/main               # undo commit on main (keep changes staged)
# Now properly: switch to the branch and proceed
git switch feat/accidental-main-commit
```

**"My push was rejected"**
→ `git pull --rebase origin main` then push again. Don't force push.

**"I have merge conflicts"**
→ Open each conflicted file, look for `<<<<<<` markers, resolve, then:
```bash
git add <resolved-file>
git rebase --continue   # or git merge --continue
```

**"I want to undo my last commit"**
→ `git reset --soft HEAD~1` — removes the commit, keeps your changes staged

**"I deleted a branch by accident"**
→ `git reflog | grep <branch-name>` → `git switch -c <branch-name> <sha>`

**"The repo has secrets that were committed"**
→ This is serious. Rotate the secrets immediately (most important). Then:
  - `git filter-repo` to scrub history (nuclear, rewrites everything)
  - Force push all branches
  - Notify collaborators to re-clone
  - Consider GitHub's secret scanning alerts

**"I want to back up a config file that always contains secrets"** (e.g., `~/.claude/settings.json`, `~/.codex/config.toml`)
→ Use a **git clean filter**: the working tree keeps real values, but the committed blob is redacted automatically. Pattern:

1. Create `scripts/redact-secrets.sh` (a sed pipeline that replaces secret values with `…REDACTED`, preserving the key name and file shape).
2. Mark it executable: `chmod +x scripts/redact-secrets.sh`.
3. Add to `.gitattributes`:
   ```
   path/to/settings.json filter=redact-secrets
   path/to/config.toml   filter=redact-secrets
   ```
4. Register the filter in the repo (not committed — local config):
   ```bash
   git config filter.redact-secrets.clean "./scripts/redact-secrets.sh"
   git config filter.redact-secrets.smudge "cat"
   git config filter.redact-secrets.required true
   ```
5. Re-stage covered files so the filter applies: `git rm --cached <file> && git add <file>`.
6. Verify the committed blob: `git show :path/to/settings.json | head` — should show `…REDACTED`.
7. Add a `pre-commit` hook (`.git/hooks/pre-commit`) as a safety net that greps staged content for the same patterns from `core.md` and blocks commits if anything slips through (catches files not yet listed in `.gitattributes`).

Real-world example: `~/code/utils/dotagents/` uses this exact setup for Claude/Codex/Gemini config backups.

Caveats:
- `.git/hooks/` is not versioned — store the hook script in `scripts/hooks/` and `setup.sh` it on clone.
- Filter `required = true` means clones without the filter script will fail loudly instead of silently committing real secrets. Good.
- Rotate any key that was ever committed before the filter was installed.

---

## Common pitfalls

| Pitfall | Wrong | Correct |
|---------|-------|---------|
| Committing to main | `git commit` on main | Branch first, PR to merge |
| Force push to shared branch | `git push --force` | `git push --force-with-lease` |
| Giant commits | 500-line single commit | Atomic commits per logical change |
| Stale branch | Long-lived feature branch | Rebase onto main frequently |
| Missing `.gitignore` | Committing `node_modules/`, `.env` | Set up `.gitignore` before first commit |
| Whitespace conflicts | Mixing tabs/spaces | `.editorconfig` + consistent tooling |

---

## Repo health checklist

Use this when auditing or setting up a project:

- [ ] Every branch except main is short-lived and has a clear purpose
- [ ] `main` has branch protection (require PR, require CI)
- [ ] `.gitignore` covers: node_modules, dist, .env, build output, IDE files
- [ ] `.env.example` exists with all required variable names (values empty)
- [ ] `README.md` explains: what, why, how to run, how to test
- [ ] Commits follow Conventional Commits format
- [ ] No large binary files in history
- [ ] No secrets in history (check with `git log -p | grep -i "api_key\|password\|secret"`)
- [ ] CI is configured and green on main
- [ ] At least one human has reviewed every PR to main
