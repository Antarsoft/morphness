---
id: supabase-prod-migration-role-before-release
title: Create the production migration role before the first release
kind: rule
target: project/RELEASE.md
tags: { stack: [], service: [supabase], area: [release] }
evidence: { fired: 1, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Create the production migration role before the first release

## Rule

Before the first release PR, the owner creates the read-only migration role in production and copies the exact pooler host from the Connect screen.

## Why

The first production dry run failed five times on setup, not code.

## How to check

The release checklist has the role and host as human steps.
