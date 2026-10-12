---
id: customer-copy-what-customer-can-do
title: Customer copy says what the customer can do
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [copy] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Customer copy says what the customer can do

Seed checklist item 33 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Customer copy says what the customer can do.** UI text says what a customer can do or what happened to them, not implementation caveats (versions, caching, internal limits); those go in docs. For every "do X" instruction, the plan names what the product allows after X (locks, limits, one-way steps) and writes the AC against that. Reused sentences are re-read in their new place against the buttons and actions that surface has. A definition of a unit the product bills for or counts lists every code path that decides whether it counts, with `file:line`.

## Why

A note told customers to save an address "while you test", which locked it for good; a reused error told users to press a button the surface didn't have.

## How to check

one row per new note or instruction with what the customer can do next. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
