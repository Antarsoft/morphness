---
id: 2026-11-07-evidence-no-cost
title: The evidence summary that /morph-share offers no longer carries cost figures
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/evidence.sh
  - harness/MORPHING.md
removed: []
---

## What changed

`scripts/evidence.sh` no longer reads or prints cost. The **Cost** line, the **Avg cost** column of the prune window table and the "Cost is an estimate" caveat are gone, and the `--json` output drops `overall.avg_cost_usd`, `overall.median_cost_usd`, `overall.cost_measured` and each window's `avg_cost_usd` and `cost_measured`. `harness/MORPHING.md` § Sharing evidence says the summary holds no cost or spend figures and why. Cost tracking itself is unchanged: `scripts/feature-cost.sh`, the learnings **Cost** line and the prune counter's totals stay, for the owner's own use.

## Why

The summary is what `/morph-share` publishes. A cost figure shared without the feature's size, mode and model mostly invites "this costs 5x plain" readings and says more about the owner's own spend than about what the harness caught, decided and learned.

## How to apply

1. Take the kit's `scripts/evidence.sh`.
2. Anything that reads the `--json` output and used the cost fields (a project's own dashboard or script) should take cost from `scripts/feature-cost.sh` or the learnings **Cost** lines instead. Before 1.0 a minor release may drop these fields (STABILITY.md).
3. Take the kit's wording for `harness/MORPHING.md` § Sharing evidence.
