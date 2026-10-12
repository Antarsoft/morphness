---
id: playwright-fixture-fails-on-csp-and-page-errors
title: The shared test fixture fails on CSP violations and page errors
kind: testing-rule
target: harness/modules/browser-e2e/README.md
in_template: true
tags: { stack: [playwright], service: [], area: [e2e, csp] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# The shared test fixture fails on CSP violations and page errors

## Rule

Every spec uses the shared `test` from the fixtures file, which fails the test on a content-security-policy violation or an uncaught page error.

## Why

CSP-blocked scripts fail silently in the browser and otherwise pass every assertion.

## How to check

Grep specs for imports of the bare runner instead of the fixture.
