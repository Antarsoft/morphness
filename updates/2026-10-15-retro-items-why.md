---
id: 2026-10-15-retro-items-why
title: Retro action items get a soft limit and a recorded reason
kind: rule
release: 2026-10-15.2
applies_to: { modules: [] }
files:
  - harness/SETUP.md
  - harness/MORPHING.md
  - harness/templates/retro.md
  - harness/templates/learnings-entry.md
  - _harness/LEARNINGS.md
  - _harness/learnings/README.md
  - .claude/rules/technical-lead.md
  - harness.config.yml
removed: []
---

## What changed

`loop.retro_max_items` is now the usual number of retro action items, not a hard cap. A retro
has only the items its findings call for: none is a normal retro, and items are never padded to
reach the number. More is allowed when each extra item comes from a different finding, with one
line under the table saying why. Every item also gets a **Why raised** column: the finding it
answers (`What to improve #N` or an Answers line) and the evidence (a QA round, a human
correction, a cost figure, a file). The prune uses it to check whether the problem an item fixed
came back after it landed.

## Why

"At most 3" could drop a real lesson on a long or failed feature, and nothing recorded why an
item was raised, so a prune could only see whether a rule fired, not whether it fixed what it was
added for. Requiring a finding for each item is also what keeps a soft limit from filling up with
weak items.

## How to apply

1. `harness/SETUP.md` § Retrospective: replace the "At most `loop.retro_max_items`" sentence in
   **Output** with the new **How many items** and **Why raised** bullets; add "its **Why raised**
   copied from the retro" to **Action items**. In § Prune step 2, add the sentence about checking
   an item's **Why raised**.
2. `harness/templates/retro.md` § Action items: the new heading, the paragraph on how many items
   and **Why raised**, and the **Why raised** column.
3. `harness/templates/learnings-entry.md`, `_harness/learnings/README.md` and
   `_harness/LEARNINGS.md`: add the **Why raised** column after **Action** in every action-items
   table (Open, Applied, Skipped). In the Skipped table rename **Why** to **Why skipped** (and the
   word in the state list). Existing rows get "not recorded" in the new column; don't invent
   reasons for them.
4. `harness/MORPHING.md` § Retro action items, `.claude/rules/technical-lead.md` (the retro
   bullet) and the `retro_max_items` comment in `harness.config.yml`: the soft-limit wording.

## Skip if

The owner wants a hard cap on retro items and doesn't want a reason recorded for each one.
