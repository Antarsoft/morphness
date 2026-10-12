---
id: sources-for-assumptions
title: Sources for assumptions
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [contracts] }
evidence: { fired: 3, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Sources for assumptions

Seed checklist item 9 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Sources for assumptions.** Every framework or library assumption has a source. "Already used in this repo" names the `file:line`. UI labels and message texts in steps are quoted from the source with `file:line`. A claim marked verified cites the line of code that executes it, not a comment or doc. A step that corrects a review finding or an earlier note cites the line that proves the corrected value. An AC that names a failure condition and its visible result cites the code path that produces that result. A value the framework renders (a canonical URL, a normalized path) is compared normalized or with a cite of how the framework renders it. Anything not measured at plan time (build output such as static or dynamic routes, layout widths, a state pattern copied into a component that renders during a route transition) is marked "Full-stack to confirm".

## Why

Claims inferred from comments, greps or memory were wrong several times; a framework dropped a trailing slash; state cleared during render was lost mid-navigation.

## How to check

every claim in the plan has a `file:line`, a doc source or the marker. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
