---
id: 2026-10-19-post-merge-fixes
title: Small, bug and security wording lined up across the rules and templates
kind: fix
release: 2026-10-19
applies_to: { modules: [] }
files:
  - .claude/agents/fullstack-engineer-medium.md
  - .claude/agents/fullstack-engineer-xhigh.md
  - .claude/agents/fullstack-engineer.md
  - .claude/agents/qa-engineer-medium.md
  - .claude/agents/qa-engineer.md
  - .claude/rules/harness.md
  - .claude/rules/technical-lead.md
  - AGENTS.md
  - _harness/LEARNINGS.md
  - harness.config.yml
  - harness/CONTROLS.md
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/README.md
  - harness/RELEASE.md
  - harness/SETUP.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/modules/ci-cd/README.md
  - harness/modules/claude-projects/README.md
  - harness/modules/security/README.md
  - harness/templates/bug-plan.md
  - harness/templates/learnings-entry.md
  - harness/templates/prune.md
  - harness/templates/retro.md
  - harness/templates/small-plan.md
  - project/HARNESS_AGENTS.md
  - scripts/prune-counter.sh
removed: []
---

## What changed

After small mode, bug mode and the security module landed together, several texts still described
only full mode. They now agree: the small plan has a QA scope and a Decisions section and its limit
covers money, secrets, deleting or sharing data, a new page or flow and a schema change; a bug plan
asks for the security review when the module is on; the always-loaded rules say which sections apply
to full mode only; `secrets` runs even for a docs-only diff; a "not run" audit doesn't block the merge
gate. `scripts/prune-counter.sh` prints `Prune proposal waiting: <path>` while a proposal is
`proposed`, and the prune step folds only that proposal's window and lists its Escaped lines.
Agents read only their named sections of the feature file, and the QA layout pass runs only for
style, layout, shared-component or width-affecting changes. Security sentences in agent bodies carry
module markers so removing the module takes them out.

## Why

The always-loaded rule and templates are what agents follow, so a mismatch made small-mode work
follow full-mode steps or skip a security review. A persistent size-triggered DUE could also repeat a
full prune after every feature.

## How to apply

Optional text fixes. Take the changed files you haven't edited; for edited ones, merge the changed
sentences (the diff of each file in the kit shows them). The counter script is a plain replacement.
