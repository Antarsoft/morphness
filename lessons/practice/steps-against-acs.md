---
id: steps-against-acs
title: Steps against ACs
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [planning] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Steps against ACs

Seed checklist item 7 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Steps against ACs.** Re-read every step against every AC. A value, name, file, condition (when a mode is on) or status code that differs between the steps, the Enforcement line and the ACs is fixed before approval.

## Why

A status-code contradiction between steps and ACs cost a QA round.

## How to check

one pass with each AC beside the step that implements it. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
