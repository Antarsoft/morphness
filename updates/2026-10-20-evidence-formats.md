---
id: 2026-10-20-evidence-formats
title: evidence.sh reads older entry and prune forms and stops on history it can't read
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/evidence.sh
removed: []
---

## What changed

`scripts/evidence.sh` now reads the older one-line entry form (`- **slug v1** (2026-10-08): pass; QA 1; …`) next to the kit's, prune files named with a letter after the date (`2026-09-29-b.md`), rule audit tables with an id column, archived action-item tables, and ignores an `Escaped: none` line. It prints a "Records read" line, and stops with an error instead of a summary when more than a fifth of the folded entries do not match a known form (`--force` prints anyway).

## Why

The first version read only the exact forms the template writes today. Run on a project whose records predate that wording, it printed 6 features and 5 escapes for a history of 150 features and 4 escapes, and nothing showed that most of the history had been skipped.

## How to apply

1. Merge `scripts/evidence.sh`.
2. Run `bash scripts/evidence.sh` and check that "Records read" matches your history.

## Skip if

The copy never runs `scripts/evidence.sh` or never shares results.
