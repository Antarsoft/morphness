---
id: reproduce-and-read-before-planning
title: Reproduce and read before planning
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [planning, debugging] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Reproduce and read before planning

Seed checklist item 5 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Reproduce and read before planning.** For a bug, a "jumps around", a "bug or not?" or a roadmap item, reproduce it locally first (with held or delayed responses for timing bugs, patched thresholds for time-based states) and read the existing code paths and every consumer of the function you plan to change.

## Why

Half of a planned item already existed; timing bugs only showed with slow responses.

## How to check

the plan cites the reproduction and the `file:line` of the cause or of the existing code. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
