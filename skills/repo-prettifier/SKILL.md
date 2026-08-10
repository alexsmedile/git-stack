---
name: repo-prettifier
description: >
  Rewrite or create a repo README that earns stars and drives adoption. Use for
  "improve my README", "prettify this repo", "make my repo look better", or a
  new README for any project, tool, CLI, agent, or library. Interviews for
  positioning first, then applies proven layout and design patterns.
metadata:
  version: "1.1.0"
---

# Skill: GitHub Repo Prettifier

## Purpose

Turn a bare or mediocre repo README into something people actually stop to read, bookmark, and share. The goal is not cosmetic — it's **conversion**: convert visitors into users, users into contributors, readers into stargazers.

Good READMEs are persuasion documents dressed as documentation.

This skill works interactively. It reads the repo, forms opinions, then **collaborates with the user** on positioning, tone, title hooks, and visual style before writing anything.

---

## Core Readability & Conversion Principles

Apply these universal principles of structure, visual design, and user psychology:

- **Plain Claim & Mental Model Contrast**: Open with one direct claim, then clarify the core concept using a memorable contrast ("If X is a worker, Y is the workplace") or a 3-step outcome table.
- **Early Audience Filtering ("Right for you if...")**: Include a short qualification checklist that filters readers early using hyper-relatable scenarios.
- **Spare Identity & Narrative Walkthrough**: Keep top-level framing concise: one-sentence identity, immediate quick start, then a brief narrative showing how a real session unfolds.
- **Concrete Execution Transcripts**: Use short, realistic text dialogs (`User: /cmd` → `System: output`) showing exploration becoming a proposal, implementation, and closure. Makes abstract workflows concrete without relying on heavy video or GIF assets.
- **Natural Action & Frictionless Installation**: Lead with a simple human promise and make installation feel like the immediate next step. For modern automation/AI tools, provide direct copy-paste prompts alongside CLI commands.
- **Attention Budgeting & Density Control**: Avoid trying to explain everything before earning reader attention. Keep the main flow scannable; delegate heavy reference manuals or massive code samples to collapsible blocks or dedicated `docs/` files.
- **Layouts, Visuals & Information Distribution Focus**: Place primary attention on how information is visually chunked and formatted. Actively consider visual building blocks during the design phase: icons, grids, tables, banners, custom SVGs, flowcharts, callout boxes (`> [!TIP]`), and tabbed code blocks.

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

### 2d. Layout & Visual Ideas to Mix and Match

Present layout ideas and visual elements tailored to the project. Mix and match from these inspiration patterns:

- **Clean & Scannable**: Badges + tagline + structured tables. Whitespace-heavy, no clutter.
- **Data & Proof-Forward**: Hero tagline + proof metrics + side-by-side code blocks + comparison tables.
- **Narrative & Framing**: Metaphor-driven lede, human promise, contrast table ("Without X" vs "With X"), qualification checklist ("Right for you if...").
- **Workflow & Interaction-First**: One-sentence identity, immediate environment quickstart grid, and a simulated execution transcript (`User: /cmd` → `System: output`).

Ask: "Which of these ideas or layout elements resonate best for this repo, or what mix should we combine?"

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

Read `references/design.md` now. It carries the style menus (hero, badges,
tables, icons, callouts, ASCII, SVG), the ten design patterns, tone rules,
badge templates, and the output format. Work through those decisions with the
user before writing anything.

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
5. Present layout & visual ideas → user selects elements to mix & match
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
