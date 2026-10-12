---
id: progress-updated-at-each-phase
title: Keep progress.md current during long work
kind: agent-rule
target: harness/agents/fullstack-engineer.md
in_template: true
tags: { stack: [], service: [], area: [process, agents] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Keep progress.md current during long work

## Rule

The Full-stack engineer updates `progress.md` at each phase commit and before any run longer than ten minutes.

## Why

A relaunched agent can only resume from what the file says; a stale file meant redone phases.

## How to check

The modified time of `progress.md` is recent whenever the agent is mid-run.
