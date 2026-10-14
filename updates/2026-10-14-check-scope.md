---
id: 2026-10-14-check-scope
title: Full-stack narrows its checks to what the branch changed
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/CONTROLS.md
  - project/CONTROLS.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/HANDOFFS.md
  - harness/templates/plan.md
  - harness/templates/progress.md
  - harness/modules/ci-cd/README.md
removed: []
---

## What changed

Full-stack's `before_qa` run can now be narrowed by the branch's diff
(`harness/CONTROLS.md` § Scoping by what changed). A documentation-only diff records each check as
`skipped: docs only`. Otherwise each check follows its row in the new `project/CONTROLS.md` § Check
scope: `full`, `affected` (a scoped command such as `pnpm --filter '...[origin/dev]' test`,
`vitest --changed` or `jest --changedSince`) or `paths` (the check runs only when the diff touches a
listed path). Cross-cutting paths, dependency changes, a missing merge base, a scoped command that
can't work out what is affected, or a plan's **Checks: full** run everything in full. `progress.md`
records each check's scope. QA's `before_signoff` run and CI always use the full commands.

## Why

Only the browser tests were scoped (targeted specs, cross-cutting paths). Typecheck, lint, unit and
build ran on the whole repo at every handoff, even for a docs-only change that CI and QA already
skip, which made small features in large repos slow to hand off.

## How to apply

1. Add § Scoping by what changed to `harness/CONTROLS.md` (after the Before Full-stack → QA handoff
   table) and the full-command sentence under § Before QA pass → human handoff.
2. Add § Check scope to `project/CONTROLS.md` after § Named checks. Fill rows only for checks this
   project's tooling can narrow; write "None: every check runs in full." otherwise, which keeps the
   old behaviour apart from the docs-only skip.
3. Merge the one-sentence changes into `harness/agents/fullstack-engineer.md` § Before handoff,
   `harness/agents/qa-engineer.md` (the merge-gate bullet), the Full-stack prompt in
   `harness/HANDOFFS.md`, and the **Checks** line in `harness/templates/plan.md` § QA scope.
4. Add the Scope column and diff line to `harness/templates/progress.md` § Validation.
5. With the `ci-cd` module, add the "CI runs the full commands" bullet to its README; the workflow
   doesn't change.
