---
id: tab-return-uses-visibility-change
title: Simulate a tab return with a visibility change
kind: testing-rule
target: harness/modules/browser-e2e/README.md
in_template: true
tags: { stack: [], service: [], area: [testing, e2e, mobile] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Simulate a tab return with a visibility change

## Rule

A page that refreshes when the user comes back from another tab listens for the visibility change and is tested by changing the document's visibility state, not only by a focus event.

## Why

Phones fire only the visibility change when a tab closes, and browser test tools emulate focus, so a focus-only refresh passed every test and failed on every phone.

## How to check

Grep the spec for the visibility-state override next to any focus-based return test.
