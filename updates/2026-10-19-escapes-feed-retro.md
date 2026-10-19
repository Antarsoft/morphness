---
id: 2026-10-19-escapes-feed-retro
title: A bug found after a pass always gets a retro item, and its fix checks sibling paths
kind: rule
release: 2026-10-19
applies_to: { modules: [] }
files:
  - harness/MODES.md
removed: []
---

## What changed

- Bug mode's retro line now always records one action item for the escape: the rule, checklist item
  or test that would have caught it, or one line on why none would.
- The fix checks the sibling paths for the same gap (other routes or pages that read the same data)
  and closes them in the same branch.

## Why

Retro rules now come only from misses, and a bug that slipped past QA is the one miss the feature's
own retro never saw. Without this, a run of clean retros adds nothing while the same kind of gap
shows up again on a new route.

## How to apply

1. Merge the new step 6 wording into `harness/MODES.md` § Bug mode.
