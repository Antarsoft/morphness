---
id: chromium-range-input-before-focus
title: A range input's first event fires before focus moves
kind: rule
target: project/STACK.md
tags: { stack: [chromium], service: [], area: [ui, input] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# A range input's first event fires before focus moves

## Rule

In Chromium the first `input` event of a range control fires before focus moves to it, so code that reads the focused element keeps a last-pointerdown fallback.

## Why

A slider edit applied to the previously focused element.

## How to check

Grep range handlers that read the active element.
