---
id: measured-layout-acs
title: Measured layout
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [ui, layout] }
evidence: { fired: 2, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Measured layout

Seed checklist item 20 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Measured layout.** A size, overflow or wrapping AC names the worst-case input (schema maximum, unbroken and spaced) and the viewports, measures the existing element first, and is run once in the same browser build CI or the deploy uses. Tables and multi-column layouts get each column's width per breakpoint. "Nothing is cut off" is asserted with box measurements, not text content. An AC that asserts browser behavior (CSS, CSP, focus, opener) makes a spike the Full-stack engineer's first step.

## Why

A table was 2 px too wide only on CI's browser build; a size AC asked for a box larger than the element could be.

## How to check

worst-case input, viewports and measurement method are in the AC. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
