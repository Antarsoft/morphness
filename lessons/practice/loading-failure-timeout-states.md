---
id: loading-failure-timeout-states
title: Loading, failure and timeout states
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [ui] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Loading, failure and timeout states

Seed checklist item 15 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Loading, failure and timeout states.** A plan that adds a loading, timeout or error state gives its exact copy, says what happens after the timeout, names what every visible value shows before the data arrives (not only the new element), gives an async refresh a visible in-progress state, and has an AC that the layout does not shift between states.

## Why

A strength label read "Strong" while its data loaded; a banner promised a later update after polling had stopped and grew 12 px.

## How to check

one row per state with copy, values and the no-shift AC. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
