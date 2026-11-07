---
id: 2026-11-05-print-size-warning
title: A print over 12000 characters warns on its first line, and the Technical Lead prints in smaller calls
kind: template
release: v0.17.0
applies_to: { modules: [] }
files:
  - scripts/doc-section.sh
  - harness/TECHNICAL_LEAD.md
removed: []
reviewed: "It adds a warning line to the output of the read-only scripts/doc-section.sh and one sentence to harness/TECHNICAL_LEAD.md; no setting, guard rule, permission or config value changes."
---

## What changed

- **`scripts/doc-section.sh`**: when the sections printed in one call total more than 12000 characters, the first line of the output says so and asks for fewer sections per call. Nothing else in the output changes.
- **`harness/TECHNICAL_LEAD.md`**: a sentence under the read table: keep each print under about 12,000 characters (the plan template and `testing.md` together are 15K) and print files and sections in separate calls.

## Why

In the benchmark reruns, a batched print of the plan template and `testing.md` was cut, and a batched print of SETUP sections was saved to a file and read back. Each cost the Technical Lead two or three more calls on a context of over 100K tokens.

## How to apply

1. Copy `scripts/doc-section.sh` from the kit; projects rarely edit it.
2. Add the sentence to `harness/TECHNICAL_LEAD.md` before `## Must do`.

## Skip if

Your tool results are never cut at this size.
