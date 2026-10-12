---
id: nextjs-server-actions-accept-no-origin
title: Server actions accept a POST without an Origin header
kind: rule
target: project/STACK.md
tags: { stack: [nextjs], service: [], area: [security] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Server actions accept a POST without an Origin header

## Rule

Server actions accept a POST with no `Origin` header (the framework only warns). A plan that relies on origin checks for an action adds its own check.

## Why

A security assumption about built-in origin checks didn't hold for header-less requests.

## How to check

Plans with sensitive actions name where origin or CSRF is verified.
