---
id: 2026-11-10-lead-reads-less
title: the Technical Lead reads less per full-mode feature, and the plan puts the goal first
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/TECHNICAL_LEAD.md
  - harness/PLAN_CHECKLIST.md
  - harness/templates/plan.md
  - scripts/plan-brief.sh
removed: []
---

## What changed

- `harness/templates/plan.md`: § Acceptance criteria moves up, right after § Summary, and says the criteria are the end goal, written before the steps. The "Writing testable ACs" tips leave the template: each now lives in the plan checklist item it belongs to, so a plan reads the UI ones only when the UI group applies.
- `harness/PLAN_CHECKLIST.md`: item 7 (Steps against ACs) says where each AC is checked (a value that must not reach the client, a UI element's screen, the files a scan leaves out); item 9 asks for a design token's `file:line`; item 16 for the help text of a hidden or disabled control; item 18 for the repeat use in the same tab and after a reload; item 20 for worst-case test data and computed motion, focus and scroll results. No item was removed or renumbered.
- `harness/TECHNICAL_LEAD.md`: the rules `AGENTS.md` § Golden rules already loads in every session are no longer repeated (the mode-picking bullet, the long merging bullet, and the Command vocabulary table, whose rows were each a rule elsewhere in the file). Every rule stays; the file is about 10% shorter.
- `scripts/plan-brief.sh`: the brief leaves out `harness/SETUP.md` § Model of the Technical Lead, which is set at install, not per plan.

## Why

The main chat is the steady part of a full-mode feature's cost: everything it reads stays in its context for every later turn. The Technical Lead file and the plan brief are read in full on every full-mode feature, and both carried rules that were already loaded or only applied to some plans. Putting the acceptance criteria first makes the plan start from the end goal, as current agent guidance recommends.

## How to apply

Merge the four files from the kit. In a morphed `harness/PLAN_CHECKLIST.md`, add the new sentences to items 7, 9, 16, 18 and 20 by hand (before each item's `Check:`). In a morphed plan template, move § Acceptance criteria after § Summary and drop the "Writing testable ACs" list once the checklist carries its sentences. Plans already written keep their order.

## Skip if

Never.
