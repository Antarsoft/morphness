---
id: 2026-10-17-prune-trend
title: One trend line for the prune
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - harness/SETUP.md
  - harness/templates/prune.md
  - _harness/LEARNINGS.md
removed: []
---

## What changed

`bash scripts/prune-counter.sh --prune` prints one summary of the features since the last prune, read
from their learnings files: `Last 7 features: rework rounds 0.4 avg, QA fails 2, cost $18.40 (6 of
7 measured)`. Rework rounds are QA rounds after the first; QA fails counts features that failed QA at
least once (a second round, or `failed-escalated`). The prune proposal's **Trend** line starts from it.
Folded lines in `_harness/LEARNINGS.md` § Entries now keep the feature's date.

## Why

The prune compared windows from a table it built by hand. One line from the same files makes the
comparison the same every time and costs nothing to produce. It stays a single line on purpose: the
learnings files keep their format, and no history or report is added.

## How to apply

1. Merge `scripts/prune-counter.sh` (the block after the rule gauge) and the wording in
   `harness/SETUP.md` § Prune step 1 and `harness/templates/prune.md` § 1.
2. Merge the § Entries line format in `_harness/LEARNINGS.md`. Existing condensed lines without a
   date can stay; add the date where the retro shows it.
3. Run `bash scripts/prune-counter.sh --prune`. A learnings file whose **Verdict** line has no
   `QA rounds: N` counts as one round; fix its line when that's wrong.
