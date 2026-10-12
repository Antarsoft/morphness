---
id: nextjs-grep-every-header-source
title: Grep every header source in the config
kind: checklist-item
target: project/PLAN_CHECKLIST.md
tags: { stack: [nextjs], service: [], area: [security, csp] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Grep every header source in the config

## Rule

A plan that says a route gets "the same headers as the rest" greps every `headers()` source in the framework config; some routes have their own.

## Why

A payment route had its own header source that the plan had missed.

## How to check

List each `headers()` entry and the routes it covers.
