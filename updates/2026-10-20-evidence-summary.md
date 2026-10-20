---
id: 2026-10-20-evidence-summary
title: Evidence summary script for showing how the harness worked
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/evidence.sh
  - harness/MORPHING.md
removed: []
---

## What changed

`scripts/evidence.sh` prints an anonymous summary of this project's run records: features finished,
how often QA passed first time, rework by prune window, escapes, estimated cost per feature, retro
items, rule audit results, trials and lessons adopted. `--out` also saves it under
`_harness/evidence/`. `harness/MORPHING.md` gains a short § Sharing evidence. `/morph-share` (plugin)
offers to share the summary; nothing is sent without the owner's yes.

## Why

The records were only readable inside a project, so showing that the harness worked meant a manual
review of the learnings, prunes and git history.

## How to apply

1. Merge the listed files and make the script executable (`chmod +x scripts/evidence.sh`).
2. Run `bash scripts/evidence.sh` once and read the output; nothing else changes.

## Skip if

The owner never wants to show or share project results.
