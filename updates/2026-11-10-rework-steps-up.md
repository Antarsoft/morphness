---
id: 2026-11-10-rework-steps-up
title: QA-fail rework runs as a new Full-stack run one effort step up
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/SETUP.md
  - harness/TECHNICAL_LEAD.md
  - harness/STRATEGY.md
  - harness/modules/autonomous/README.md
  - project/HARNESS_AGENTS.md
  - .claude/agents/fullstack-engineer.md
  - .claude/agents/fullstack-engineer-medium.md
  - .claude/agents/fullstack-engineer-xhigh.md
removed: []
---

## What changed

- After a QA fail, the rework goes to a **new Full-stack run one effort step up** (`medium` to `high`, `high` to `xhigh`; `xhigh` stays), within the project's `agents.fullstack.variants`. Before, it went back to the same variant.
- The rework prompt is the usual block from `scripts/handoff.sh fullstack <slug>` (`fullstack-bug` for a bug plan), plus one line: read `Development/progress.md` and `QA/qa-result.md` first, fix the failed items on the existing branch, keep what passed, and update `progress.md`.
- The plan's effort, not the rework's, decides QA's variant and whether the code review before QA runs. The number of QA rounds and the escalation to the owner are unchanged.
- The Full-stack agent descriptions say which variant takes rework of which plan.

## Why

A failed QA round usually means the work was harder than the plan's effort allowed. More effort on one agent is expected to fix that more often than another round at the same level. A new run also starts from the plan and the brief instead of the first run's long context.

## How to apply

Merge the files from the kit. `project/HARNESS_AGENTS.md` is your project's own file: change its sentence "QA-fail rework goes to the same Full-stack variant as the first round." to the kit's new wording, or say there why your project keeps the old rule. A project without an `xhigh` Full-stack variant steps up to `high` at most. With the autonomous module, the rework also runs on `auto.last_try_model`, as before.
