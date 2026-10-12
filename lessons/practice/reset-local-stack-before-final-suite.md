---
id: reset-local-stack-before-final-suite
title: Reset the local stack before the final full run
kind: agent-rule
target: harness/agents/qa-engineer.md
tags: { stack: [], service: [], area: [qa, data] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Reset the local stack before the final full run

## Rule

When a feature changes seed-derived values, QA resets the local stack before the final full browser suite.

## Why

Leftover rows from earlier runs made tests fail only on a reused stack, which looked like flakes.

## How to check

`qa-result.md` records the reset before the final run.
