---
id: 2026-10-21-trials-by-default
title: Retro items that change how a role works run as trials by default
kind: rule
release: v0.14.0
applies_to: { modules: [] }
files:
  - harness/MORPHING.md
  - harness/SETUP.md
  - harness/templates/retro.md
  - harness/templates/trial.md
removed: []
---

## What changed

`harness/MORPHING.md` § Trials gains "Trial by default": a retro item that changes how a role works (agent files, a role's model or effort, a rule a role follows) is approved as a trial, with the rule tagged `(trial: <slug>)`, a trial file and a Baseline. The retro template's Decision column offers `approve (trial)` and `approve (permanent, why)`. The window is unchanged: the trial runs its length, then waits one prune window before the prune decides it.

## Why

Role rules added on one retro's yes were never measured, and a bug QA missed shows a window later. Running them as trials makes each one earn its place against a baseline and the escapes that follow.

## How to apply

1. Merge the listed files.
2. Nothing to migrate: rules already in place keep their `(from …)` tags.
