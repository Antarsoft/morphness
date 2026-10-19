---
id: 2026-10-19-text-cleanups
title: Safety sections always read, last copies of old wording removed
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/agents/fullstack-engineer.md
  - .claude/agents/fullstack-engineer-medium.md
  - .claude/agents/fullstack-engineer-xhigh.md
  - .claude/agents/qa-engineer.md
  - .claude/agents/qa-engineer-medium.md
  - .claude/rules/technical-lead.md
  - harness/templates/small-plan.md
  - _harness/LEARNINGS.md
  - scripts/guard.sh
removed: []
---

## What changed

- The Full-stack wrappers now always read § Shared remote environments and § Ownership limits, and the QA wrappers always read § Ownership limits, besides the sections they read already.
- The small plan's § Why small and the Technical Lead rule point at the tests in `harness/MODES.md` § Small mode instead of repeating a shorter list.
- The small plan's QA scope line says QA runs its layout pass when the change touches styles, layout or a shared component.
- `_harness/LEARNINGS.md` links to the entry template instead of carrying its own copy.
- The `guard.sh` deny messages name the "Shared remote environments" golden rule in `AGENTS.md`.

## Why

The sections that stop harm were skipped by a medium agent told to read only what its task needs, and the old copies of the small-mode test and entry format had drifted from the originals.

## How to apply

Take the files above as they are. `scripts/guard.sh` changes message text only.
