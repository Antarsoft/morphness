---
id: slow-network-double-actions
title: Slow-network double actions
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [ui, testing] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Slow-network double actions

Seed checklist item 17 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Slow-network double actions.** A button that saves and then moves the page gets ACs for a second tap while its save is held and for opening another step before the save answers, with the request held in the test.

## Why

Local saves are instant, so a late answer reopening a step only showed on a slow deploy.

## How to check

the ACs exist and name how the request is held. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
