---
id: playwright-pin-timezone
title: Pin browser and unit-test time zones
kind: testing-rule
target: project/TESTING.md
tags: { stack: [playwright, vitest], service: [], area: [testing, time] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Pin browser and unit-test time zones

## Rule

Browser tests and unit tests pin the time zone (UTC) in their configs, so date formatting tests don't depend on the machine.

## Why

Local-time formatting tests passed or failed with the runner's zone.

## How to check

Grep both configs for the pinned zone.
