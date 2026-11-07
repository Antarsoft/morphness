---
id: 2026-11-07-batched-retro
title: "loop.retro_every: decide several features' retro action items in one pass"
kind: rule
release: v0.17.0
applies_to: { modules: [] }
files:
  - harness.config.yml
  - scripts/prune-counter.sh
  - harness/SETUP.md
  - harness/TECHNICAL_LEAD.md
  - harness/MORPHING.md
  - harness/HANDOFFS.md
removed: []
reviewed: "It adds one config key, loop.retro_every, whose default (1) keeps every feature's decisions at its close. No guard rule or settings value changes; prune-counter.sh only reads more files."
---

## What changed

- **`harness.config.yml`**: `loop.retro_every`. The default is `1`, which decides items at each feature's close, as before. A value from `2` to `5` batches the decisions.
- **`harness/SETUP.md`** § Retrospective → **Batched decisions**: with a value above 1, the Technical Lead still checks the closer's draft at each close, but leaves the action items `open` in the file and lists them as `open (batched)` in the hand-off. Two kinds of item are still decided, or put to the owner, at once: an item from an **Escaped** line, and an item the owner decides. When the batch is due, the Technical Lead decides every open and deferred item in the listed files in one pass and one commit, by the same rules (an item deferred at one batch is decided at the next), and runs the counter again for the hand-off. When a prune is due too, the batch is decided first.
- **`scripts/prune-counter.sh`**: with a value above 1, it prints `Retro decisions: N/<retro_every> features with open items`, and `Retro decisions are DUE: <files>` once N reaches it. It counts `open` and `deferred` rows, not one whose Note says `human decides`. A file that was there where the branch left the integration branch, or that is only there, is read from the integration branch, so an older local copy doesn't count items a batch already decided.
- **`harness/TECHNICAL_LEAD.md`** § Full mode, step by step, After QA pass row: points to the batched rule.

## Why

In the benchmark each full-mode close spent three to five main-chat turns deciding one feature's items. Deciding several features' items together takes one pass. An item that shows up next to the same miss in another feature also has more evidence behind it. The prune still runs on its own schedule (`loop.prune_every`).

## How to apply

1. Add `retro_every: 1` under `loop:` in `harness.config.yml`, with the kit's comment (the owner approves the edit).
2. Copy `scripts/prune-counter.sh` from the kit.
3. Add the kit's **Batched decisions** bullet to `harness/SETUP.md` § Retrospective, its wording in § Retrospective (Per-feature review, the leftovers sentence, Hand-off message) and § Prune step 3, and the batching clauses in `harness/TECHNICAL_LEAD.md` (After QA pass row, § Must do), `harness/MORPHING.md` § How rules change and `harness/HANDOFFS.md` § Mandatory flow step 4.
4. To batch, set `retro_every` to a value from 2 to 5.

## Skip if

You run only light and small mode (no retros).
