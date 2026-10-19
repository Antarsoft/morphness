---
id: 2026-10-19-rules-from-misses
title: Retro rules come from misses, and the plan checklists get a size budget
kind: rule
release: 2026-10-19
applies_to: { modules: [] }
files:
  - harness/SETUP.md
  - scripts/prune-counter.sh
  - harness.config.yml
removed: []
---

## What changed

- A retro item that adds or tightens a rule must name a miss in that feature the rule would have
  caught (a failed QA round, a review finding that needed a fix, a human correction, rework, a bug
  after a pass). A clean feature adds no rule. While a size budget is over, an approved rule item
  removes or shortens text of at least its size, or waits for the prune.
- `scripts/prune-counter.sh` prints a `Checklists: X/Y KB` line for `harness/PLAN_CHECKLIST.md` plus
  `project/PLAN_CHECKLIST.md` against the new `loop.checklist_budget_kb` (default 36), and says the
  prune is due when they are over it.

## Why

Over 12 clean features, 10 retros each added checklist "specifics" and the project's rule files grew
by more than half, with no failure behind any of them. The always-loaded gauge
didn't see it, because the checklists aren't always loaded.

## How to apply

1. Merge the "Rules come from misses" bullet into `harness/SETUP.md` § Retrospective and the
   checklist budget wording in § Retrospective → Prune counter and § Prune.
2. Add `checklist_budget_kb: 36` under `loop:` in `harness.config.yml` (raise it if your checklists
   are already larger, then let the next prune bring them down).
3. Replace `scripts/prune-counter.sh` with the template's.
