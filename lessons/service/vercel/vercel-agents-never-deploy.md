---
id: vercel-agents-never-deploy
title: Agents never deploy
kind: rule
target: .claude/settings.json
in_template: true
tags: { stack: [], service: [vercel], area: [safety, release] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Agents never deploy

## Rule

The Git integration builds the integration and production branches; agents don't deploy or promote, and a missing preview is the owner's call.

## Why

Deployment counts are capped per day on small tiers, and a deploy is a shared-environment change.

## How to check

Deploy tools are denied or absent in settings.
