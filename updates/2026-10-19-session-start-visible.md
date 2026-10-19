---
id: 2026-10-19-session-start-visible
title: Session start shows its commands, times out and skips dependency scripts
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/session-start.sh
removed: []
---

## What changed

`scripts/session-start.sh` no longer runs the toolchain setup and the dependency install silently.
It prints each command before it runs, runs it under a timeout (300 seconds, or
`MORPHNESS_START_TIMEOUT`), and when it fails or times out prints the command and the last 15 lines of
its output. An install by `npm`, `pnpm`, `bun` or `yarn` 1 gets `--ignore-scripts`, so the lifecycle
scripts of a dependency don't run at session start. The script still never fails the session start.

## Why

A hanging install blocked the session with no output, a failed one printed a single easy-to-miss line,
and a dependency's install script ran with nothing shown. Anyone who checks out a branch and opens
Claude Code runs this script, so what it runs has to be visible.

## How to apply

Copy `scripts/session-start.sh` from the kit, then put the project's own two commands back into the
`TOOLCHAIN_SETUP` and `INSTALL_CMD` lines (from `project/STACK.md`). If an install needs its scripts
(a native module build), add `--ignore-scripts=false` to `install_cmd` in `harness.config.yml` and the
script; the flag you write is kept.

## Skip if

The project already replaced `scripts/session-start.sh` with its own version that shows its output.
