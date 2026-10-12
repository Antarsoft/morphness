---
id: enforcement-on-every-write-path
title: Enforcement on every write path
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [security] }
evidence: { fired: 3, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Enforcement on every write path

Seed checklist item 29 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Enforcement on every write path.** For each new limit or permission, the plan's **Enforcement** line names every write path (server actions, route handlers, direct database or API access, editors and import paths found by grep) and what blocks it, the status codes, and how the caller's identity is verified where access depends on it. A rule on stored data lists every writer of that data and every stored field the rule reads. A header or field condition is stated as non-empty, not present, when the checking helper treats empty as missing.

## Why

A direct API path bypassed a limit; a code review found an editor save path the rule had missed.

## How to check

grep every writer of the affected data; each is on the Enforcement line. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
