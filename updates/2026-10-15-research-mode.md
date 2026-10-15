---
id: 2026-10-15-research-mode
title: Research mode and a read-only researcher subagent
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/MODES.md
  - harness/STRATEGY.md
  - harness/SETUP.md
  - harness/HANDOFFS.md
  - harness/README.md
  - harness/SKILLS_AND_MCPS.md
  - harness/agents/researcher.md
  - harness/templates/research.md
  - harness/templates/prune.md
  - project/agents/researcher.md
  - project/HARNESS_AGENTS.md
  - .claude/agents/researcher.md
  - .claude/agents/researcher-high.md
  - .claude/rules/technical-lead.md
  - .claude/rules/harness.md
  - _harness/README.md
  - _harness/research/.gitkeep
  - harness.config.yml
  - AGENTS.md
  - CLAUDE.md
removed: []
---

## What changed

A third mode next to full and light: **research mode**, for when the human wants an answer and no
change yet (how something works, why a bug happens, which library fits). The Technical Lead writes
the question and scope in `_harness/research/<date>-<slug>.md`, a new **researcher** subagent
answers it read-only with every claim cited (`file:line` or a URL with the date read), and the
Technical Lead checks the findings the answer rests on and records the decision: plan a feature, a
light-mode change, or no action. The researcher can also run before a plan, for a wide codebase
sweep or an unfamiliar API, with its file under the feature's `Research/` folder. It comes in two
variants, `researcher` (sonnet, medium) and `researcher-high` (opus, high, for architecture or risk
areas). The prune lists research files and what came of them.

## Why

Questions were either answered by the Technical Lead in the main chat, which loaded every file and
page it read into the rest of the thread and made every later turn more expensive, or squeezed into
light mode as a "spike" that left nothing behind. A separate read-only role keeps the search out of
the Technical Lead's context, runs on a cheaper model, can run two questions in parallel, and leaves
a cited answer the project can find again. The Technical Lead keeps its effort and its
responsibility for the decision.

## How to apply

1. Add the new files as they are: `harness/agents/researcher.md`, `harness/templates/research.md`,
   `.claude/agents/researcher.md`, `.claude/agents/researcher-high.md` and `_harness/research/.gitkeep`.
   In the agent files, fill `{{project.name}}` and the models (`{{models.researcher}}`: sonnet,
   `{{models.researcher_high}}`: opus, unless the owner wants others).
2. Add `project/agents/researcher.md` and fill its three sections from the project's docs and
   `project/SKILLS_AND_MCPS.md` (the docs to read first, the official docs for the stack, what to
   skip), or leave "Not set yet" lines.
3. Add `researcher: { model: sonnet, high_model: opus, default: medium, variants: [medium, high] }`
   under `agents` in `harness.config.yml`, and the two Researcher rows, the effort row and the
   "Researcher `high`" bullet to `project/HARNESS_AGENTS.md`, with the models the owner accepted.
4. Merge the rest: § Research mode and the two "Choosing mode" rows into `harness/MODES.md`; the
   Researcher row, folder entries and Agent 5 into `harness/STRATEGY.md`; the mode, execution and
   effort rows, the Technical Lead paragraph and the prune sentence into `harness/SETUP.md`; the
   ownership row and the researcher prompt block into `harness/HANDOFFS.md`; § 1c into
   `harness/templates/prune.md`; the research-mode bullet, the edit-list words and the command row
   into `.claude/rules/technical-lead.md`; the researcher bullet into `.claude/rules/harness.md`;
   and the small wording changes in `harness/README.md`, `harness/SKILLS_AND_MCPS.md`,
   `_harness/README.md`, `AGENTS.md` and `CLAUDE.md`.
5. Run `/morph-doctor`: it checks that both new agent files point at `harness/agents/researcher.md`.

## Skip if

The owner never asks questions that need more than a quick look, and wants the Technical Lead to
keep doing all research itself.
