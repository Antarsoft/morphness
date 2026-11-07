---
id: 2026-11-05-bug-fix-adjacent-risk-path
title: A small bug fix whose edge input needs a risk path goes to bug mode, not out of scope
kind: template
release: v0.17.0
applies_to: { modules: [] }
files:
  - harness/MODES.md
removed: []
reviewed: "It adds one sentence to the small-mode bug fix steps in harness/MODES.md; no setting, guard rule, permission or config value changes."
---

## What changed

- **`harness/MODES.md` § Fixing a bug**: when an edge input the failing test names, or a defect next to the symptom in the same code path, can only be fixed by editing a risk path, the fix is bug mode (reusing the failing-test commit). It is no longer listed as out of scope while the fix ships without it. Same-pattern hits in other places stay out of scope unless the owner says otherwise.

## Why

A rerun of a paging bug fix named "equal created_at values" as an edge input, then left the `id` tie-breaker undone because it lives in a risk-path file. The fix passed its checks and still let items with equal timestamps move between pages.

## How to apply

1. In `harness/MODES.md` § Fixing a bug, merge the added sentences after "A fix that needs a risk path stops: bug mode…". Keep any project wording.

## Skip if

Your project has no risk paths, or you have removed small-mode bug fixes.
