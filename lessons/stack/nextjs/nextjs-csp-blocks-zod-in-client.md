---
id: nextjs-csp-blocks-zod-in-client
title: Client code imports only eval-free entry points under a strict CSP
kind: rule
target: project/PROJECT.md
tags: { stack: [nextjs, zod], service: [], area: [security, csp] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Client code imports only eval-free entry points under a strict CSP

## Rule

With a `script-src` that omits `unsafe-eval`, Zod 4's `Function` probe is blocked in the browser, so client components import runtime values only from entry points that don't pull in Zod; type-only imports are fine.

## Why

A client bundle that imported the schema index broke under the production CSP.

## How to check

Grep client components for runtime imports from the schema index.
