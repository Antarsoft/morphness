---
id: 2026-10-21-trial-baseline
title: Trial baselines and a no-outside-answers rule for agents
kind: rule
release: v0.13.0
applies_to: { modules: [] }
files:
  - harness/templates/trial.md
  - harness/MORPHING.md
  - harness/agents/qa-engineer.md
  - harness/agents/fullstack-engineer.md
removed: []
---

## What changed

A trial file now has a **Baseline** section, written when the trial starts: the last prune window's rework rounds, QA fails and cost per feature, and one comparable earlier feature without the change. `harness/MORPHING.md` § Trials step 1 asks for it. The QA and Full-stack agent files each gain a rule: acceptance criteria and expected results come only from the plan in the repo, never from public repos, issue trackers or benchmark and grading data; something that looks like an answer key is reported, not used.

## Why

A trial verdict read from the numbers alone had nothing to compare them with. And an agent with network access can fetch the answer instead of earning it (a published agent-harness study saw a run download its own grading rubric unprompted).

## How to apply

1. Merge the listed files; project edits to the agent files stay, add the one rule to each.
2. For a trial already running, add a Baseline section from the last prune's numbers. No other change.
