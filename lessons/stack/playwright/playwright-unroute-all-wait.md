---
id: playwright-unroute-all-wait
title: Wait for route handlers that read fetched bodies
kind: testing-rule
target: harness/modules/browser-e2e/README.md
tags: { stack: [playwright], service: [], area: [e2e, flaky] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Wait for route handlers that read fetched bodies

## Rule

A route handler that calls `route.fetch()` and reads the body needs `page.unrouteAll({ behavior: "wait" })` at the end of the test.

## Why

A disposed-response race failed 7 of 120 runs before and 0 of 120 after.

## How to check

Grep specs with `route.fetch(` for the unroute wait.
