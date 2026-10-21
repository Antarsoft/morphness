---
id: prerequisites-only-a-human-can-set
title: Prerequisites only a human can set
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [release, vendors] }
evidence: { fired: 1, features: 167, source: "prune audits" }
reports:
  - { fired: unknown, features: 153, source: "Twinpage prune audits", added: 2026-10-12 }
  - { fired: 1, features: 14, source: "prune audits", added: 2026-10-21 }
added: 2026-10-12
---

# Prerequisites only a human can set

Seed checklist item 38 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Prerequisites only a human can set.** Each third-party console screen the plan needs is listed with its precondition (domain verification, public pages reachable through a gate), and each production setting the feature depends on (an auth setting, a role, a secret, a host) is a human step in § QA scope, ordered before the release that needs it. A plan step that calls a vendor and needs a key only the owner holds becomes a human step, or the code handles the missing key defensively and a test covers it; agents never wait on, ask for or read such a key.

## Why

A first production release failed five times on setup that no plan had listed. In another project a plan's first step needed a vendor key no agent has; it surfaced during dev and cost a QA round.

## How to check

one human step per console screen and production setting, and each vendor call in the plan says where its key comes from. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
