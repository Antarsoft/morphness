---
id: repeat-timing-sensitive-tests
title: Repeat new timing-sensitive tests before handoff
kind: testing-rule
target: harness/CONTROLS.md
in_template: true
tags: { stack: [], service: [], area: [testing, flaky] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Repeat new timing-sensitive tests before handoff

## Rule

Each new or changed test that uses a fake clock, hover or focus timing is run five times in a row before handoff (the runner's repeat option), and the pass count is recorded.

## Why

A carousel test passed once at handoff and then failed 8 of 11 repeats in QA.

## How to check

`progress.md` lists each timing test with its repeat pass count.
