---
id: 2026-10-19-project-docs-budget
title: The project fact docs get a size budget
kind: config
release: 2026-10-19
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - harness.config.yml
  - harness/SETUP.md
  - project/PROJECT.md
removed: []
---

## What changed

- `scripts/prune-counter.sh` prints a `Project docs: X/Y KB` line for `project/*.md` against the new
  `loop.project_docs_budget_kb` (default 48), and says the prune is due when they are over it,
  naming the two largest files.
- The prune's scope includes the project fact docs: condense what a plan no longer needs, and swap
  hand-kept lists (every route, table or component) for a pointer to the code or a generated file.
- `project/PROJECT.md` says it holds architecture and conventions, not full lists.

## Why

Every plan reads the project docs, and nothing capped them. A Technical Lead that documents each new
route grows `PROJECT.md` by about a kilobyte a feature, so every plan gets slower and dearer.

## How to apply

1. Add `project_docs_budget_kb: 48` under `loop:` in `harness.config.yml` (raise it if your project
   docs are already larger, then let the next prune bring them down).
2. Replace `scripts/prune-counter.sh` with the template's.
3. Merge the project docs wording into `harness/SETUP.md` § Retrospective → Prune counter and
   § Prune (due conditions and scope), and the guidance line at the top of `project/PROJECT.md`.
