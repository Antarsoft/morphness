---
id: 2026-10-19-refused-check-gate
title: A check recorded "not run" is not a pass at the merge gate
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/CONTROLS.md
  - harness/agents/qa-engineer.md
  - harness/agents/fullstack-engineer.md
removed: []
---

## What changed

- `harness/CONTROLS.md` § Merge gate now says a check recorded **not run** is not a pass: it runs, or
  the owner accepts it in `plan.md` § Decisions, before the merge. The `security` module's offline
  `audit` stays the one exception.
- The refused-check rule (a check the environment refused is **not run**, never an "equivalent"
  command counted as a pass) is now in the QA and Full-stack agent bodies, not only in CONTROLS.md § Notes.

## Why

The rule said how to record a refused check but not what the merge gate does with it, and the two
agents who run the checks never read § Notes.

## How to apply

1. In `harness/CONTROLS.md` § Merge gate, add the sentence about a **not run** check after "A stale or missing record goes back to QA.", and (with the security module) the offline-`audit` exception line before "After merging the integration branch"
2. Add the refused-check sentence to `harness/agents/qa-engineer.md` (after "If a script is missing") and `harness/agents/fullstack-engineer.md` § Before handoff (before "All must exit 0").

## Skip if

Your copies already carry both.
