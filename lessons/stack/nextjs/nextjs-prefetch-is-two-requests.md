---
id: nextjs-prefetch-is-two-requests
title: Wait for the page-data prefetch, not only the tree
kind: testing-rule
target: project/TESTING.md
in_template: true
tags: { stack: [nextjs, playwright], service: [], area: [e2e, testing] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Wait for the page-data prefetch, not only the tree

## Rule

A prefetch is two requests, the route tree and then the page data. A loading-state test waits for the page-data response (the one without the segment-prefetch tree header) before clicking; waiting for the tree alone races.

## Why

One racy loading-state spec cost a rework round.

## How to check

Grep loading-state specs for the page-data wait.
