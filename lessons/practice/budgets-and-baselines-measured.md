---
id: budgets-and-baselines-measured
title: Budgets and baselines
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [data, performance] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Budgets and baselines

Seed checklist item 27 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Budgets and baselines.** A size budget on generated data is set from building the exact planned artifact once at plan time. A shared budget (a bundle size, a quota) is re-measured at each dev handoff, with the headroom and the other open plans competing for it named. An AC that a build output stays byte-identical checks every file the plan lists against that output's imports. A plan whose goal is a measured improvement re-measures the baseline over the last 10 to 20 runs (median of all and of the last 10) and measures before choosing options.

## Why

A planned data file came out 5 % over budget; another plan spent a shared budget measured at plan time; a stale baseline hid a growing suite.

## How to check

the measured numbers and their commands are in the plan. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
