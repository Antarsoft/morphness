---
id: nextjs-rethrow-in-try-catch
title: A try/catch around request APIs rethrows framework errors
kind: rule
target: project/STACK.md
tags: { stack: [nextjs], service: [], area: [routing] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# A try/catch around request APIs rethrows framework errors

## Rule

A `try/catch` around `cookies()`, `headers()`, `redirect()` or `notFound()` calls `unstable_rethrow` (or rethrows framework errors) first in the catch.

## Why

Catching the framework's control-flow errors silently broke redirects and dynamic rendering.

## How to check

Grep `catch` blocks near these calls for the rethrow.
