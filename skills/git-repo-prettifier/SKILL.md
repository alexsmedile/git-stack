---
name: git-repo-prettifier
version: 1.0.0
description: >
  Transforms a GitHub repo README into a high-performing, visually compelling page that earns stars, gets shared, and drives adoption. Use this skill whenever the user wants to improve a README, prettify a repo, make a repo more professional, attract contributors, increase stars, or just asks "make my repo look better." Also triggers when the user asks to write a new README from scratch for any open-source project, tool, CLI, agent, or library. Goes beyond cosmetic fixes — interviews the user about positioning, brainstorms hooks and titles together, and applies design patterns (badges, tables, hero sections, visual boxes, icons) extracted from top-performing repos.
---

# Skill: GitHub Repo Prettifier

## Purpose

Turn a bare or mediocre repo README into something people actually stop to read, bookmark, and share. The goal is not cosmetic — it's **conversion**: convert visitors into users, users into contributors, readers into stargazers.

Good READMEs are persuasion documents dressed as documentation.

This skill works interactively. It reads the repo, forms opinions, then **collaborates with the user** on positioning, tone, title hooks, and visual style before writing anything.

---

## Phase 1: Research (silent, do before talking to the user)

Read the repo before asking a single question:

1. Read `README.md` (current state)
2. Scan key files: `CLAUDE.md`, `AGENTS.md`, skill/agent files, `package.json`, `pyproject.toml`, or equivalent
3. Form your own opinion on: what it does, who it's for, what makes it different, what the current README gets wrong or misses

Come to the conversation prepared with a point of view, not just questions.

---

## Phase 2: Positioning Interview

After reading, open a focused conversation. Don't ask everything at once — one topic at a time.

### 2a. Reflect back your read

Show the user you understood the repo. State:
- What you think it does (your words, not theirs)
- Who you think the target audience is
- What you think the strongest angle is
- What the current README is missing or gets wrong

Example:
> "Here's my read: this is a skill library for coding agents that converts a business idea into a complete offer system using Hormozi frameworks. The current README buries the lead — it reads like documentation, not a product page. The strongest angle I see is the 11-output-file pipeline. Agree?"

### 2b. Brainstorm hooks and title options

Generate 3–5 title/tagline options. Present them with reasoning. Ask the user which direction resonates.

Hook types to explore:
- **Outcome hook** — "Turn any idea into a sellable offer in one session"
- **Identity hook** — "For founders who are done guessing at what to sell"
- **Contrast hook** — "Stop writing offers. Start engineering them."
- **Specificity hook** — "17 skills. 1 orchestrator. 11 output files. One complete offer."
- **Framework hook** — "Alex Hormozi's offer methodology — built for AI agents"

Ask: "Which of these feels most like you? Or is there a direction I'm missing?"

### 2c. Clarify depth and audience

Ask targeted questions based on what you don't yet know:

- **Audience type**: Developers? Founders? Agents running autonomously? All three?
- **Tone**: Technical and precise, or approachable and punchy?
- **Depth level**: One-page intro or full reference doc?
- **Prior art**: Any repos or READMEs the user loves the look and feel of?
- **Assets available**: Logo? Screenshots? Demo GIFs? If not, should we design around text-only?
- **SVG icon**: Ask "Do you want a custom SVG icon for the repo hero? I can generate one — or skip if you prefer text-only." If yes, ask for a brief description of what the icon should convey (concept, colors, style). Generate it at `docs/assets/<repo-name>-icon.svg` and reference it in the README hero.

### 2d. Visual style decision

Present the style options and get a pick:

**Option A — Clean minimal** (APM-style)
- Badges + tagline + tables. No icons. Whitespace-heavy. Scannable.

**Option B — Bold technical** (Firecrawl-style)
- Hero tagline + metrics + code blocks + comparison tables. Numbers-forward.

**Option C — Warm narrative** (Paperclip-style)
- Metaphor-driven lede, emoji-prefixed features, contrast table, identity-driven language.

**Option D — Custom mix**
- Describe what to borrow from each.

Ask: "Which style fits best, or what mix?"

### 2e. Section-by-section check-in

Before building the full README, present a proposed section plan:

```
Proposed structure:
1. Hero — [tagline choice] + badges
2. Problem statement — [pain you identified]
3. Quick start — [install + first command]
4. What you get — output file table
5. Skills library — full table
6. How it works — pipeline/agent flow
7. Who it's for / not for
8. Credits

Anything to add, remove, or reorder?
```

Wait for confirmation before writing.

---

## Phase 3: Visual Design Decisions

For each major section, offer to apply visual upgrades and ask if the user wants them:

### Hero styles
- Plain H1 + tagline (minimal)
- H1 + tagline + `> blockquote` summary (adds weight)
- HTML `<div align="center">` with centered title + badges (GitHub renders this)
- Logo image above title (only if asset exists or user wants to add one)
- SVG icon generated inline — create at `docs/assets/<repo-name>-icon.svg`, reference with `<div align="center"><img src="docs/assets/<repo-name>-icon.svg" width="80" alt="icon" /></div>` above the H1

### Badges
Show the full badge options, let user pick 2–5:
```md
![License](https://img.shields.io/badge/license-MIT-blue)
![Stars](https://img.shields.io/github/stars/USERNAME/REPO?style=flat)
![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-blueviolet)
![Platform](https://img.shields.io/badge/platform-Claude%20%7C%20Codex%20%7C%20Cursor-lightgrey)
![Version](https://img.shields.io/badge/version-1.0.0-green)
![Inspired by](https://img.shields.io/badge/inspired%20by-Alex%20Hormozi-orange)
```

### Tables vs. bullets
For feature/skill lists: ask whether user prefers a table (scannable, structured) or bullet list (faster to read, less formal).

### Icons and emoji
Ask: "Do you want emoji icons on section headers or feature lists? (e.g. `⚡ Quick Start`, `📦 What You Get`, `🧠 How It Works`) — adds visual texture but some repos prefer clean plain text."

### Visual boxes / callouts
GitHub markdown supports `> [!NOTE]`, `> [!TIP]`, `> [!WARNING]` callout blocks. Offer to use them for key info:
```md
> [!TIP]
> Start with `/hormozi-orchestrator` for a full offer system, or call any skill standalone.
```

Ask if user wants these used and where.

### ASCII diagrams vs. plain text
For pipeline/architecture sections: offer to render as ASCII tree or plain prose list. Example:
```
hormozi-orchestrator
├── sub-market    → MARKET_RESEARCH.md
├── sub-offer     → OFFER.md
└── sub-sales     → PITCH.md + HOOKS.md
```

Ask if user prefers the tree or a simple prose description.

### SVG flow diagram
For tools with a **sequential workflow or pipeline**, offer an SVG flow diagram instead of ASCII. SVG renders natively in GitHub READMEs and is far more readable than text art for multi-step flows.

Pattern (adapted from julianoczkowski/designer-skills):
- Vertical stack of colored rounded-rectangle boxes, one per step
- Left-side phase labels (e.g. "clarify", "document", "build") in muted grey
- Arrows between steps; dashed arrow + label for optional/on-request steps
- Right-side "iterate" loop arrow if the flow is non-linear
- Color-code by phase type (planning / documentation / system / build / review)
- Legend row at the bottom with color swatches
- Subtitle above the stack: tool/command name that orchestrates the flow
- Caption below: key behavioral notes ("confirms before advancing", "skip any phase")

Save to `docs/assets/<repo-name>-flow.svg` and embed with:
```md
<img src="docs/assets/<repo-name>-flow.svg" width="100%" alt="flow diagram" />
```

Offer this pattern when: the repo has 3+ sequential steps, a pipeline, or an orchestrator command that runs sub-commands in order. Ask the user to confirm colors and step names before generating.

---

## Design Patterns to Apply

These patterns are extracted from high-performing repos (Firecrawl 109k★, Fooocus, MochiDiffusion, Paperclip, APM, firecrawl-lean). Apply the ones that fit. Skip the ones that don't.

### Pattern 1: Strong Hero Section
The first 10 lines decide if the visitor stays.

Required elements:
- Project name (H1)
- One-line tagline — specific, outcome-focused, no jargon
- Badge row — 2 to 5 shields: license, stars, version, platform compatibility
- Optional: logo or screenshot (especially for UI tools)

Bad tagline: "A tool for building offers."
Good tagline: "Turn any business idea into a sellable offer — using Alex Hormozi's frameworks."

### Pattern 2: Problem-First Framing
Don't describe the tool. Describe the pain it solves.

Structure:
```
## The Problem
[1-3 lines: what the user suffers without this]

## What This Does
[1-3 lines: how it solves it, what the output is]
```

Or use a contrast table:
| Without | With |
|---------|------|
| Manually writing offer docs | Complete OFFER.md in one session |
| Guessing at pricing | Value-anchored price with justification |

### Pattern 3: Quantified Claims
Replace vague with specific. Numbers earn trust.

Bad: "Saves time"
Good: "Goes from raw idea to full offer system in ~20 minutes"

Bad: "Multiple output formats"
Good: "Produces 11 output files: OFFER.md, PITCH.md, HOOKS.md, LANDING.md, and 7 more"

### Pattern 4: Visual Hierarchy
Use formatting to guide scanning eyes:
- H2 for major sections
- H3 for subsections
- Bold for key terms
- Code blocks for all commands and file paths
- Tables for comparisons, command references, output lists
- Horizontal rules (`---`) to separate major sections
- Bullet lists for feature sets (3-7 items per list)

### Pattern 5: Progressive Disclosure
Structure for three types of readers:
1. **Skimmers** — get value from hero, tagline, badges, bolded terms
2. **Evaluators** — read problem/solution, feature table, quick start
3. **Adopters** — read full docs, architecture, output specs

Put content in this order:
1. Hero (tagline + badges)
2. What it is / problem it solves
3. Quick start (under 5 steps)
4. Features / what it does
5. Architecture / how it works
6. Output / what you get
7. Installation / full setup
8. Credits / attribution

### Pattern 6: Quick Start That Actually Works
The quick start must be copy-pasteable and produce visible output in < 2 minutes.

Include:
- Prerequisite line (what you need first)
- Install command in code block
- One example invocation
- Expected output (file created, result shown)

### Pattern 7: Social Proof Anchors
Earned credibility signals:
- Star count badge (auto-updates via shields.io)
- "Built on X" attribution (borrow credibility from known frameworks)
- Inspired-by attribution ("Inspired by Alex Hormozi's $100M Offers")
- Integration badges (works with Claude Code, Codex, Cursor, etc.)

### Pattern 8: Feature Table (not a wall of bullets)
For repos with many features, use a table:

| Feature | What it does |
|---------|-------------|
| `hormozi-offer` | Full Grand Slam Offer → OFFER.md |
| `audit-offer` | Score + rewrite weak offers |

### Pattern 9: Architecture Clarity
Show structure visually when it helps:
- Directory tree for file-based systems
- ASCII flowchart for pipelines
- Dependency order for agent systems

### Pattern 10: Honest Positioning
State what the tool is NOT for. This builds trust and filters the right users in.

```md
## Who This Is For

- Founders, coaches, consultants, and freelancers building offers
- Coding agents building offer-generation pipelines
- Anyone using Alex Hormozi's frameworks in their business

## Who It's Not For

- Generic copywriters looking for a fill-in-the-blank template
- Developers who need a code library (this is prompt-based, not an API)
```

---

## Tone Rules

- **Direct, not corporate** — write like a smart peer, not a product manager
- **Specific, not aspirational** — outcomes over vibes
- **No hype words**: "powerful", "revolutionary", "game-changing", "blazing fast" (unless you have a benchmark)
- Short sentences. Active voice. Present tense.
- Avoid: "This tool allows you to..." → Use: "Build X. Get Y."

---

## Badge Templates

```md
![License](https://img.shields.io/badge/license-MIT-blue)
![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-blueviolet)
![Stars](https://img.shields.io/github/stars/USERNAME/REPONAME?style=flat)
![Version](https://img.shields.io/badge/version-1.0.0-green)
![Platform](https://img.shields.io/badge/platform-Claude%20Code%20%7C%20Codex%20%7C%20Cursor-lightgrey)
```

Replace USERNAME/REPONAME and version. Choose 2–4 badges max — more dilutes signal.

---

## Output Format

Deliver a complete `README.md` (or `README2.md` if the user wants to review before replacing).

Structure the file exactly:
1. Title + tagline
2. Badge row
3. One-line description (bold or blockquote)
4. Problem / What this is
5. Quick Start
6. Features / Skills / Commands table
7. Architecture (if applicable)
8. Output (what gets produced)
9. Installation / Setup
10. How it works (pipeline, agent flow, etc.)
11. Credits / Attribution

---

## Phase 4: Write

Only write after the positioning interview and style decisions are done. Never write speculatively — the user must confirm the structure and style first.

Apply the agreed patterns. Deliver `README2.md` for review (not `README.md` directly, unless the user explicitly asks to overwrite).

After delivering:
- Ask for feedback section by section if the user wants to iterate
- Offer to tweak tone, swap a section, try a different hook, or change the visual style on any part
- Replace `README.md` only on explicit confirmation

---

## Creating special repos

### Agentic Skills

When creating agentic skills, preferred installation process is:

`npx skills add https://github.com/<usertag>/<repo>`

If they contain agents + skills, the preferred method is:

```bash
# Clone the skill library
git clone https://github.com/<usertag>/<repo>
cd <repo>

# Copy skills and agents into your Claude config
cp -r skills/ agents/ ~/.claude/
```

Do not ever delete files under skills/ or agents/.


---

## Process Summary

```
1. Read repo silently → form point of view
2. Reflect back understanding → confirm with user
3. Brainstorm 3–5 hooks/taglines → user picks direction
4. Clarify: audience, tone, depth, assets available
5. Present style options (A/B/C/D) → user picks
6. Propose section plan → user confirms or edits
7. Decide: icons? callouts? ASCII tree? badges? → user picks
8. Write README2.md
9. Iterate based on feedback
10. Replace README.md on confirmation
```

---

## Success Criteria

The new README succeeds when:
- A stranger can understand what it does in 10 seconds
- They can get it running in under 2 minutes
- They know exactly what output to expect
- They understand who it's for and who it's not for
- The structure rewards both skimmers and deep readers
- It builds credibility without hype
- The user is proud to share the link
