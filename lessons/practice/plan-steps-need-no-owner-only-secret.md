---
id: plan-steps-need-no-owner-only-secret
title: No plan step needs a secret only the owner holds
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
tags: { stack: [], service: [], area: [vendors, planning] }
evidence: { fired: 1, features: 14, source: "prune audits" }
added: 2026-10-21
reports:
  - { fired: 1, features: 14, source: "prune audits", added: 2026-10-21 }
status: active
---

# No plan step needs a secret only the owner holds

## Rule

**Owner-only secrets.** A plan step that calls a vendor and needs a key only the owner holds becomes a human step, or the code handles the missing key defensively and a test covers it. Agents never wait on, ask for or read such a key.

## Why

A plan's first step needed a vendor key no agent has. It surfaced during dev and cost a QA round.

## How to check

Each vendor call in the plan lists where its key comes from; any key that comes only from the owner has a human step or a defensive-code test.
