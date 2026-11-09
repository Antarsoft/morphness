---
id: 2026-11-09-small-bug-mode
title: small-bug is defined, and a small card for a bug fix with no plan file no longer stops a run
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - harness/MODES.md
  - harness/templates/auto/card.md
  - harness/templates/auto/feature-prompt.md
  - harness/modules/autonomous/README.md
  - scripts/auto/driver.py
removed: []
---

## What changed

- `harness/MODES.md` § Fixing a bug names the mode: **small-bug**, a small-mode bug fix with no plan file, failing test first, then the fix.
- With the autonomous module, the card template's `mode:` comment defines `small-bug` the same way, and the feature prompt says a plain-mode bug fix's card says `mode: small-bug`, not `small`.
- With the autonomous module, a `small` card with no feature folder is checked as `small-bug` (with a warning) when the branch has a failing-test commit followed by the fix. Without those commits, the exit reason says to relabel the card `small-bug` instead of "no folder".

## Why

The card template listed `small-bug` but nothing defined it. In an autonomous run, a fix made the small-mode bug fix with no plan file and labelled its card `small`. The driver then wanted `Plan/plan.md` and stopped the run.

## How to apply

Merge `harness/MODES.md` from the kit. With the autonomous module, also merge the card and feature-prompt templates, the module README and `scripts/auto/driver.py`.

## Skip if

Never; the run files only apply with the autonomous module.
