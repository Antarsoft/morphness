---
id: polling-tests-with-slow-responses
title: Test polling with responses slower than the interval
kind: testing-rule
target: harness/modules/browser-e2e/README.md
in_template: true
tags: { stack: [], service: [], area: [testing, e2e] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Test polling with responses slower than the interval

## Rule

A component that refreshes or fetches on a timer is also tested with each response held past the polling interval, and a poll never starts while the previous one is in flight.

## Why

Locally every response is fast, so an unguarded poll only stalled on a real deploy, where the page stopped redrawing.

## How to check

The spec has a slow-server case that holds the response longer than the interval.
