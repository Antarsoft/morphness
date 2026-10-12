---
id: supabase-auth-sessions-ip-is-server
title: Auth session IPs are the server's when the server signs in
kind: rule
target: harness/modules/legal/README.md
in_template: true
tags: { stack: [], service: [supabase], area: [privacy] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Auth session IPs are the server's when the server signs in

## Rule

`auth.sessions` has IP and browser columns, but when the server creates sessions the values are the server's; privacy wording cites a sample of recorded values, not the column list.

## Why

A privacy sentence claimed user IPs were stored when they weren't.

## How to check

Query a sample of session rows before writing the sentence.
