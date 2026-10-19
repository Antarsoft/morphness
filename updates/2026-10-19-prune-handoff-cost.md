---
id: 2026-10-19-prune-handoff-cost
title: Hand-offs no longer wait on the network or poll background agents, and an exceeded budget fails the hand-off
kind: fix
release: 2026-10-19.2
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - harness/SETUP.md
  - harness/HANDOFFS.md
  - harness/TECHNICAL_LEAD.md
  - project/PROCESS.md
removed: []
---

## What changed

`scripts/prune-counter.sh` no longer runs `git fetch` at every hand-off: it reads the last fetched
`origin/<integration>` (set `PRUNE_FETCH=1` to fetch first). It only counts files in `_harness/prunes/`
whose name starts with a date as proposals. When a size budget (rules, checklists, project docs, or the
Technical Lead rule) is over and no proposal is open, it exits 1, so the hand-off is not complete until
the proposal is written; with a proposal open it exits 0 as before.

After launching a background agent the Technical Lead now ends its turn and waits for the completion
notification, instead of scheduling a check every 10 minutes (each check was a full turn over the thread's
context). A failure or stop notification is the cue to relaunch.

## Why

An offline or slow network added a stall to every hand-off, a budget that was only printed could be ignored,
and polling a long build cost a full-context turn every 10 minutes.

## How to apply

Merge the `scripts/prune-counter.sh` changes (the `PRUNE_FETCH` condition, the date-named proposal filter,
the `over` flag and the final exit status), the matching sentences in `harness/SETUP.md` § Retrospective,
the Background agents paragraph in `harness/HANDOFFS.md`, the bullet in `harness/TECHNICAL_LEAD.md`
and the example line in `project/PROCESS.md`. If you installed the lesson `background-agent-signs-of-life`, replace its rule with the new text.
