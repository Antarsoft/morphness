---
id: negative-test-proves-regression-test
title: Prove a regression test with a negative test
kind: testing-rule
target: .claude/rules/testing.md
in_template: true
tags: { stack: [], service: [], area: [testing] }
evidence: { fired: 2, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Prove a regression test with a negative test

## Rule

A bug fix's regression test is proven by a negative run: back up the fixed file, restore the bug, run the new test and watch it fail, then restore the fix. Never use `git checkout` or `git stash` for this. Record the run in `progress.md`.

## Why

A regression test that passes with and without the fix guards nothing, and nobody notices until the bug returns.

## How to check

`progress.md` records the negative run with its exit code.
