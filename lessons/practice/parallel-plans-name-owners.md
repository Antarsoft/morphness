---
id: parallel-plans-name-owners
title: Parallel plans
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [process, git] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Parallel plans

Seed checklist item 40 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Parallel plans.** When another plan is open at the same time, this plan names the owner of each shared file, names the other plan's functions in § Out of scope, and says which merges first when both touch the same non-doc file.

## Why

Two threads negotiating the same line crossed messages; naming the other plan's functions kept a merge to one docs conflict.

## How to check

list the open plans and the files they share (`git diff --name-only origin/<integration>...<branch>`). Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
