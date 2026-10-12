---
id: parallel-agents-separate-local-stack
title: Parallel agents don't share one local stack
kind: rule
target: project/HARNESS_AGENTS.md
in_template: true
tags: { stack: [], service: [], area: [agents, data] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Parallel agents don't share one local stack

## Rule

Two agents running at once never use the same local database stack, container daemon or app port; a lock or a named owner decides who runs. Worktree-isolated agents start from the base commit, so pass absolute plan paths and merge their branch back before QA.

## Why

Two agents on one container daemon can corrupt each other's runs; a stale server on the app port invalidated a 12-minute run.

## How to check

Handoff prompts name the stack lock and check the port is free before the suite.
