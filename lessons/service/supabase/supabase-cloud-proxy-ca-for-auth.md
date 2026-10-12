---
id: supabase-cloud-proxy-ca-for-auth
title: Give the local auth container the session's CA bundle
kind: rule
target: project/STACK.md
tags: { stack: [], service: [supabase], area: [tooling, cloud] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Give the local auth container the session's CA bundle

## Rule

In a cloud session behind a TLS proxy, the local auth container needs the session's CA bundle to fetch OAuth discovery documents; copy it in and restart the container, with verification still on.

## Why

OAuth sign-in failed locally with an x509 error.

## How to check

None; built into the stack script.
