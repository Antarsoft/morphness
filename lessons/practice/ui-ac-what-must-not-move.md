---
id: ui-ac-what-must-not-move
title: What must not move
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [ui, layout] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# What must not move

Seed checklist item 14 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**What must not move.** An AC that compares two UI states says what must not change (element boxes, scroll height, sideways scroll), not "same height" of the state-specific element. A position compared across an action that can move focus or scroll uses page coordinates, not viewport coordinates.

## Why

Two message panels differed by their text; a viewport comparison failed because focus scrolled the page.

## How to check

each layout-stability AC names the boxes it measures and the coordinate space. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
