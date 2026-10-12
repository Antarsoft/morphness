---
id: smoke-run-new-subagent
title: Smoke-run a new subagent file
kind: rule
target: harness/SETUP.md
tags: { stack: [], service: [], area: [agents] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Smoke-run a new subagent file

## Rule

After adding or changing a subagent definition, run it once on a trivial task and confirm the model and effort it reports.

## Why

A subagent file can load with a different model than intended, and nothing else surfaces it.

## How to check

The smoke run's reported model matches the file.
