---
id: threat-model-for-foreign-origins
title: Code that runs on other people's pages or origins
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [security] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Code that runs on other people's pages or origins

Seed checklist item 32 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Code that runs on other people's pages or origins.** A plan for code that runs on a customer's site or receives messages from another origin has a threat-model line: what it trusts, how a message's sender is verified, and forged-message tests for each trust rule.

## Why

Trust rules written into the plan became tests that caught forged messages.

## How to check

the threat-model line and one test per rule. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
