---
id: 2026-11-06-code-scout
title: A cheap code scout maps the code before a full-mode plan, and the Technical Lead reads only the lines the plan changes
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/agents/code-scout.md
  - harness/agents/code-scout.md
  - harness.config.yml
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/README.md
  - harness/SETUP.md
  - harness/SKILLS_AND_MCPS.md
  - harness/STRATEGY.md
  - harness/TECHNICAL_LEAD.md
  - project/HARNESS_AGENTS.md
  - scripts/plan-brief.sh
removed: []
reviewed: "It adds a subagent file limited to `tools: Read, Bash, Grep, Glob` (no edit, web or MCP tools; `2026-11-07-shared-code-map` adds Write for one file under `_harness/`; Bash to search, read-only by its role body, and the guard checks its calls as it checks every agent's), one agents.scout line to harness.config.yml and the docs that launch it; no guard rule, permission or settings value changes."
---

## What changed

- **`code-scout`** (new subagent, `.claude/agents/code-scout.md` with its role body in `harness/agents/code-scout.md`):
  - It runs on `agents.scout.model` (haiku by default) at medium effort.
  - Before a full-mode plan, it searches with the shell (`git grep`, `rg`, `find`) and reads the code the change touches.
  - It replies with a map: the files and functions with line ranges, contracts, callers, tests, conventions, adjacent defects, what it didn't find, and open questions. (Superseded in the same release by `2026-11-07-shared-code-map`: the scout now writes the map to `Plan/code-map.md`, and the Full-stack engineer, the review and QA read it too.)
  - Its tools are Read, Bash, Grep and Glob: no edit, web or MCP tools. Its role body allows only commands that read. (`2026-11-07-shared-code-map` adds Write for the one map file.)
  - Bug mode doesn't use it: there the Technical Lead reads the failing code path itself before the risk check.
- **`harness/TECHNICAL_LEAD.md`** § Full mode, step by step:
  - A new **Map the code** row launches the scout.
  - **Write the plan** now reads the line ranges the map names for the code the plan changes, with Read's offset and limit, instead of whole files. The Technical Lead runs `git grep -n` on each function, type or table the plan changes, to confirm the map's callers, and re-checks any **Not found** the plan relies on. What the plan says about the code comes from its own read.
  - The research-mode bullet names the scout too.
- **`harness/HANDOFFS.md`** gets the § Code scout prompt block, step 0 of § Mandatory flow (full mode only), and the scout in the no-product-code-edits line.
- **`harness/STRATEGY.md`**, **`harness/SETUP.md`**, **`harness/README.md`**, **`harness/SKILLS_AND_MCPS.md`** and **`harness/MODES.md`** § Research mode name the scout with the other agents.
- **`harness.config.yml`** gets `agents.scout: { model: haiku, effort: medium }`. `project/HARNESS_AGENTS.md` gets its table row and tool-limits sentence.
- **`scripts/plan-brief.sh`** ends by pointing to the scout.

## Why

In the benchmark runs, the full-mode main chat read the code itself before the plan. That pushed its context past 100K tokens, which every later call of the feature re-reads. The scout reads on a model 10 to 20 times cheaper per token (`harness/MODEL_PRICES.md`) and hands back a short map, so the main chat's context grows only by the lines the plan changes.

Plan quality is kept three ways:
- the Technical Lead still reads the exact code the plan changes;
- the Full-stack engineer reads the real code;
- the code review and QA are unchanged.

## How to apply

1. Copy `.claude/agents/code-scout.md` and `harness/agents/code-scout.md` from the kit. Fill `{{models.scout}}` with `agents.scout.model` and `{{project.name}}` with your project's name.
2. Add `scout: { model: haiku, effort: medium }` under `agents:` in `harness.config.yml`.
3. Take the kit's code-scout parts of `harness/TECHNICAL_LEAD.md`: the **Map the code** and **Write the plan** rows, and the research-mode bullet.
4. Take the kit's code-scout parts of `harness/HANDOFFS.md`: § Code scout, step 0 of § Mandatory flow, and the ownership line. Add the scout where `harness/STRATEGY.md`, `harness/SETUP.md`, `harness/README.md`, `harness/SKILLS_AND_MCPS.md` and `harness/MODES.md` § Research mode list the agents (take the kit's wording).
5. Add the code scout's row and tool-limits sentence to `project/HARNESS_AGENTS.md`.
6. Copy `scripts/plan-brief.sh`.

## Skip if

Your Technical Lead already runs on a cheap model, or your codebase is small enough that the plan step reads only a few short files.
