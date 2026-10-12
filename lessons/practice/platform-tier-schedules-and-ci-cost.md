---
id: platform-tier-schedules-and-ci-cost
title: Platform tier for schedules, limits and CI cost
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [release, vendors, ci] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Platform tier for schedules, limits and CI cost

Seed checklist item 37 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Platform tier for schedules, limits and CI cost.** A plan that sets a platform schedule, limit or quota (a cron frequency, a function duration, a rate limit) reads the vendor page for the account's current tier and names it with the source; "Full-stack to confirm" is not enough. A plan that adds a CI workflow or a long CI step times the main command locally and states the billed-minute estimate from that timing.

## Why

An hourly schedule was rejected at deployment by the account's tier; a CI estimate was off by 2x.

## How to check

the tier cite and the measured timing. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
