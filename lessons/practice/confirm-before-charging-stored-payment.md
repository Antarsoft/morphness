---
id: confirm-before-charging-stored-payment
title: Confirm before charging stored payment details
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [billing, security] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Confirm before charging stored payment details

Seed checklist item 36 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Confirm before charging stored payment details.** A button or action that charges stored payment details states the confirm step before the charge, the exact amount shown and where it comes from (the vendor's preview, not an estimate), and the exact decline message.

## Why

An upgrade button charged the saved card at once with no confirmation.

## How to check

the three are in the plan with sources. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
