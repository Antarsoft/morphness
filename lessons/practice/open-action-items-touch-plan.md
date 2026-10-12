---
id: open-action-items-touch-plan
title: Open action items that touch the plan
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [planning, process] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Open action items that touch the plan

Seed checklist item 4 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Open action items that touch the plan.** Grep `_harness/LEARNINGS.md` § Open and § Action items of every file in `_harness/learnings/` for `approved` or `deferred` items that name this feature or a file the plan touches; put each in the steps or say why not.

## Why

Approved items assigned to a feature landed nowhere because no plan picked them up.

## How to check

grep the touched paths and the slug over those files. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
