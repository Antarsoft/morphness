---
id: 2026-11-08-checks-path-and-harness-bugs
title: checks.sh refuses a path instead of crashing, and a card can report a bug in the harness
kind: fix
release: v0.18.0
applies_to: { modules: [] }
files:
  - scripts/checks.sh
  - scripts/auto/driver.py
  - harness/templates/auto/card.md
  - harness/modules/autonomous/README.md
removed: []
---

## What changed

- `bash scripts/checks.sh run <check> <path>` read the path as another check name and crashed with a traceback after the check had run. It now refuses any argument that isn't a check name, before running anything. The refusal says how to run one test file instead: the named command with the path (`npm test -- <path>`) or the runner's own form. A record still covers a whole check only, so the merge gate isn't fed a partial run.
- With the autonomous module, a card's § Bugs found takes `- harness | what | where` for a bug in the harness itself (its scripts, rules or templates). The driver puts it in the version checklist's § Harness changes for the owner. It adds no fix item, and the card counts as valid instead of the session being started again.

## Why

Both came up in an autonomous run. QA ran `checks.sh run unit <path>` and got a traceback. A Technical Lead reported a harness bug in § Bugs found, which only took feature slugs, so the card failed its check and the driver restarted the session.

## How to apply

Merge `scripts/checks.sh` from the kit. With the autonomous module, also merge `scripts/auto/driver.py`, `harness/templates/auto/card.md` and the module README.

## Skip if

Never; step 2 only applies with the autonomous module.
