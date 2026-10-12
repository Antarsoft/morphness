---
id: paddle-preview-amount-before-charge
title: Show the vendor's preview amount before charging
kind: checklist-item
target: project/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [paddle], area: [billing] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Show the vendor's preview amount before charging

## Rule

A subscription change that charges the saved payment method shows a confirm step with the amount from the vendor's preview call, not an estimate.

## Why

An upgrade charged the card at once without confirmation.

## How to check

The plan names the preview call and the decline message.
