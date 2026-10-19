---
id: 2026-10-19-guard-fail-closed
title: The guard blocks when it cannot run
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - harness.config.yml
removed: []
---

## What changed

`scripts/guard.sh` let every call through when `python3` was missing, when `scripts/lib/config.sh`
could not be read, when its project folder could not be entered and when the hook input was not valid
JSON. It now exits 2 with the reason in all four cases, and also when the script itself crashes, so a
broken guard stops the call instead of silently passing it. The input check only accepts a JSON
object. A machine that cannot have `python3` can opt out: `guard: { fail_open: true }` in
`harness.config.yml` lets calls through when `python3` is missing (the other cases still block).
`/morph-doctor` now says the guard blocks without `python3` instead of passing.

## Why

On a machine without `python3` (a fresh minimal container, macOS without developer tools) the README
promised a guard and every call passed, with no message. A guard that is off should say so.

## How to apply

Merge the `guard_closed` function, the `python3` check and the exit-code handling at the end of
`scripts/guard.sh`, and add the `fail_open` line to the comment above `guard:` in
`harness.config.yml`. Install `python3` if the guard now blocks every call.

## Skip if

Never; it is a fix.
