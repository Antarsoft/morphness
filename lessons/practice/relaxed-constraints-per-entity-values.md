---
id: relaxed-constraints-per-entity-values
title: Relaxed constraints and per-entity values
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [data, security] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Relaxed constraints and per-entity values

Seed checklist item 26 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Relaxed constraints and per-entity values.** A plan that drops or loosens a uniqueness, ownership or tenancy constraint states who can trigger the newly allowed state and how the vendor or system matches the record, with a source. A rule that keeps a stored per-entity value (a timestamp, counter, status) says "only for the same entity id".

## Why

A dropped unique id opened a cross-account path; a literal fallback copied one record's timestamp onto another.

## How to check

the trigger and match are named; every fallback is scoped to the entity. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
