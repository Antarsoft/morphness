---
id: 2026-11-01-lessons-ledger
title: The config records lessons you declined or put off, and the release a copy taken from the default branch came from
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
removed: []
---

## What changed

- `harness.config.yml` → `installed_from` has a `lessons: { declined: [], deferred: [] }` line. `/morph-update` records there the community lessons you decline or answer "later" for. Before, a lesson put off for later was never offered again, because the next run only lists lessons added after the commit it last synced to, and a declined one had no record at all.
- The comment above `installed_from` says what a release such as `v0.15.0+ce3921d` means: a copy taken from the default branch after that release. `/morph-init` now records that form instead of the bare release name when its source isn't a release tag.

## Why

The kit's audit found that lessons answered "later" were lost after one update, and that an install taken from the default branch recorded a release label that didn't match its content.

## How to apply

In `harness.config.yml` → `installed_from`, add the line `  lessons: { declined: [], deferred: [] }   # lesson ids` under `updates:`, and replace the comment lines above `installed_from:` that start at `# release:` with the kit's four. `/morph-update` adds the line itself on its next run when it is missing; nothing else to do.
