---
id: supabase-local-target-guard
title: Local stack scripts refuse non-local URLs
kind: agent-rule
target: harness/modules/data-access/README.md
in_template: true
tags: { stack: [], service: [supabase], area: [safety, data] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Local stack scripts refuse non-local URLs

## Rule

Migration, seed and QA scripts refuse to run unless the database URL and the Supabase URL point to localhost; `--env-file` does not override variables already set in the session.

## Why

A QA script reached DEV with anonymous calls because session variables won.

## How to check

The guard runs before the first data call.
