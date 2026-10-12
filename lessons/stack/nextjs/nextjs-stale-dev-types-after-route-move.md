---
id: nextjs-stale-dev-types-after-route-move
title: Delete stale dev types after moving routes
kind: rule
target: project/STACK.md
tags: { stack: [nextjs], service: [], area: [tooling] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Delete stale dev types after moving routes

## Rule

After moving or renaming routes, a typecheck that fails with TS2307 on old page paths comes from stale generated types under `.next/dev`; delete that folder (it is generated) or run the dev server once.

## Why

The error points at files that no longer exist and cost a confusing diagnosis.

## How to check

None; a note in the stack doc.
