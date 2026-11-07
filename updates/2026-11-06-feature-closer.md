---
id: 2026-11-06-feature-closer
title: A cheap feature closer drafts the closing records after a QA pass, and the Technical Lead checks them and decides
kind: template
release: v0.17.0
applies_to: { modules: [] }
files:
  - .claude/agents/feature-closer.md
  - harness/agents/feature-closer.md
  - harness.config.yml
  - harness/HANDOFFS.md
  - harness/README.md
  - harness/SETUP.md
  - harness/SKILLS_AND_MCPS.md
  - harness/templates/learnings-entry.md
  - harness/STRATEGY.md
  - harness/TECHNICAL_LEAD.md
  - project/HARNESS_AGENTS.md
removed: []
reviewed: "It adds a subagent file limited to `tools: Read, Write, Edit, Bash, Grep, Glob` (no web or MCP tools; its role body limits its writes to the three closing records and its commands to the cost and doc-section scripts and reads, and the guard checks its calls as it checks every agent's), one agents.closer line to harness.config.yml and the docs that launch it; no guard rule, permission or settings value changes."
---

## What changed

- **`feature-closer`** (new subagent, `.claude/agents/feature-closer.md` with its role body in `harness/agents/feature-closer.md`):
  - It runs on `agents.closer.model` (haiku by default) at medium effort.
  - After a full- or bug-mode QA pass, it reads the feature's records and the closing rules, and drafts three records from the files and the facts the Technical Lead passes it:
    - the steps file, or none;
    - `plan.md` set to `passed` with its **Steps file** line;
    - the learnings file, with the cost line pasted from `scripts/feature-cost.sh`, § What went wrong, and proposed action items, each left `open` and marked `human decides` where the owner decides.
  - It edits nothing else, never commits, and decides nothing.
- **`harness/TECHNICAL_LEAD.md`**: the **After QA pass** row launches the closer. The Technical Lead then:
  1. reads the learnings and steps files and checks them against the records and the conversation (every correction, stop and rework round it saw is a § What went wrong line);
  2. decides each item;
  3. commits, runs the prune counter and runs the cost script again for the hand-off line, in one call;
  4. pushes and marks the PR ready.

  On `failed-escalated` it sets the plan's status itself and launches the closer for the learnings file only.
  
  It prints SETUP § After QA pass or § Retrospective only for a case the draft doesn't settle.
- **`harness/HANDOFFS.md`** gets the § Feature closer prompt block (it passes what only the conversation holds: the verdict, human corrections, agent stops and blockers, connector actions and what they now show, human-only steps, remote config changes, run durations and tool calls, fired rules and lessons, the cost script's flags), the closer in the ownership rows for `plan.md`, the steps file and the learnings file, § Steps file, step 4 of § Mandatory flow, and the closer in the no-product-code-edits line.
- **`harness.config.yml`** gets `agents.closer: { model: haiku, effort: medium }`. The closer is also added to `project/HARNESS_AGENTS.md` (table row and tool limits) and to `harness/STRATEGY.md`, `harness/SETUP.md` (§ After QA pass, the roles table, § Workflow steps 5 and 6), `harness/README.md`, `harness/SKILLS_AND_MCPS.md` and the comment at the top of `harness/templates/learnings-entry.md`.

## Why

In the benchmark runs, the full-mode close took 6 to 9 main-chat calls. It printed about 11,000 characters of SETUP sections and read each template and record on a context of over 100K tokens. The closer does that reading in a small context on a cheaper model. The decisions stay with the Technical Lead: which items to approve, and what the owner decides. The cost line still comes from the script, never from an estimate.

## How to apply

1. Copy `.claude/agents/feature-closer.md` and `harness/agents/feature-closer.md` from the kit. Fill `{{models.closer}}` with `agents.closer.model` and `{{project.name}}` with your project's name.
2. Add `closer: { model: haiku, effort: medium }` under `agents:` in `harness.config.yml`.
3. Take the kit's **After QA pass** row and the two After-QA bullets of § Must do in `harness/TECHNICAL_LEAD.md`.
4. Take the kit's § Feature closer block, the three ownership rows, § Steps file's first sentence, step 4 and the ownership line in `harness/HANDOFFS.md`, and the first paragraph of `harness/SETUP.md` § After QA pass with § Workflow steps 5 and 6.
5. Add the closer's row and tool-limits sentence to `project/HARNESS_AGENTS.md`, and add it where `harness/STRATEGY.md`, `harness/SETUP.md`, `harness/README.md`, `harness/SKILLS_AND_MCPS.md` and the learnings template's comment name who writes the records (take the kit's wording).

## Skip if

Your Technical Lead already runs on a cheap model, or you want every closing record written in the main chat.
