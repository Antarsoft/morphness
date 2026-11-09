---
id: 2026-11-09-no-harness-fix-loops
title: An autonomous run never inserts a fix for the harness's own files, or a fix of a fix
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/auto/driver.py
  - harness/templates/auto/card.md
  - harness/templates/auto/feature-prompt.md
  - harness/modules/autonomous/README.md
removed: []
reviewed: "It names .claude/ only as a path the driver reads in a bug line to route it to the backlog. It changes no guard rule, settings file or permission, and the driver writes only the backlog and the version checklist."
---

## What changed

- With the autonomous module, the driver no longer inserts a fix feature for a § Bugs found line whose `where` is under `scripts/`, `harness/`, `project/`, `.claude/` or `_harness/`. It adds the line to `_harness/HARNESS_BACKLOG.md` and to the version checklist's § Harness changes instead.
- Fixes are one level deep. A line about a fix feature (its slug starts `fix-`) goes to the backlog as a follow-up instead of becoming a fix of that fix.
- The feature prompt and the card template say both.

## Why

In an autonomous run, inserted fixes for `scripts/handoff.sh` and `scripts/checks.sh` each reported another harness bug. The driver inserted a fix for each fix, five levels deep, which used about eight features and the `max_features` limit while no product feature advanced.

## How to apply

With the autonomous module, merge `scripts/auto/driver.py`, the card and feature-prompt templates and the module README from the kit. A project-level AGENTS.md rule added as a workaround can stay or go.

## Skip if

The project doesn't use the autonomous module.
