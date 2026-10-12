---
id: paddle-customer-matching-before-relaxing
title: Know how the vendor matches a customer before relaxing a constraint
kind: checklist-item
target: project/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [paddle], area: [billing, security] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Know how the vendor matches a customer before relaxing a constraint

## Rule

Before dropping a unique customer id or sharing a customer between accounts, the plan cites how Paddle matches a customer at checkout and who can trigger the shared state; a return-time sync re-checks the account binding itself.

## Why

Dropping a unique customer id opened a cross-account adoption path the security review found.

## How to check

The plan cites the vendor doc line on customer matching.
