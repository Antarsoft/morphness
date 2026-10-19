---
id: review-result-never-ends-turn
title: A review result never ends the lead's turn
kind: rule
target: harness/TECHNICAL_LEAD.md
in_template: true
tags: { stack: [], service: [], area: [process, review] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# A review result never ends the lead's turn

## Rule

When a code or copy review hands back, the Technical Lead writes `review.md` and launches the fix round or QA in the same turn.

## Why

A thread sat idle after a review until the human asked what was happening.

## How to check

The turn that receives a review result also launches the next agent.
