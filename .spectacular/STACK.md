---
type: Anchor
id: 01a0252d-0929-7ea0-9252-e08ef853ddc5
human_ref: STACK
title: Technology and Distribution Stack
updated: "2026-08-21T16:35:03Z"
direction: Keep judgment portable across agent hosts and use deterministic local tools only where they improve speed, precision, or safety.
boundaries:
  - Portable Agent Skills are the primary behavior surface.
  - Git is the local repository substrate.
  - GitHub CLI (`gh`) is the first-release forge interface.
  - POSIX shell and Node.js support compact checks, synchronization, installation, and distribution validation.
  - Claude-specific commands and agents remain optional adapters over portable skills and scripts.
constraints:
  - Canonical scripts live in `src/scripts/`; generated skill copies are synchronized by `src/sync-scripts.mjs` and are never edited directly.
  - A quick preflight remains local, read-only, compact, and network-free.
  - GitHub access is earned only by operations that need remote collaboration or policy facts.
  - Missing optimization scripts degrade to direct read-only inspection rather than blocking ordinary Git work.
  - Existing manifest, secret, author-identity, and distribution gates remain authoritative until deliberately changed.
---

# Stack

The bundle consists primarily of Markdown skills with progressively disclosed
references. Shell scripts provide narrow Git safety checks and compact verdicts;
Node.js provides synchronization, installer, and distribution mechanics.

## Mechanical sources

- `src/scripts/git-stack.sh`: shared Git inspection and operation fast paths.
- `src/scripts/check-manifests.sh`: release and version consistency checks.
- `src/scripts/bump-manifests.sh`: controlled version updates.
- `src/scripts/validate-distribution.mjs`: cross-host distribution validation.
- `src/sync-scripts.mjs`: source-to-skill script distribution contract.

## Validation baseline

Use the narrowest applicable check during development, then the full bundle gates
before release:

```sh
node src/sync-scripts.mjs --check
scripts/check-manifests.sh
node src/scripts/validate-distribution.mjs --native
```

Skill changes additionally use their own structural checker, prompt fixtures,
and fresh-context review contract.
