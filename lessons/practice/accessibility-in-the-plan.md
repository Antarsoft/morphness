---
id: accessibility-in-the-plan
title: Accessibility in the plan
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [ui, a11y] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Accessibility in the plan

Seed checklist item 19 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Accessibility in the plan.** A control with visible text and an accessible name has a name that contains the visible text, and the AC states both strings. Text on a new background token puts that state in the automated accessibility scan, so contrast is checked in every theme. A new page or dialog reachable by users goes into the accessibility test.

## Why

A control's label didn't contain its visible text; text on a new warning background failed contrast.

## How to check

both strings in the AC; the new state named in the a11y test list. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
