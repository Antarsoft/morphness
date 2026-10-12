---
id: icon-toggle-keeps-both-icons-mounted
title: An icon toggle keeps both icons mounted
kind: rule
target: project/PROJECT.md
tags: { stack: [], service: [], area: [ui] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# An icon toggle keeps both icons mounted

## Rule

A toggle that swaps icons keeps both mounted and hides the inactive one; it never replaces the element under the pointer.

## Why

Swapping the element under the pointer broke hover state and froze a carousel, costing a QA round.

## How to check

Grep the toggle for conditional rendering of the icon element.
