---
id: 2026-10-19-guard-docs
title: One description of the guard hook, matching what it does
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - AGENTS.md
  - CLAUDE.md
  - harness/RELEASE.md
  - harness/SKILLS_AND_MCPS.md
  - harness.config.yml
  - scripts/guard.sh
removed: []
---

## What changed

The guard hook was described in five files, each with a different list, and some claims were wider than the
code ("blocks secrets", "well-known remote database writes", "without python3 the guard lets the call
through"). `AGENTS.md` § Permissions for this project is now the one description: what the guard denies,
what it asks, which `guard:` switches turn an ask off, and what it does not see (scripts, interpreters,
`curl | sh`, `ssh`, unlisted CLIs, WebFetch and Glob). `CLAUDE.md`, `harness/RELEASE.md` and
`harness/SKILLS_AND_MCPS.md` link to it, `harness.config.yml` points to it from the `guard:` comment, and the
header of `scripts/guard.sh` no longer repeats the list. `harness/RELEASE.md` also stops saying the guard lets
calls through without python3; it fails closed.

## Why

Two statements of the same control let the model pick the weaker one, and a safety claim that the code does
not back misleads the owner.

## How to apply

Replace the "Permissions for this project" paragraph in `AGENTS.md` with the new section (keep any rules of
your own at its end), swap the guard sentences in `CLAUDE.md`, `harness/RELEASE.md` and
`harness/SKILLS_AND_MCPS.md` for the links, and replace the `guard:` comment in `harness.config.yml` and the
header comment of `scripts/guard.sh`. Text only; no behaviour changes.

## Skip if

Never; it is a correction.
