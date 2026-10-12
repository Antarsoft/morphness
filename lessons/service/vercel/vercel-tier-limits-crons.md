---
id: vercel-tier-limits-crons
title: Read the plan tier before setting crons or limits
kind: checklist-item
target: project/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [vercel], area: [release, vendors] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Read the plan tier before setting crons or limits

## Rule

A plan that sets a cron frequency, function duration or other quota reads the account's tier on the vendor page; Hobby rejects crons more frequent than daily at deployment. A tier-only feature can ship dormant behind an env flag.

## Why

An hourly cron was rejected at deployment.

## How to check

The plan cites the tier page.
