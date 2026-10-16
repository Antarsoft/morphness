---
id: 2026-10-16-review-skill-fallback
title: Code review before QA still runs when the review skills are missing
kind: rule
release: 2026-10-16
applies_to: { modules: [] }
files:
  - harness/SETUP.md
removed: []
---

## What changed

`harness/SETUP.md` § Code review before QA relies on Claude Code's built-in `code-review` and
`security-review` skills. When the environment doesn't have one, the Technical Lead now runs a
read-only subagent with the same scope and brief, and `Plan/review.md` opens with
`Review by: subagent (<skill> not available)`. The review is never skipped. `/morph-init` and
`/morph-doctor` now check that both skills are present and say what happens without them.

## Why

The review was assumed, not checked: in an environment without the skills, an `xhigh` feature had
no defined review at all.

## How to apply

Add the sentence to the end of step 1 of `harness/SETUP.md` § Code review before QA. If the project
moved that section, add it where the `/code-review high` step now lives.
