---
id: 2026-11-09-owner-decisions-and-duplicate-fixes
title: An autonomous run uses owner decisions recorded before a feature started, and inserts one fix per bug
kind: fix
release: v0.18.0
applies_to: { modules: [] }
files:
  - scripts/auto/driver.py
  - harness/modules/autonomous/README.md
removed: []
reviewed: "The driver only reads more of the version docs it already reads (git ls-tree and git show on the run branch) and writes nothing new. It changes no guard rule, settings file or permission."
---

## What changed

- With the autonomous module, a feature's prompt lists every owner row in a version doc's § Decisions table on the run branch, not only the rows added since the feature started. Rows by the Technical Lead, the director or another agent are left out, as before.
- When a later feature reports a bug that a fix the run already inserted covers (same buggy feature, same description up to its first comma or bracket), the driver adds no second fix. When that fix already passed, the checklist's § Needs you gets an item to check whether the bug came back.

## Why

In an autonomous run, the owner recorded "Upgrade stays allowed on a failed module" in `v1.md` § Decisions. A fix inserted after that only saw answers newer than its own start, so it asked the owner again and waited. A later feature reported the same finding again, and the run inserted a second fix for it. Both ended the run as waiting on the owner for a decision already made.

## How to apply

With the autonomous module, merge `scripts/auto/driver.py` and the module README from the kit. A run that ended "done, waiting on you" with such features picks the answers up on `bash scripts/auto/run.sh resume`.

## Skip if

The autonomous module isn't installed.
