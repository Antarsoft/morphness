---
id: playwright-fulfill-204-for-pending-form-post
title: Freeze a native form post with a 204
kind: testing-rule
target: harness/modules/browser-e2e/README.md
in_template: true
tags: { stack: [playwright], service: [], area: [e2e] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Freeze a native form post with a 204

## Rule

A pending-state test for a native form post answers the POST with `route.fulfill({ status: 204 })` so the page stays pending; holding the route open blocks in-page queries (count, evaluate, scans) in Chromium.

## Why

A held route hung the dev and QA runs.

## How to check

Grep pending-state specs for held native posts.
