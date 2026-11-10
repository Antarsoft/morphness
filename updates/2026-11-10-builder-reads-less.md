---
id: 2026-11-10-builder-reads-less
title: the Greps record moves to Plan/greps.md, and the agent brief carries the testing rules once
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/templates/plan.md
  - harness/templates/bug-plan.md
  - harness/TECHNICAL_LEAD.md
  - harness/PLAN_CHECKLIST.md
  - harness/HANDOFFS.md
  - project/PLAN_CHECKLIST.md
  - scripts/handoff.sh
removed: []
---

## What changed

- The **Greps** record of the pre-approval checklist moves out of `plan.md` § References into its own file, `Plan/greps.md`, next to the plan. `plan.md` § References names it. The rule is unchanged: a plan with no Greps record is not ready for approval. `harness/HANDOFFS.md` lists the file (Technical Lead only), and the checklists and the Technical Lead file say where to write it.
- `harness/templates/plan.md` § Implementation steps: name existing code by `file:line` and say the change in words; write out only the text that must ship as written (a policy expression, an error message, UI copy).
- `scripts/handoff.sh`: the agent brief for Full-stack and QA held the testing rule file twice when the plan's files matched its paths. It now holds it once.

## Why

The Full-stack engineer, the code review and QA each read `plan.md` whole and carry it through every turn. The Greps record is the Technical Lead's evidence for approval, and none of them needs it; on a large feature it was several kilobytes of the plan. The duplicate testing rules added about 3 KB to every Full-stack and QA brief.

## How to apply

Merge the files from the kit. Then find every place that still sends the record into the plan, items your project added and installed lessons included: `grep -rn 'References → \*\*Greps' harness project` (and the role addenda under `project/agents/`). Change each "in `plan.md` § References → **Greps**" to "in `Plan/greps.md`", and the opening paragraph of `harness/PLAN_CHECKLIST.md`, which names where the record lives. Plans already written keep their Greps record where it is.

## Skip if

Never.
