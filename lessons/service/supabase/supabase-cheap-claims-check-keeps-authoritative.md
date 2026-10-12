---
id: supabase-cheap-claims-check-keeps-authoritative
title: A cheaper session check keeps the authoritative one where it matters
kind: rule
target: project/STACK.md
tags: { stack: [], service: [supabase], area: [auth, performance] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# A cheaper session check keeps the authoritative one where it matters

## Rule

Replacing a user lookup with a local claims check in middleware keeps the authoritative check on login and sign-up pages, or a revoked session loops between them.

## Why

A revoked session redirected forever after a latency fix.

## How to check

Grep auth pages for the authoritative check.
