---
id: false-positive-rate-of-threshold
title: False positives of a user-facing threshold
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [contracts, stats] }
evidence: { fired: 2, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# False positives of a user-facing threshold

Seed checklist item 13 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**False positives of a user-facing threshold.** A threshold behind a user-facing label (a verdict, alert, badge, status) gets a simulation or measurement of how often the label appears when nothing is true (a null or A/A run), and the number goes in the plan. An AC that quotes the label names the component that shows or hides it.

## Why

An unmeasured cut-off showed a "leading" label in about a third of null runs.

## How to check

the measured rate and the component's `file:line` are in the plan. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
