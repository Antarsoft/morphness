---
id: supabase-auth-behaviour-checked-locally
title: Check auth responses on the local stack before writing ACs
kind: checklist-item
target: project/PLAN_CHECKLIST.md
tags: { stack: [], service: [supabase], area: [auth] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Check auth responses on the local stack before writing ACs

## Rule

Before writing an AC about sign-up, sign-in or reset responses, check how the auth service answers for unknown, confirmed and unconfirmed addresses on the local stack.

## Why

Auth answers differ by account state in ways the docs don't spell out.

## How to check

The plan quotes the local responses.
