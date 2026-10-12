---
id: seeds-fixtures-and-raw-resets
title: Seeds, fixtures and raw resets
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [data, testing] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Seeds, fixtures and raw resets

Seed checklist item 25 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Seeds, fixtures and raw resets.** When a plan adds a column an action sets, locks or restricts a field, validates a format, or changes a time window or threshold, it greps seeds, fixtures, test helpers and raw SQL in tests for writes to the same rows and for every spelling of the affected value (for an age: every unit and arithmetic form, on either side of the old and new values), in every test folder.

## Why

Raw resets left a new timestamp set; seeded keys contained a character the new format refused; an age seed written in hours was missed.

## How to check

one grep per value and folder, every hit in the steps. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
