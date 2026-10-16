---
id: 2026-10-16-light-mode-brief
title: A brief for light-mode code changes, and what record they leave
kind: rule
release: 2026-10-16
applies_to: { modules: [] }
files:
  - harness/MODES.md
  - harness/HANDOFFS.md
  - harness/agents/fullstack-engineer.md
removed: []
---

## What changed

Light mode sends a code change to the Full-stack subagent, but Full-stack stopped without an
approved `plan.md` and there was no brief for it. `harness/HANDOFFS.md` § Subagent prompt blocks now
has a **Full-stack engineer, light mode** block (task, files, out of scope, checks, what to hand
back), and the Full-stack body says that brief replaces the plan and `progress.md`.
`harness/MODES.md` § Light mode says plainly that there is no QA agent: the `before_qa` checks the
change touches run, scoped, and the PR (or the commit message) records them with their exit codes
under a **Light mode** line saying why the change qualified.

## Why

A light-mode code change either stalled at Full-stack's "no approved plan" stop or went out with
no brief and no record of which checks ran.

## How to apply

1. Add the light-mode block to `harness/HANDOFFS.md` § Subagent prompt blocks, before the QA block.
2. In `harness/agents/fullstack-engineer.md` § Before you start, step 1, add the sentence that a
   light-mode brief replaces the plan. If the project's `project/agents/fullstack-engineer.md`
   requires a plan for every run, add the same exception there.
3. Replace the first three bullets of `harness/MODES.md` § Light mode → Process with the kit's.
   Keep any project-specific light-mode rules.

## Skip if

The project never sends light-mode code changes to Full-stack (docs-only light mode).
