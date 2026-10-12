---
id: playwright-headless-shell-glyph-widths
title: Run width ACs in CI's headless shell
kind: testing-rule
target: harness/modules/browser-e2e/README.md
in_template: true
tags: { stack: [playwright], service: [], area: [e2e, layout] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Run width ACs in CI's headless shell

## Rule

A size, overflow or wrapping test is run once under the same headless shell CI uses, which rounds glyph widths differently from the full browser.

## Why

A table was 2 px too wide only on CI.

## How to check

The progress file records one run under the headless shell for each width AC.
