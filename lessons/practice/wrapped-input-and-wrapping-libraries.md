---
id: wrapped-input-and-wrapping-libraries
title: Wrapped input and wrapping libraries
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [security] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Wrapped input and wrapping libraries

Seed checklist item 31 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Wrapped input and wrapping libraries.** Code that wraps user input (a script in a wrapper, a value in a template) has a step that validates the input alone as well as wrapped. When a plan wraps a request in a library's auth or error handling, it says what the library returns when the check throws and which headers it adds, with the source line.

## Why

A wrapper breakout passed validation of the wrapped form only; an auth wrapper answered a thrown lookup with the wrong status and an extra header.

## How to check

both validations are steps; the library behavior is cited. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
