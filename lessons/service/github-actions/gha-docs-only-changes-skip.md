---
id: gha-docs-only-changes-skip
title: Docs-only changes skip heavy CI jobs and still succeed
kind: rule
target: project/CONTROLS.md
tags: { stack: [], service: [github-actions], area: [ci, cost] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Docs-only changes skip heavy CI jobs and still succeed

## Rule

Each CI job first decides its scope from the changed files; when every file is documentation (an explicit allowlist, no `..` segments), it skips all later steps and concludes success.

## Why

Docs-only PRs burned full CI minutes; QA mutation runs proved the allowlist rules.

## How to check

Unit tests for the scope script cover each allowlist rule.
