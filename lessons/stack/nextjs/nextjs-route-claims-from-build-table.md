---
id: nextjs-route-claims-from-build-table
title: Static or dynamic route claims cite the build's route table
kind: checklist-item
target: project/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [nextjs], service: [], area: [routing, performance] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Static or dynamic route claims cite the build's route table

## Rule

A plan claim that a route is static or dynamic cites the route table of a baseline production build, not a grep for `cookies()` or `headers()`. Before a baseline build it is marked to confirm.

## Why

Grep-based route claims were wrong twice; build-table citations held in four later plans.

## How to check

The plan quotes the build's route table line for each route claim.
