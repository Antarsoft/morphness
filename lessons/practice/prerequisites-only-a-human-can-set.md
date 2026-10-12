---
id: prerequisites-only-a-human-can-set
title: Prerequisites only a human can set
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [release] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Prerequisites only a human can set

Seed checklist item 38 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Prerequisites only a human can set.** Each third-party console screen the plan needs is listed with its precondition (domain verification, public pages reachable through a gate), and each production setting the feature depends on (an auth setting, a role, a secret, a host) is a human step in § QA scope, ordered before the release that needs it.

## Why

A first production release failed five times on setup that no plan had listed.

## How to check

one human step per console screen and production setting. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
