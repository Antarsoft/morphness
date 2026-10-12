---
id: full-suite-in-background-with-long-limit
title: Run the full suite in the background with a long limit
kind: agent-rule
target: harness/HANDOFFS.md
in_template: true
tags: { stack: [], service: [], area: [tooling, agents] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Run the full suite in the background with a long limit

## Rule

Agents start the full browser suite in the background with a limit of an hour or more and wait for it in the same turn; a run is reported only once its exit file exists.

## Why

Foreground runs hit the command timeout and were cut off; environment failures dropped from seven to none in the next window after this rule.

## How to check

The handoff prompt sets the long limit; the exit file is newer than the run's start.
