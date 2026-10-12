---
id: supabase-deny-remote-writes
title: Deny agent writes to remote Supabase projects
kind: rule
target: .claude/settings.json
in_template: true
tags: { stack: [], service: [supabase], area: [safety, data] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Deny agent writes to remote Supabase projects

## Rule

Deny MCP tools that apply migrations, manage branches, create, pause or restore projects or deploy functions, and Bash patterns for `db push`, `supabase link`, `drizzle-kit push` and the migrate scripts. Put SQL execution on `ask`. Migrations reach shared environments only through workflows or the owner.

## Why

An agent with write access to a shared database can change it irreversibly from a chat.

## How to check

The deny and ask lists in `.claude/settings.json` contain each tool and pattern.
