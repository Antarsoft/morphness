---
id: 2026-10-16-missing-check-rows
title: A check the project doesn't have is left out, not marked "none"
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - project/CONTROLS.md
  - harness/modules/browser-e2e/README.md
removed: []
---

## What changed

A named check the project doesn't have (no lint yet, no browser tests) now has one rule everywhere:
its row is deleted from `project/CONTROLS.md` and `project/STACK.md`, and its name from
`harness.config.yml` → `checks`. The fill comment in `project/CONTROLS.md` used to say to write
"not configured" instead, and the install guide said "none (add when the project has one)" in one
place and "delete the row" in another. Removing the browser-e2e module now also drops the
`e2e-repeat` row and name.

## Why

Three conflicting instructions meant each install picked one at random, and `/morph-doctor`, which
expects every name in `checks` to have a command, flagged the "none" and "not configured" rows as
broken wiring. With one rule, a missing row means the project doesn't have the check, and agents
record it as **not run** wherever the kit names it.

## How to apply

1. In `project/CONTROLS.md` § Named checks, find rows whose command is "none", "not configured" or
   similar text rather than a command. With the owner's yes, delete each such row, its row in
   § Check scope and in `project/STACK.md` § Commands, and its name from every list under
   `harness.config.yml` → `checks`.
2. Without the browser-e2e module: delete an `e2e-repeat` row from `project/CONTROLS.md` and the name
   from `checks`, if either is there.
3. Take the new fill-comment wording only if the project still has the comment (installs normally
   deleted it).

## Skip if

Every row in `project/CONTROLS.md` § Named checks already has a real command.
