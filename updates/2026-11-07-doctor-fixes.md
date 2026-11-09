---
id: 2026-11-07-doctor-fixes
title: checks.sh status says clean on a clean tree, and the prune handles an action item with an unknown status
kind: fix
release: v0.18.0
applies_to: { modules: [] }
files:
  - scripts/checks.sh
  - harness/SETUP.md
removed: []
moved: []
---

## What changed

`bash scripts/checks.sh status` printed "uncommitted changes" in its header even when the working tree was clean; it now prints "clean". The prune (`harness/SETUP.md` § Prune) now treats an action item row whose status isn't `open`, `approved`, `deferred`, `applied` or `skipped` as `open`, lists it with the leftovers and folds it into the Open table.

## Why

The clean test read git's empty output as a failure, so every status header said "uncommitted changes" and QA couldn't tell a clean tree from a dirty one. Only the label was wrong: check results were keyed and reused correctly. A retro that wrote `proposed` for its action items left the next prune with rows that had no table to move to.

## How to apply

Take the new `scripts/checks.sh` (a one-line fix; an edited copy takes the same change to the `clean =` line). Merge the one sentence into `harness/SETUP.md` § Prune step 3. A learnings file that already uses another status: set those rows to `open` (or the TL's decision) now, or let the next prune sweep them.
