---
id: supabase-explicit-api-grants
title: Grant API roles explicitly; check every relation kind
kind: checklist-item
target: project/PLAN_CHECKLIST.md
tags: { stack: [], service: [supabase], area: [data, security] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Grant API roles explicitly; check every relation kind

## Rule

Don't rely on default privileges for API roles: new public tables grant only what each needs, and tests check every relation kind (tables, views, sequences, functions) and `PUBLIC` execute separately. Check the vendor changelog for announced default changes.

## Why

A planned reliance on a platform default met an announced change; the miss cost about 1.8M tokens.

## How to check

Integration tests assert grants per relation kind.
