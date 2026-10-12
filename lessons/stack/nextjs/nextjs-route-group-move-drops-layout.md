---
id: nextjs-route-group-move-drops-layout
title: Moving a page to its own route group drops the parent layout
kind: rule
target: project/STACK.md
tags: { stack: [nextjs], service: [], area: [routing, performance] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Moving a page to its own route group drops the parent layout

## Rule

A page moved to its own route group keeps its URL and no longer runs the parent layout's queries and providers; the plan lists what the old layout supplied.

## Why

Moving a page out of the dashboard group removed queries it didn't need, but also anything else the layout provided.

## How to check

List the parent layout's data and providers in the plan.
