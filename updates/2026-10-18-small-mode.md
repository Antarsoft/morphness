---
id: 2026-10-18-small-mode
title: Small mode, the default for fully specified requests
kind: rule
release: 2026-10-19
applies_to: { modules: [] }
files:
  - harness/MODES.md
  - harness/templates/small-plan.md
  - .claude/rules/technical-lead.md
  - .claude/rules/harness.md
  - harness/SETUP.md
  - harness.config.yml
removed: []
---

## What changed

A fifth mode, between light and full, and the default for a clear request. When the request says
exactly what to build, the change fits in a few files the Technical Lead can name, and it changes no
access rules, money, stored data's shape or deletion, secrets, dependency or flow, the Technical Lead
writes a short plan from `harness/templates/small-plan.md` (why it
qualifies, the change, the files, 3 to 8 acceptance criteria with their tests, a limit) instead of
`feature.md`, the full plan and the plan checklist run. Full-stack and QA still both run, at
`medium`. No `retro.md`: the learnings file carries `Retro: none (small mode)` and still counts
toward the prune counter. Risk is judged by what the change does, not by where it lives: a new query
parameter on a route in `risk_areas` stays small, a change to who that route answers does not.
`risk_areas` now means "changing how this behaves needs full mode", and its comment in
`harness.config.yml` says so.

## Why

On small, fully specified changes, full mode cost many times a plain Claude Code session for the
same result; small mode cut the cost by more than half with the same result. Limited to changes
outside every `risk_areas` entry, small mode was rarely picked: a risk area such as "public API
routes" ruled out almost every change. Access-control work stays in full mode.

## How to apply

1. Add `harness/templates/small-plan.md` from the template.
2. Merge `harness/MODES.md` § Small mode, the new row in § Choosing mode and the § Default line.
3. Merge the small mode bullet in `.claude/rules/technical-lead.md` (§ Must do, before the research
   mode bullet) and in `.claude/rules/harness.md`, and the reworded Agent effort bullet.
4. Merge the `Never medium for Full-stack` bullet in `harness/SETUP.md` § Effort per feature and the
   `risk_areas` comment in `harness.config.yml` (keep your own entries).
