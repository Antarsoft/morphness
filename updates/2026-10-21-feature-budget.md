---
id: 2026-10-21-feature-budget
title: Optional soft spend cap per feature (loop.feature_budget_usd)
kind: config
release: v0.14.0
applies_to: { modules: [] }
files:
  - harness.config.yml
  - scripts/feature-cost.sh
  - harness/TECHNICAL_LEAD.md
  - harness/SETUP.md
removed: []
---

## What changed

`harness.config.yml` has a new key under `loop`, `feature_budget_usd: 0` (off). Set it to a dollar amount and `scripts/feature-cost.sh` prints a `Budget: $X of $Y (NN%)` line before its `Cost ≈ $…` line. The Technical Lead runs the script each time a subagent returns; when the estimate is over the cap, it stops and asks you whether to continue, raise the cap or stop.

## Why

A feature's cost shows up only in the retro, after the money is spent. A cap you choose gives one point mid-feature where you decide whether it is worth going on. It is a soft estimate at API list prices checked between steps, so it can overshoot by one step.

## How to apply

1. Add `feature_budget_usd: 0` to the `loop:` block in `harness.config.yml` (the template line has a comment), and a number above 0 if you want a cap.
2. Take the new `scripts/feature-cost.sh` and the Technical Lead and SETUP text from the template.
3. Run `bash scripts/feature-cost.sh` once; with a cap set and a session on record it prints the `Budget:` line.

## Skip if

You don't want a cap. Without the key nothing changes.
