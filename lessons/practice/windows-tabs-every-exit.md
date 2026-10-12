---
id: windows-tabs-every-exit
title: Windows, tabs and sessions the product opens
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [ui] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Windows, tabs and sessions the product opens

Seed checklist item 18 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Windows, tabs and sessions the product opens.** A flow that opens or reuses a window, tab or session gets an AC for the second use in a row and an AC for where the user ends up on every exit (done, cancel, escape, refusal).

## Why

A cancel left a helper tab open because the ACs checked the message sent, not where the user ended up.

## How to check

one AC per exit path plus the repeat use. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
