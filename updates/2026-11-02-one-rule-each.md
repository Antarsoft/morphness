---
id: 2026-11-02-one-rule-each
title: Rules that said two things now say one
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/rules/testing.md
  - .github/pull_request_template.md
  - AGENTS.md
  - harness/CONTROLS.md
  - harness/HANDOFFS.md
  - harness/MORPHING.md
  - harness/PLAN_CHECKLIST.md
  - harness/TECHNICAL_LEAD.md
  - harness/agents/fullstack-engineer.md
  - harness/modules/claude-projects/README.md
  - harness/templates/plan.md
  - project/CONTROLS.md
  - project/HARNESS_AGENTS.md
  - project/TESTING.md
removed: []
reviewed: "It names harness.config.yml → agents and .claude/settings.json → model only to compare them with the agent files; it changes no guard rule, permission or setting, and any fix to the settings is the owner's choice, made by the owner."
---

## What changed

- **Browser suites run for every change.** `harness/CONTROLS.md` said `e2e-targeted` and `e2e-full` were required only "for features touching screens, auth or a public API", while the QA role, the browser-e2e module and `checks.before_signoff` ran them for every change, and the merge gate needs every `before_signoff` check. CONTROLS now says every change. `project/CONTROLS.md` marks `e2e-targeted` required, and the PR template and `harness/templates/plan.md` drop the condition too.
- **A parallel merge goes back to QA.** `harness/HANDOFFS.md` § Parallel plans had the Technical Lead merge both branches and run the `before_signoff` checks itself, which its own rules forbid. Now each PR merges on the human's ask. The second one merges the integration branch in and returns to QA under `harness/CONTROLS.md` § After merging the integration branch.
- **Long output keeps the real exit code.** `AGENTS.md` said to pipe long output through `head`/`tail`, which reports the pipe's exit code. It now shows the log recipe from `harness/CONTROLS.md` § Command output.
- **One source for models.** `harness.config.yml` → `agents` holds the models. The agent files' `model:` lines and `.claude/settings.json` → `model` are copies that Claude Code reads.
  - `project/HARNESS_AGENTS.md` § Agents names the config key for each agent instead of restating its model.
  - `harness/MORPHING.md` sends a model lesson to the config first, then the copies.
  - `/morph-doctor` reports an agent file whose model or effort disagrees with the config.
- `harness/PLAN_CHECKLIST.md` had § How to use it twice; one copy is gone.
- **Vague words become tests:**
  - "useful" or "meaningful" tests are now one test per behaviour changed, one that fails when the behaviour breaks;
  - "when setup cost is reasonable" and "stable and small" become "runs without a live service";
  - "Prefer files over memory" says to name the file a fact comes from;
  - the thread rule ("send nothing into a thread that needs no action") becomes "a message to a thread asks for an action", owned by `harness/HANDOFFS.md` § Threads; `harness/TECHNICAL_LEAD.md` and the claude-projects module point to it.

## Why

Each pair let an agent follow one rule and break the other, and a retro couldn't tell which one was meant. The kit's own rule is one rule, one owner file.

## How to apply

1. Merge `harness/CONTROLS.md` § Before Full-stack → QA handoff and § Before QA pass, the `e2e-targeted` row of `project/CONTROLS.md`, `.github/pull_request_template.md` and `harness/templates/plan.md`. If your project chose to skip the browser suites for backend-only changes, keep that choice in your own files instead: the Required column of `project/CONTROLS.md` and a line in `project/agents/qa-engineer.md`, so the rule stays one rule.
2. Merge `harness/HANDOFFS.md` (§ Parallel plans and the Full-stack prompt block), `AGENTS.md` (the facts and long-output golden rules), `harness/PLAN_CHECKLIST.md`, `harness/TECHNICAL_LEAD.md` § One feature per thread, `harness/modules/claude-projects/README.md`, `harness/MORPHING.md`, `.claude/rules/testing.md`, `harness/agents/fullstack-engineer.md` and `project/TESTING.md`.
3. In `project/HARNESS_AGENTS.md` § Agents, replace the Model column's values with the `agents` keys and add the **One source for models** paragraph. Then compare `harness.config.yml` → `agents` with each `.claude/agents/*.md` `model:` line and with `.claude/settings.json` → `model`. Bring each difference to the owner and fix the side they choose; a trial variant keeps its trial model.

## Skip if

Never.
