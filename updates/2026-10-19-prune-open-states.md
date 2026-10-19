---
id: 2026-10-19-prune-open-states
title: An approved prune proposal no longer prints "Prune is DUE", and a declined one closes
kind: fix
release: 2026-10-19
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - harness/SETUP.md
removed: []
---

## What changed

`scripts/prune-counter.sh` treats a prune proposal as open while its **Status** is `proposed` or
`approved`: it prints `Prune proposal waiting: <path>` (with `(approved, cuts not applied yet)` for
an approved one) and no `Prune is DUE` line. The status match is anchored to the whole line and
`_harness/prunes/README.md` is skipped. `harness/SETUP.md` § Prune now says an answered proposal is set
to `approved` or `declined`, that a declined one is still folded and reset (the window's learnings are
folded into `LEARNINGS.md`, noted as declined), and that `applied` is set when the approved cuts are in.

## Why

Before, `approved` and `declined` fell through to `Prune is DUE`, so the Technical Lead wrote a second
proposal for the same window right after the owner had answered the first.

## How to apply

Merge the `waiting=` block in `scripts/prune-counter.sh` and the sentences in `harness/SETUP.md` §
Retrospective (hand-off message and prune counter bullets) and § Prune (intro, steps 5 and 6).
