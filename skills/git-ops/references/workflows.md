# git-stack / workflows — Multi-step Sequences

Workflows are the high-level layer. Each one orchestrates several atomic skills
in a safe, opinionated order. Prefer workflows over raw commands — they encode
context, sequencing, and guardrails that individual commands don't carry.

---

## git-stack.workflow.feature

**Purpose:** Ship a new feature from idea to merged PR.

**Steps:**
```
1. Sync with latest main
2. Create a feature branch
3. Implement (with small commits along the way)
4. Rebase onto main if it has moved forward
5. Push and open PR
6. Address review feedback
7. Merge and clean up
```

**Full sequence:**
```bash
# 1. Sync
git switch main
git pull origin main

# 2. Branch
git switch -c feat/my-feature

# 3. Implement → commit in small logical units
git add <files>
git commit -m "feat(scope): describe the change"
# ... repeat for each logical step

# 4. Rebase onto updated main (before PR)
git fetch origin
git rebase origin/main
# Resolve any conflicts, then: git rebase --continue

# 5. Push and open PR
git push -u origin feat/my-feature
gh pr create --title "feat(scope): my feature" --body "Closes #<issue>"

# 6. If review requests changes:
# Make the fix, then:
git add <files>
git commit -m "fix(scope): address review feedback"
git push

# 7. After approval — merge and clean up
gh pr merge --squash --delete-branch
git switch main
git pull origin main
```

**Guardrails:**
- Never skip the rebase step before opening a PR
- Small, clear commits during development (squash on merge is fine)
- Reference the issue number in the PR body

---

## git-stack.workflow.bugfix

**Purpose:** Fix a bug with a clear, safe, traceable path.

**Steps:**
```
1. Understand the bug (reproduce, locate, assess impact)
2. Sync main
3. Create fix branch (naming: fix/<issue-id>-<short-description>)
4. Fix + test
5. Commit with clear message
6. PR with context
```

**Full sequence:**
```bash
# 1. Reproduce first — don't fix blind
# Run the failing test / reproduce the scenario

# 2. Sync
git switch main && git pull origin main

# 3. Branch
git switch -c fix/88-login-token-refresh

# 4. Fix the bug
# ... edit files ...

# 5. Commit
git add <files>
git commit -m "fix(auth): prevent token refresh loop on every request

The expiry check compared timestamps without accounting for clock skew.
Added a 30-second buffer to the comparison.

Closes #88"

# 6. Push and PR
git push -u origin fix/88-login-token-refresh
gh pr create --title "fix(auth): prevent token refresh loop" --body "Closes #88"
```

**Guardrails:**
- Reproduce the bug before writing a fix — fixes without reproduction can miss the root cause
- Write a test that would have caught the bug (if the codebase has tests)
- PR body must explain what the bug was and what the fix does

---

## git-stack.workflow.refactor

**Purpose:** Improve code structure without changing observable behavior.

**Key principle:** Refactor in isolation. Don't mix refactoring with feature
changes in the same PR — it makes review harder and introduces hidden risk.

**Steps:**
```
1. Verify tests pass before you start
2. Sync and branch
3. Refactor in small increments (one thing at a time)
4. Run tests after each step
5. Commit frequently (each refactor step = a commit)
6. PR with clear scope statement
```

**Full sequence:**
```bash
# 1. Baseline: confirm tests pass
npm test  # or equivalent

# 2. Sync and branch
git switch main && git pull origin main
git switch -c refactor/payment-calculation

# 3-4. Refactor incrementally, test as you go
# ... edit ...
npm test
git add <files>
git commit -m "refactor(payment): extract discount calculation to utility"

# ... next step ...
git commit -m "refactor(payment): simplify tax rate lookup"

# 5. Push and PR
git push -u origin refactor/payment-calculation
gh pr create --title "refactor(payment): extract and simplify calculation logic" \
  --body "No behavior changes. Tests pass before and after.

  - Extracted discount calc to \`utils/discount.ts\`
  - Simplified tax rate lookup (was O(n), now O(1))

  Refs #102"
```

**Guardrails:**
- Tests passing before AND after is the contract for "refactor"
- If behavior changes accidentally: stop, commit as a separate fix, then continue
- Keep PR scope tight — one logical refactor per PR

---

## git-stack.workflow.release

**Purpose:** Cut a versioned release and publish it to GitHub.

**Steps:**
```
1. Confirm main is stable (CI green, no pending critical fixes)
2. Decide version number (semver)
3. Update CHANGELOG / release notes
4. Tag the commit
5. Push tag
6. Create GitHub release
7. (Optional) trigger deployment
```

**Full sequence:**
```bash
# 1. Confirm CI is green
gh run list --branch main --limit 3

# 2. Decide version: MAJOR.MINOR.PATCH
# Breaking change → bump MAJOR
# New feature (backwards compat) → bump MINOR
# Bug fix → bump PATCH

# 3. Update CHANGELOG.md (if maintained manually)
# Or use gh release --generate-notes for auto-generated notes

# 4. Commit changelog update
git add CHANGELOG.md
git commit -m "chore(release): prepare v1.2.0 changelog"
git push origin main

# 5. Tag
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0

# 6. GitHub release
gh release create v1.2.0 \
  --title "v1.2.0" \
  --generate-notes        # auto-generates from merged PRs

# For a draft release (review before publishing):
gh release create v1.2.0 --draft --generate-notes
# Then publish when ready:
gh release edit v1.2.0 --draft=false
```

**Guardrails:**
- Never tag on a branch — only tag on main (or your release branch)
- Always verify CI is green on main before tagging
- Use `--generate-notes` unless you maintain a manual changelog — it's reliable

---

## git-stack.workflow.hotfix

**Purpose:** Emergency fix for a production issue — fast but still safe.

**The rule:** Even in emergencies, branch. Never push directly to main.

```bash
# 1. Branch from main (or the current production tag)
git switch main && git pull origin main
git switch -c hotfix/prod-payment-null

# 2. Fix fast, test minimally
# ... fix ...
git add <files>
git commit -m "fix(payment): handle null cart on checkout\n\nFixes production 500 on empty cart. Closes #99"

# 3. PR with urgent label
git push -u origin hotfix/prod-payment-null
gh pr create --title "hotfix: handle null cart on checkout" \
  --label "hotfix" --body "Emergency fix. Closes #99"

# 4. Get at least one quick review, merge fast
gh pr merge --squash --delete-branch

# 5. Tag a patch release immediately
git switch main && git pull origin main
git tag -a v1.2.1 -m "Hotfix: null cart on checkout"
git push origin v1.2.1
gh release create v1.2.1 --generate-notes
```

---

## Workflow selection guide

| Situation | Workflow |
|-----------|----------|
| New feature or capability | `workflow.feature` |
| Reproducible bug to fix | `workflow.bugfix` |
| Code quality / structure improvement | `workflow.refactor` |
| Scheduled version release | `workflow.release` |
| Production emergency | `workflow.hotfix` |
| Unclear / mixed | Start with feature; split if scope creeps |
