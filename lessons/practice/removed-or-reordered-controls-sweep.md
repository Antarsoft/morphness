---
id: removed-or-reordered-controls-sweep
title: Removed, moved or reordered controls
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [testing] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Removed, moved or reordered controls

Seed checklist item 22 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Removed, moved or reordered controls.** The test-update sweep greps every test file for each control the plan removes or moves; no file is excluded by name. When it removes, adds or reorders an option of a group, it also greps every other label of the group, the test-helper parameters that select options, constants that list the options, and assertions that count them. When a validation rule is relaxed, it greps for the field's error element, its invalid-state attribute and submits that leave the field empty.

## Why

Specs used other labels of the same group; a test counted the options; a test submitted a blank field to get the old error.

## How to check

one grep per label, helper, list and count. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
