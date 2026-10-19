---
id: 2026-10-19-prune-waiting-line
title: A waiting prune proposal no longer prints "Prune is DUE"
kind: fix
release: 2026-10-19
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - harness/SETUP.md
  - harness/templates/prune.md
  - harness/modules/claude-projects/README.md
  - .claude/rules/technical-lead.md
removed: []
---

## What changed

While a prune proposal with **Status:** `proposed` waits for the owner, `scripts/prune-counter.sh`
prints only `Prune proposal waiting: <path>` and no `Prune is DUE` line (a size budget that is over
shows as a suffix on the waiting line). Before, both lines printed, and the hand-off bullet's "when it
prints DUE, write the proposal" could make the Technical Lead write a second proposal. The prune
proposal template's **Status** values now include `declined`.

## Why

The count stays at or above the threshold the whole time the owner is away, which is the case where
the proposal is written without waiting. The script now enforces "write one proposal, then name it".

## How to apply

Merge the `scripts/prune-counter.sh` change (the `due` variable and the final block that prints
either the waiting line or the DUE line). Merge the matching sentences in `harness/SETUP.md` § Retrospective
(hand-off message and prune counter bullets) and § Prune, the one in `.claude/rules/technical-lead.md`,
the playbook line in `harness/modules/claude-projects/README.md`, and `declined` in the **Status** line of `harness/templates/prune.md`.
