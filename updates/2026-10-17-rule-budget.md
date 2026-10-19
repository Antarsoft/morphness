---
id: 2026-10-17-rule-budget
title: Size gauge for the always-loaded rules
kind: config
release: 2026-10-19
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - harness.config.yml
  - harness/SETUP.md
  - harness/templates/retro.md
  - harness/modules/claude-projects/README.md
removed: []
---

## What changed

`scripts/prune-counter.sh` prints a second line for the hand-off, `Rules: 24.2/36 KB always loaded`:
the size of the files Claude Code loads into every session (`CLAUDE.md`, the files it imports with
`@`, and each `.claude/rules/*.md` without a `paths:` line) against the new `loop.rule_budget_kb`
(default 36). Over the budget it prints `Prune is DUE` with the three largest files. The 20 KB limit
on `.claude/rules/technical-lead.md` still applies.

## Why

The only size check was the Technical Lead rule passing 20 KB, a cliff nobody saw coming (review
fix A1 had to cut it from 19.4 KB). Every always-loaded byte is read on every turn, so the Technical
Lead now sees the total grow feature by feature and the prune starts before the rules get expensive.

## How to apply

1. Merge the template's `scripts/prune-counter.sh` (the gauge is the block after the count).
2. Add `rule_budget_kb: 36` under `loop:` in `harness.config.yml`. Run the script: when a copy that
   has morphed is already over 36 KB, show the owner the size and ask whether to raise the budget or
   plan a prune.
3. Merge the hand-off wording in `harness/SETUP.md` (§ Retrospective → Hand-off message and Prune
   counter, § Prune), the retro template's last line and, with the `claude-projects` module, its
   playbook line (re-paste the playbook into the project's instructions).
