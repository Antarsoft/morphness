---
id: supabase-local-stack-db-wait
title: The local stack waits for a healthy database
kind: rule
target: project/STACK.md
tags: { stack: [], service: [supabase], area: [tooling] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# The local stack waits for a healthy database

## Rule

The local stack script retries the start and waits for the database to answer before migrating.

## Why

Migrations raced the database start and failed intermittently.

## How to check

None; built into the stack script.
