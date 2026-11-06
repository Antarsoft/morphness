---
id: 2026-11-06-guard-docs-env-ref
title: GUARD.md lists the environment-branch moves the guard asks about
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/GUARD.md
removed: []
reviewed: "It adds one clause to the Asks list in harness/GUARD.md describing what scripts/guard.sh already does; no setting, guard rule, permission or config value changes."
---

## What changed

- **`harness/GUARD.md` § Asks** names the commands that move an environment branch in the local clone: `git update-ref` on it, `git update-ref --stdin`, a `git fetch` refspec that writes it, and `git checkout -B` or `git switch -C` with its name.

## Why

The guard asks about these since 2026-11-06-guard-env-ref-moves; the doc that lists what it asks about didn't say so.

## How to apply

1. Merge the clause into the `git reset --hard` item of § Asks in `harness/GUARD.md`.

## Skip if

You haven't taken 2026-11-06-guard-env-ref-moves yet.
