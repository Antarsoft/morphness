---
id: scheduled-jobs-and-limited-queries
title: Scheduled jobs and limited queries
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [data] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Scheduled jobs and limited queries

Seed checklist item 28 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Scheduled jobs and limited queries.** A row-limited candidate query filters on the exact condition, not a looser bound, so non-matches don't eat the limit. A retention rule ("older than X") states the worst case at the job's frequency. An action that must happen once (a send, a charge) claims a unique key before it acts.

## Why

A looser filter let non-matches fill the limit; a daily job kept up to a day of rows promised to last an hour.

## How to check

the query condition, the worst-case age and the unique key are in the plan. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
