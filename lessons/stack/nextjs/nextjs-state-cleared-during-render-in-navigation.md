---
id: nextjs-state-cleared-during-render-in-navigation
title: State cleared during render can drop in a suspended navigation
kind: checklist-item
target: project/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [nextjs, react], service: [], area: [ui, routing] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# State cleared during render can drop in a suspended navigation

## Rule

A React pattern that clears stale state during render, copied into a component that renders during a route change (anything that reads the pathname under a shared layout), is marked to confirm: the router renders it with the new path inside a suspended navigation and React can drop its queued updates.

## Why

A navigation bug only showed mid-transition.

## How to check

Grep the copied pattern's target for pathname reads under the layout.
