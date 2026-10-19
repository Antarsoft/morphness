---
id: background-agent-signs-of-life
title: Check a background agent for signs of life
kind: rule
target: harness/TECHNICAL_LEAD.md
in_template: true
tags: { stack: [], service: [], area: [process, agents] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Check a background agent for signs of life

## Rule

After launching a background agent, schedule a check every 10 minutes in the same turn: one shell command (`git status --short` plus the modified time of `progress.md`). Relaunch an agent that has gone silent with a resume prompt; delete the schedule at hand-back.

## Why

An agent stalled silently for about two hours before anyone looked.

## How to check

A scheduled check exists while an agent runs and is removed at hand-back.
