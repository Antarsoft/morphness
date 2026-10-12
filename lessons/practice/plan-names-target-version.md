---
id: plan-names-target-version
title: Target version
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [planning, roadmap] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Target version

Seed checklist item 2 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Target version.** When the roadmap module is on, the plan header names the version the feature ships in: the roadmap's single next version at plan time. If the roadmap has no single next version, ask the owner. Scope for a later version goes to that version's doc, not to this plan.

## Why

Scope drifts between versions when no plan says where it ships.

## How to check

grep the roadmap for the next-version marker; it matches exactly once. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
