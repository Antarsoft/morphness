---
id: drizzle-schema-drift-check
title: Fail CI when the schema changes without a migration
kind: rule
target: project/CONTROLS.md
tags: { stack: [drizzle], service: [], area: [data, ci] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Fail CI when the schema changes without a migration

## Rule

A check fails when the schema file changes with no committed migration.

## Why

A schema edit without a generated migration works locally and breaks the next environment.

## How to check

Run the drift check in the before-QA checks.
