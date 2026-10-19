---
id: background-agent-signs-of-life
title: Wait for a background agent's notification, don't poll it
kind: rule
target: harness/TECHNICAL_LEAD.md
in_template: true
tags: { stack: [], service: [], area: [process, agents] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Wait for a background agent's notification, don't poll it

## Rule

After launching a background agent, end the turn and wait for its completion notification. Relaunch one that reports a failure or a stop with a resume prompt.

## Why

A polling check is a full turn over the thread's context every time it runs, so a long build costs far more than the one notification that says it ended.

## How to check

No scheduled check exists while an agent runs; the hand-off follows the agent's notification.
