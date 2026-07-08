# git-stack / github — GitHub Operations

This file covers everything that lives on GitHub rather than local Git:
pull requests, code review, issues, releases, repo setup, and CI/CD.

All GitHub operations use the `gh` CLI. Verify auth first: `gh auth status`

---

## Repository setup (git-stack.github.repo-setup)

**New project from scratch:**
```bash
# 1. Create local repo
mkdir ~/code/my-project && cd ~/code/my-project
git init
git add README.md .gitignore
git commit -m "chore: initial project scaffold"

# 2. Create remote and link
gh repo create my-project --private --source=. --push

# Or: create on GitHub first, then clone
gh repo create my-project --private
git clone git@github.com:username/my-project.git
```

**Minimum repo files at creation:**
```
README.md          # what/why/how
.gitignore         # what not to track
.gitattributes     # line ending consistency: * text=auto
LICENSE            # if public or shared
.env.example       # env var template (never the real .env)
```

**Protect main branch (for team projects):**
```bash
# Via gh CLI
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":[]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null
```

**Clone an existing repo:**
```bash
gh repo clone owner/repo          # SSH (preferred)
gh repo clone owner/repo ~/code/project-name
```

---

## Pull requests (git-stack.github.pr-create)

**Before opening a PR, always:**
```bash
git fetch origin
git rebase origin/main         # sync with latest main
git diff origin/main...HEAD    # review what you're shipping
git log origin/main..HEAD --oneline
```

**Open a PR:**
```bash
# Interactive (opens editor)
gh pr create

# One-liner
gh pr create --title "feat(auth): add OAuth2 login" --body "Closes #42"

# Draft (not ready for review)
gh pr create --draft --title "WIP: payment refactor"

# Target a different base branch
gh pr create --base develop
```

**PR description template** — use for non-trivial PRs:
```markdown
## What
Brief description of the change.

## Why
The reason this was needed.

## How
Key implementation decisions (if non-obvious).

## Testing
How to verify this works locally.

Closes #<issue>
```

**Manage an existing PR:**
```bash
gh pr list                           # all open PRs
gh pr view 42                        # details
gh pr checkout 42                    # check out locally
gh pr diff 42                        # see the diff
gh pr ready 42                       # convert draft → ready
gh pr close 42                       # close without merging
```

---

## Code review (git-stack.github.pr-review)

```bash
# Review inline via CLI
gh pr review 42 --approve
gh pr review 42 --request-changes --body "Please add test for edge case X"
gh pr review 42 --comment --body "Nit: rename this for clarity"

# View PR comments
gh pr view 42 --comments
```

**Merge strategies:**
| Strategy | When to use | Result |
|----------|-------------|--------|
| `--squash` | Feature branches with noisy WIP commits | Single clean commit on main |
| `--merge` | When branch history should be preserved | Merge commit, full history |
| `--rebase` | Linear history preferred, branch is clean | Replays commits, no merge commit |

```bash
gh pr merge 42 --squash --delete-branch    # most common
gh pr merge 42 --merge
gh pr merge 42 --rebase
```

**Guardrail:** Don't merge your own PRs on team projects without at least one review.

---

## Issues (git-stack.github.issue-manage)

```bash
# List
gh issue list
gh issue list --label bug --assignee @me

# Create
gh issue create --title "Bug: login fails on Safari" --label bug
gh issue create --title "Feat: dark mode" --label enhancement

# View and comment
gh issue view 15
gh issue comment 15 --body "Reproduced on macOS 14.3"

# Close
gh issue close 15
gh issue close 15 --comment "Fixed in PR #42"

# Reference in commits (auto-closes on merge to main)
git commit -m "fix(auth): handle Safari cookie SameSite issue\n\nCloses #15"
```

**Issue-to-PR link:** When you create a branch to fix an issue, name it:
```
fix/15-safari-login-cookie
```
Then reference `Closes #15` in the PR body to auto-close on merge.

---

## Releases and tags (git-stack.github.release)

**Semantic versioning:** `MAJOR.MINOR.PATCH`
- **MAJOR** — breaking changes
- **MINOR** — new features (backwards compatible)
- **PATCH** — bug fixes

```bash
# Create annotated tag
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0

# Create GitHub release
gh release create v1.2.0 --title "v1.2.0" --notes "## Changes\n- Feature X\n- Fix Y"

# Auto-generate release notes from merged PRs (great for consistent changelogs)
gh release create v1.2.0 --generate-notes

# Draft release (publish later)
gh release create v1.2.0 --draft --generate-notes

# List releases
gh release list

# Upload build artifacts
gh release upload v1.2.0 ./dist/app.tar.gz
```

---

## GitHub Actions CI/CD

**Manage workflows via `gh`:**
```bash
gh workflow list
gh workflow run deploy.yml
gh workflow run deploy.yml --ref feat/my-branch

# Monitor runs
gh run list --workflow=ci.yml
gh run watch                        # live tail
gh run view <run-id> --log
gh run rerun <run-id> --failed      # rerun only failed jobs
```

**Common workflow triggers:**
```yaml
# CI on every PR
on:
  pull_request:
    branches: [main]

# Deploy on merge to main
on:
  push:
    branches: [main]

# Manual trigger with inputs
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [staging, production]
```

**Standard CI structure:**
```yaml
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - run: npm run build
```

---

## Auth and account management

```bash
gh auth status          # check authentication
gh auth login           # authenticate (opens browser)
gh auth logout

# SSH keys
gh ssh-key list
gh ssh-key add ~/.ssh/id_ed25519.pub --title "my-laptop"

# Config
gh config set git_protocol ssh      # use SSH for clone/push (recommended)
gh config set editor "code --wait"
```

---

## Useful repository operations

```bash
# Fork a repo and clone your fork
gh repo fork owner/repo --clone

# View repo info
gh repo view
gh repo view owner/repo --web    # open in browser

# Manage repo settings
gh repo edit --visibility private
gh repo edit --add-topic python --add-topic api
gh repo archive                  # archive (read-only)
```
