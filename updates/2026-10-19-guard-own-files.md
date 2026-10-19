---
id: 2026-10-19-guard-own-files
title: The guard protects its own files
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - .claude/settings.json
removed: []
---

## What changed

A `Write` or `Edit` to `scripts/guard.sh` passed the guard and took effect on the next call, so one
injected edit switched every control off. `scripts/guard.sh` now asks the owner before any change to
the files it rests on: `scripts/guard.sh`, `scripts/session-start.sh`, `scripts/lib/`,
`.claude/settings.json` and `harness.config.yml`. It catches the Edit, Write and MultiEdit tools and
the Bash forms (a redirect, `sed -i`, `cp`, `mv`, `rm`, `chmod`, `tee`, `ln`, `git restore`,
`git update-index`, an interpreter one-liner naming the file, a path reached after a `cd`).
`.claude/settings.local.json` is denied outright: it is the owner's file, and an agent that could
write it could grant itself permissions that never show in a PR. A new `ConfigChange` hook in
`.claude/settings.json` runs the same script and blocks a mid-session change to the local settings.

These are asks, not denies, on purpose: `/morph-init`, `/morph-update` and the retro change
`harness.config.yml` and `.claude/settings.json` on the owner's yes, and the prompt shows the owner
each change.

## Why

A hostile-audit probe wrote `exit 0` to `scripts/guard.sh`, `{}` to `.claude/settings.json` and a
download-and-run line to `scripts/session-start.sh`; every call passed.

## How to apply

Merge the "guard files" block, the Bash write check and the `ConfigChange` branch in
`scripts/guard.sh`, and add the `ConfigChange` entry under `hooks` in `.claude/settings.json` (same
command as the PreToolUse hook). Nothing to render. Approve the prompts that follow when you or the
harness edit those files.

## Skip if

Never; it is a fix.
