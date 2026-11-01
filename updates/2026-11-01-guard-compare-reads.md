---
id: 2026-11-01-guard-compare-reads
title: The guard lets /morph-update's curl compare read through, and checks Morphness URLs segment by segment
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
removed: []
---

## What changed

- `scripts/guard.sh` checks a `curl` of a Morphness GitHub URL for a `.` or `..` path segment after decoding it (`%2e`, `%2f`, a backslash or a second round of encoding still ask), instead of any `..` in the URL. `/morph-update` now asks GitHub whether the release it offers comes after this copy's commit (`repos/antarsoft/morphness/compare/<base>...<head>`), and the `...` in that read made every run ask.

## Why

`/morph-update` pins each run to a commit and stops when the upstream history doesn't line up, which needs that one read.

## How to apply

Merge `scripts/guard.sh`: the new `dotted_path` function above `check_curl`, and its use in `check_curl` in place of `".." in w or "%2e" in w.lower()`. Nothing else to do.
