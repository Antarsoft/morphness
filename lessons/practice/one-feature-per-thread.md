---
id: one-feature-per-thread
title: One feature, one PR per thread
kind: rule
target: harness/TECHNICAL_LEAD.md
in_template: true
tags: { stack: [], service: [], area: [process, cost] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# One feature, one PR per thread

## Rule

Each thread handles one feature and one PR and is resolved when it merges. Recurring checks get a new thread each time; nothing that needs no action is sent into a thread.

## Why

Every message re-reads the whole thread; long multi-PR threads cost several times more per step than a fresh one.

## How to check

Each merged PR maps to exactly one thread.
