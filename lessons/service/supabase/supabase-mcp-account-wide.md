---
id: supabase-mcp-account-wide
title: The Supabase MCP is account-wide
kind: agent-rule
target: project/SKILLS_AND_MCPS.md
in_template: true
tags: { stack: [], service: [supabase], area: [safety] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# The Supabase MCP is account-wide

## Rule

The Supabase connector can see every project on the account, so every call names the project ref of the intended environment, and agents use it read-only.

## Why

A call without a ref can target the wrong project.

## How to check

Grep QA records for MCP calls without the project ref.
