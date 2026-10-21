---
id: state-changes-assert-what-shows
title: Tests of a state change assert what the page shows
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
tags: { stack: [], service: [], area: [testing, ui] }
evidence: { fired: 3, features: 14, source: "escape records" }
added: 2026-10-21
reports:
  - { fired: 3, features: 14, source: "escape records", added: 2026-10-21 }
status: active
---

# Tests of a state change assert what the page shows

## Rule

**State changes assert what shows.** A test of an action that changes state asserts the displayed value (a time, a status or plan line) and what disappears (an old failure line), not only the stored status.

## Why

Three bugs reached users after QA passed because the original tests checked the stored state while the page showed something else: a plan line kept its pre-approval status, a reply showed its creation time instead of its finish time, and a failure notice stayed on screen after the step was retried. `fired` counts these escapes; the rule was written after them.

## How to check

Each AC for a state-changing action names the visible text it expects and the text that must be gone; the test has an assertion for each.
