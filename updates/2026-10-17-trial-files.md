---
id: 2026-10-17-trial-files
title: Trials as files, counted by the prune counter
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/templates/trial.md
  - _harness/trials/README.md
  - harness/MORPHING.md
  - harness/SETUP.md
  - harness/README.md
  - harness/STRATEGY.md
  - harness/templates/retro.md
  - harness/templates/learnings-entry.md
  - harness/templates/plan.md
  - harness/templates/prune.md
  - _harness/LEARNINGS.md
  - _harness/README.md
  - project/HARNESS_AGENTS.md
  - scripts/prune-counter.sh
removed: []
---

## What changed

A trial is now its own file, `_harness/trials/<trial-slug>.md` (template `harness/templates/trial.md`):
hypothesis, the exact rule text or variant, the feature it starts with, its length in features, the
metric (rework rounds, QA fails, cost) and the pass and revert conditions. A feature that runs it
writes `**Trial:** <trial-slug>` in its learnings file; that line is the result.
`scripts/prune-counter.sh` prints `Trial <slug>: N/<length> features` in every hand-off, and the
prune decides keep or revert from the numbers `--prune` prints. The prune adds each trial feature to
the trial file's § Results when it folds the learnings files.

## Why

Trials were rows in `_harness/LEARNINGS.md` § Trials and the prune tabulated their KPIs by hand, so
nobody saw a trial's progress between prunes and the decision rested on whatever the TL collected.
The result goes in the feature's own learnings file, not the trial file, so parallel features never
conflict.

## How to apply

1. Merge the listed files. `_harness/trials/README.md` and `harness/templates/trial.md` are new.
2. Move each row of the copy's `_harness/LEARNINGS.md` § Trials (and any trial bullet in
   `project/HARNESS_AGENTS.md` § Trials) to its own file from the template, keeping its scope, KPI,
   pass and revert lines; the features it already ran go in its § Results. Leave a one-line bullet
   in `project/HARNESS_AGENTS.md` linking the file for a model or effort trial.
3. In learnings files still in `_harness/learnings/`, rewrite a `**Trial:** <name>: <numbers>` line to
   `**Trial:** <trial-slug>` matching the new file name.

## Skip if

The copy has never run a trial and doesn't want them counted; the template text still changes, so
take at least steps 1 and 3 when a trial starts.
