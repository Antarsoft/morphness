---
id: playwright-exact-name-locators
title: Role locators match names as substrings
kind: checklist-item
target: harness/modules/browser-e2e/README.md
in_template: true
tags: { stack: [playwright], service: [], area: [e2e, locators] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Role locators match names as substrings

## Rule

When a new control's accessible name contains an existing control's name, grep specs for `getByRole(…, { name })` without `exact: true`; Playwright matches names as substrings.

## Why

A new "New experiment in <project>" button made four specs' locators ambiguous.

## How to check

Grep non-exact name locators for the existing name.
