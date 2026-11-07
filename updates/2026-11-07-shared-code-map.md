---
id: 2026-11-07-shared-code-map
title: The code scout writes its map to a file that the Full-stack engineer, the review and QA read too
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/agents/code-scout.md
  - harness/agents/code-scout.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/HANDOFFS.md
  - harness/SETUP.md
  - harness/STRATEGY.md
  - harness/TECHNICAL_LEAD.md
  - harness/templates/plan.md
  - harness.config.yml
  - project/HARNESS_AGENTS.md
removed: []
reviewed: "It adds the Write tool to the code scout's subagent file for one file its role body names (`<feature>/Plan/code-map.md`, under `_harness/`, never product code), and changes prompt blocks and role bodies; no guard rule, permission or settings value changes. The guard checks the scout's writes as it checks every agent's."
---

## What changed

- **`code-scout`** writes its map to `<feature>/Plan/code-map.md` with the Write tool, the only file it writes, and replies with a summary of 200 words at most (path, commit, files to change, adjacent defects, not found, open questions). Its subagent file now sets `tools: Read, Write, Bash, Grep, Glob`.
- **`harness/TECHNICAL_LEAD.md`** § Full mode, step by step: the Technical Lead Reads the map file once, plans from it as before, writes a range or caller it found wrong into the map's § Technical Lead notes (now in its edit list), links the map from `plan.md` § References, and fills the map's path and commit into the Full-stack prompt block.
- **`harness/HANDOFFS.md`**: an ownership row for `Plan/code-map.md` (the scout writes it; the Technical Lead may add § Technical Lead notes); the Full-stack and QA prompt blocks name the map; the Code scout block says to write the file; step 0 of § Mandatory flow says the map's path goes into the later prompts.
- **`harness/agents/fullstack-engineer.md`** § Before you start: a new step reads the map and opens the code by its line ranges, reading further only where the change goes beyond them, never printing a whole file the map covers. When the current commit differs from the map's, the file wins. **`harness/agents/qa-engineer.md`** § Lean QA: a file outside the diff is opened by the map's ranges, not by searching.
- **`harness/SETUP.md`** § Code review before QA: the Technical Lead's brief for the security review, and for the fallback review subagent, names the map too (`/code-review` itself runs on the diff and needs no brief). The agents table says what the scout writes.
- **`harness/STRATEGY.md`**, **`project/HARNESS_AGENTS.md`** and the `agents.scout` comment in **`harness.config.yml`**: the scout's description and tool limits. **`harness/templates/plan.md`** § References gets a Code map line.

## Why

In the benchmark's largest feature the Full-stack engineer pulled about 380,000 new tokens into its context, 3.3 times what a plain run needed for the same work, because it searched and read the same files the scout had already mapped on a model 20 times cheaper. The map stopped at the Technical Lead. Writing it to the feature folder and handing its path on lets every later agent read by line range, so the code is searched once per feature.

## How to apply

1. Copy `.claude/agents/code-scout.md` and `harness/agents/code-scout.md` from the kit (fill `{{models.scout}}` and `{{project.name}}` as before).
2. Take the kit's wording for the **Map the code**, **Write the plan** and **Build** rows of `harness/TECHNICAL_LEAD.md`.
3. In `harness/HANDOFFS.md`, add the `Plan/code-map.md` ownership row and take the kit's Code scout, Full-stack engineer and QA engineer prompt blocks and step 0 of § Mandatory flow.
4. Add the map step to `harness/agents/fullstack-engineer.md` § Before you start (renumber the steps after it) and the map clause to `harness/agents/qa-engineer.md` § Lean QA.
5. Take the kit's sentences in `harness/SETUP.md` (the agents table row and the security-review brief), `harness/STRATEGY.md`, `project/HARNESS_AGENTS.md` (tool limits) and `harness/templates/plan.md` § References.

## Skip if

Your Technical Lead builds in full mode without a scout, or your features are small enough that the builder reads only a few short files.
