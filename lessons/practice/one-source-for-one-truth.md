---
id: one-source-for-one-truth
title: One source for one truth
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [contracts, architecture] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# One source for one truth

Seed checklist item 12 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**One source for one truth.** A promise that two surfaces show the same thing (a page and an API, a panel and an email) names the one function both call; a copy of the logic is a plan gap. When the server holds a state (a session, a lock, a revocation), the client reads it on refresh; a client timer alone is a plan gap.

## Why

A copied pipeline drifted from the original; a client timer kept a "still open" note for 30 minutes after the server had closed the session.

## How to check

the shared function or the server read is named with `file:line`. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
