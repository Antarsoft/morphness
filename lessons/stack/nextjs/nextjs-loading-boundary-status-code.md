---
id: nextjs-loading-boundary-status-code
title: A loading boundary fixes the status code at 200
kind: checklist-item
target: project/PLAN_CHECKLIST.md
tags: { stack: [nextjs], service: [], area: [routing, seo] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# A loading boundary fixes the status code at 200

## Rule

A plan that adds `loading`, `error`, `not-found` or `layout` files states the status-code effect and which pages call `notFound()`. A `loading.tsx` above a page that calls `notFound()` fixes the response at 200 once the shell streams.

## Why

A soft 404 shipped silently until a tenancy test caught it.

## How to check

Grep `notFound(` under every segment that gains a `loading.tsx`.
