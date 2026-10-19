---
id: 2026-10-19-trial-escape-window
title: A trial is decided only after an escape window, reading Escaped lines from fix PRs
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/MORPHING.md
  - harness/SETUP.md
  - harness/templates/trial.md
  - harness/templates/prune.md
removed: []
---

## What changed

A trial that has run its length is no longer decided at the next prune. It waits until one prune
window (`loop.prune_every` features) has finished after its last qualifying feature, and the decision
also reads the `Escaped` lines of bug-mode and fix-PR learnings files traced to the trial's features.
An escape traced to a trial feature counts against the trial. `harness/templates/trial.md` gains an
**Escape window** section and the prune template's trial rows say `carry on` while the window is open.

## Why

QA bugs show days after deploy. A QA effort change was kept on a "0 escapes" reading taken hours
after it shipped, and the next window logged 4 escapes. A trial decided before its escape window
closes measures nothing.

## How to apply

1. Merge the listed files.
2. Add the **Escape window** section to trial files already in `_harness/trials/` (copy it from
   `harness/templates/trial.md`).

## Skip if

The copy has never run a trial.
