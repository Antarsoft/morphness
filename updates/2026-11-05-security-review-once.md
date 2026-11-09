---
id: 2026-11-05-security-review-once
title: The security review runs once, with a diff-only second pass after a fix round
kind: template
release: v0.17.0
applies_to: { modules: [security] }
files:
  - harness/SETUP.md
removed: []
reviewed: "It changes one sentence of the security review step in harness/SETUP.md from a full rerun to a second pass over the fix round's diff; no setting, guard rule, permission or config value changes."
---

## What changed

- **`harness/SETUP.md` § Code review before QA, step 2**: "After the review fixes, it runs again on the final code" becomes: the review runs once; when it had `fix` items, a second pass covers the fix round's diff only, without the 15-call minimum, and only when the round touched code the review read in full or added code on the same paths. `Plan/review.md` says which applies.

## Why

A security review rerun on the whole change after the fix round cost $0.46 more in one benchmark feature, and the docs gave it no reason beyond "the final code". What can go wrong in a fix round is the fix itself, so the second pass reads that.

## How to apply

1. In `harness/SETUP.md` § Code review before QA, step 2, replace the last sentence ("After the review fixes, it runs again on the final code.") with the new text. Keep any project wording.

## Skip if

You want the full rerun on the final code, for example on a payments project: keep your wording.
