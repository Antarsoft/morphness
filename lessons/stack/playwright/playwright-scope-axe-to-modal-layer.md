---
id: playwright-scope-axe-to-modal-layer
title: Scope accessibility scans to an open modal layer
kind: testing-rule
target: harness/modules/browser-e2e/README.md
in_template: true
tags: { stack: [playwright], service: [], area: [a11y, e2e] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Scope accessibility scans to an open modal layer

## Rule

A page or item inside an open menu or dialog is scanned with the scan scoped to that layer (`include` the menu or dialog role): the modal layer aria-hides the rest of the page, so a page-wide scan passes on nothing.

## Why

An a11y check of a menu item passed on an empty scan.

## How to check

Grep a11y specs for open-menu states without an include scope.
