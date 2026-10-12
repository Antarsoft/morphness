---
id: paddle-verify-webhook-signatures
title: Verify Paddle webhook signatures
kind: testing-rule
target: project/TESTING.md
in_template: true
tags: { stack: [], service: [paddle], area: [billing, security] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Verify Paddle webhook signatures

## Rule

Webhook handlers verify the signature before reading the payload, and tests cover the rejection paths without live keys.

## Why

An unverified webhook lets anyone change billing state.

## How to check

Tests for valid, missing and wrong signatures exist.
