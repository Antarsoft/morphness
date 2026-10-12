---
id: playwright-locator-handler-for-overlays
title: Close recurring overlays in the shared fixture
kind: testing-rule
target: harness/modules/browser-e2e/README.md
tags: { stack: [playwright], service: [], area: [e2e] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Close recurring overlays in the shared fixture

## Rule

An overlay that can appear on any page (a tour, a banner) is closed by one `page.addLocatorHandler` in the shared fixture, not per spec.

## Why

Adding a tour would otherwise have touched every spec that visits those pages.

## How to check

Grep the fixture for the handler when a plan adds a global overlay.
