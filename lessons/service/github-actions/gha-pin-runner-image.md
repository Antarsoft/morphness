---
id: gha-pin-runner-image
title: Pin the runner image
kind: rule
target: project/CONTROLS.md
tags: { stack: [], service: [github-actions], area: [ci] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Pin the runner image

## Rule

CI pins the runner image version instead of `-latest` and moves it in its own PR.

## Why

An unannounced image change breaks unrelated PRs.

## How to check

Grep workflows for `-latest`.
