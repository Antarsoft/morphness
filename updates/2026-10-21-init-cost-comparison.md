---
id: 2026-10-21-init-cost-comparison
title: Init shows a relative cost comparison for the model choice
kind: rule
release: v0.13.0
applies_to: { modules: [] }
files:
  - harness/MODEL_PRICES.md
removed: []
---

## What changed

`/morph-init` now says how the Opus preset compares with All Sonnet on cost (relative, from the price
table), and the hand-off reminds the owner that each feature ends with its measured cost. `harness/MODEL_PRICES.md` gains one sentence saying so.

## Why

Owners picked models without any sense of the price difference. Dollar figures at install time would
mislead (cost depends on the feature and goes stale with prices), so only ratios are shown, and the
project's own measured cost takes over after a few features.

## How to apply

Nothing to do for an installed copy. The merge adds one sentence to your `MODEL_PRICES.md`; your price edits stay.
