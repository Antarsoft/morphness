---
id: 2026-10-19-checklist-group-index
title: The plan checklist starts with a group index the Technical Lead skips from
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/PLAN_CHECKLIST.md
removed: []
---

## What changed

`harness/PLAN_CHECKLIST.md` has a **Group index** table before its items: each group, its item numbers and
the condition under which the whole group is skipped (for example, no UI in the plan). A skipped group takes
the existing one-line `n/a` in `plan.md`, and its items are not read. The items and their numbers are unchanged.

## Why

A full-mode planning turn read the whole checklist even for a plan with no UI or no data. The index lets the
Technical Lead read only the groups the plan touches.

## How to apply

Add the **Group index** section and the changed first bullet of **How to use it** to your copy of
`harness/PLAN_CHECKLIST.md`. If you added groups or items of your own to a project checklist, add a row for them.
