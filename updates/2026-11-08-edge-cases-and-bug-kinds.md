---
id: 2026-11-08-edge-cases-and-bug-kinds
title: Plans spell out interface edge cases, and only a reproduced behaviour bug becomes a fix feature
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/PLAN_CHECKLIST.md
  - harness/TECHNICAL_LEAD.md
  - harness/agents/code-scout.md
  - harness/templates/auto/tech.md
  - harness/templates/auto/director-prompt.md
  - harness/templates/auto/card.md
  - harness/templates/auto/feature-prompt.md
  - harness/templates/auto/resume-prompt.md
  - harness/modules/autonomous/README.md
  - scripts/auto/driver.py
removed: []
---

## What changed

- Plan checklist item 41 (**Interface edge cases**, in the Testing group): when a plan builds or changes an interface that a design doc lists with edge cases, each edge-case row becomes one AC with a test, or is marked n/a with a reason. The group index in `harness/TECHNICAL_LEAD.md` gives Testing as `21-24, 41`.
- The code scout names, under Adjacent defects, each edge case in `docs/product/tech.md` that the existing code doesn't handle.
- With the autonomous module, `tech.md` § Interfaces between features is a table with one row per edge case (`Interface (path) | Shape | Producer → consumers | Edge case | Expected result`), and the director fills it for every interface: empty or zero input, boundaries, a call before ready, errors and failures, time edges, or one `none` row with the reason.
- With the autonomous module, a § Bugs found line takes a kind and a reproduction: `- <slug> | what | where | kind | reproduction`. Only `behaviour` with a failing test or steps becomes a fix feature. A behaviour line with no reproduction, or an old line with no kind, goes to § Needs you as unconfirmed. `style` goes to the prompt of the next feature built on the buggy one, or is dropped. `docs` becomes an item in `_harness/HARNESS_BACKLOG.md`. `decision` goes to § Needs you.

## Why

An autonomous run's interfaces were planned with no edge cases written down, so later features found the gaps, and every note they reported, including naming and doc nits, became an inserted fix feature with its own full session.

## How to apply

Merge `harness/PLAN_CHECKLIST.md`, `harness/TECHNICAL_LEAD.md` and `harness/agents/code-scout.md` from the kit. A project that cites its checklist items keeps its numbers: the new item is 41. With the autonomous module, also merge the module's templates, README and `scripts/auto/driver.py`.

## Skip if

Never; the autonomous files only apply with the module.
