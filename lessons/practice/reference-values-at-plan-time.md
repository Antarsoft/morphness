---
id: reference-values-at-plan-time
title: Reference values at plan time
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [contracts, testing] }
evidence: { fired: 2, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Reference values at plan time

Seed checklist item 10 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Reference values at plan time.** Every AC example that names an output (a verdict, a label, a computed number) is run through today's code at plan time and its output recorded, also when copied from an older plan. An AC that says behavior is unchanged ("as today", "still refused") is checked once against the integration branch. A number quoted from a design review or another page is measured before it is trusted.

## Why

An example copied from an older plan had a different result under the current code; an "unchanged" claim was false on the integration branch; a reviewed width was off by half.

## How to check

the run results are in Greps or the plan's reference table. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
