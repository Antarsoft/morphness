---
id: tests-that-assert-changed-text
title: Tests that assert changed text
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [testing] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Tests that assert changed text

Seed checklist item 21 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Tests that assert changed text.** For each user-facing message the plan changes or says must not change, grep unit and end-to-end tests for the current text, for changed attributes (title, accessible label) and for empty-state text. When a default label or name is renamed, classify each hit as created data (update it) or seeded legacy data that still stores the old text (leave it).

## Why

Renamed defaults left tests stale, while a seeded legacy row correctly kept the old name.

## How to check

the grep per string and the classified hit list are in Greps. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
