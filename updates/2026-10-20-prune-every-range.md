---
id: 2026-10-20-prune-every-range
title: loop.prune_every is limited to 8 to 30
kind: rule
release: 2026-10-20.2
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - harness.config.yml
  - harness/SETUP.md
removed: []
---

## What changed

- `scripts/prune-counter.sh` reads `loop.prune_every` as 8 to 30. A lower value counts as 8 and a higher one as 30, and the script prints a line to stderr saying so. The default stays 10.
- `harness/SETUP.md` § Prune and the `harness.config.yml` comment state the range.

## Why

A rule that landed in the last 3 features is `too new to judge`. With a window of 5 or fewer features most rules in it are too new, so the prune audits almost nothing, and a trial is decided after one window, before its escaped bugs show up.

## How to apply

1. Copy the new clamp block after the `threshold=` lines of `scripts/prune-counter.sh`.
2. Add "(8 to 30)" to the `prune_every` comment in `harness.config.yml`, and the range to the due paragraph of `harness/SETUP.md` § Prune.
3. If `loop.prune_every` is below 8 in the project, raise it to 8 or more.
