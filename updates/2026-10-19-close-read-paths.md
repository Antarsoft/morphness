---
id: 2026-10-19-close-read-paths
title: Closing an access gap closes every read path, even when the owner is away
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/PLAN_CHECKLIST.md
removed: []
---

## What changed

Plan checklist item 29 (Enforcement on every write path) gains a sub-item for read paths. A plan
that closes who can see some data lists every route that returns it (single reads, lists, search,
counts, exports, sibling routers) and closes each in the same plan. Keeping an output's format is
not a reason to keep who can see its rows. When closing a path might break someone and the human
can't be asked, the plan closes it and names it in the hand-off instead of leaving the leak open.
The Security group's n/a line now also excludes plans that close an access gap.

## Why

A privacy fix closed the list, single note, search, tags and stats routes but left the CSV export
showing every user's notes, recorded as an owner decision because the README said to keep the
export format. A plain session without the harness closed it.

## How to apply

Merge the new indented sub-item under item 29 and the Security group's n/a line in
`harness/PLAN_CHECKLIST.md`. Item numbers don't change.
