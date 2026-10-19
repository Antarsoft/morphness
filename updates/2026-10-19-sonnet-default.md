---
id: 2026-10-19-sonnet-default
title: Sonnet in every role by default, Opus as an install preset
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
removed: []
---

## What changed

New installs default to Sonnet for the Technical Lead, Full-stack and the high researcher, as well
as QA and the default researcher. `/morph-init` offers two presets: All Sonnet (default) and Opus for
planning and building (the previous defaults). The legal writer is unchanged.

## Why

With the plan, QA and checks around it, Sonnet in every role gave the same results as Opus on the
work we compared, at about half the cost. Projects where a missed edge case is expensive can keep
Opus with the preset.

## How to apply

Optional for an installed copy: your models are your choice and nothing changes unless you want it.
To switch, set `model: sonnet` (and `high_model: sonnet` for the researcher) under `agents:` in
`harness.config.yml`, `"model": "sonnet"` in `.claude/settings.json`, and `model: "sonnet"` in each
`.claude/agents/*.md` except `legal-writer.md`, then update the model column in
`project/HARNESS_AGENTS.md`. Try it as a trial first ([harness/MORPHING.md](../template/harness/MORPHING.md) § Trials)
if you want the numbers from your own project.
