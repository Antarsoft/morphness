---
id: 2026-10-21-harness-schema
title: harness_schema key records the config and records layout version
kind: config
release: v0.13.0
applies_to: { modules: [] }
files:
  - harness.config.yml
removed: []
---

## What changed

`harness.config.yml` has a new top-level key, `harness_schema: 1`, with a comment above it. It names the version of the config keys and `_harness/` record formats this copy follows (STABILITY.md in the Morphness repo). `/morph-doctor` checks it.

## Why

From 1.0, a change to the stable surface comes only with a major release and a migration note. The number lets the doctor and later updates tell which layout a copy is on without guessing from its files.

## How to apply

1. Add the comment and `harness_schema: 1` to `harness.config.yml`, after the header comment and before `project:`.
2. Run `/morph-doctor`; the Schema line should pass.

## Skip if

Never: every copy needs the number for later updates.
