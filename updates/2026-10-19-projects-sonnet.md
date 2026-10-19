---
id: 2026-10-19-projects-sonnet
title: Advised Claude Projects settings follow the Sonnet default
kind: config
release: unreleased
applies_to: { modules: [claude-projects] }
files:
  - harness.config.yml
  - harness/modules/claude-projects/README.md
removed: []
---

## What changed

The advised Claude Projects settings are now sonnet for the coordinator (medium), feature threads (high)
and one-shot threads (medium), matching the Sonnet default for the agents. The module README adds when
opus at high is still worth it: a review, research or architecture thread that does the hard thinking
itself, or a feature where a missed edge case is costly. With the Opus preset, the advice stays opus.

## Why

The agents already default to Sonnet, with the plan, QA and checks around them. The advice for the
threads that run them still said opus, so the two disagreed.

## How to apply

Optional: these settings live in the Claude app, not the repo, so nothing changes unless you change it
there. To follow the new advice, change the model in the Project's settings, then set
`claude_projects` in `harness.config.yml` to match and merge the table and the paragraph under it in
`harness/modules/claude-projects/README.md`.
