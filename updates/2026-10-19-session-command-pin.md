---
id: 2026-10-19-session-command-pin
title: A changed session-start command waits for the owner
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/session-start.sh
  - .claude/settings.json
removed: []
---

## What changed

`scripts/session-start.sh` records the toolchain and install commands in the clone's git folder
(`morphness-session-commands`) the first time it runs. When a later session finds different commands
(a pulled branch edited them), it runs nothing, prints the old and new commands, and tells the agent to
ask the owner. Only after the owner says yes does `bash scripts/session-start.sh --accept` record the new
commands and run them. `.claude/settings.json` gets an `ask` rule for that command.

## Why

Any maintainer who checks out a branch and opens Claude Code runs the commands in that branch's
`session-start.sh`. A pull request that edits them would otherwise run on the next session start.
The pin protects a clone that has run the script before; a fresh clone has no pin, so its first run
rests on Claude Code's trust prompt for the folder.

## How to apply

Copy `scripts/session-start.sh` from the kit (this note builds on `2026-10-19-session-start-visible`),
put the project's two commands back into its `TOOLCHAIN_SETUP` and `INSTALL_CMD` lines, and add
`"Bash(*session-start.sh --accept*)"` to `permissions.ask` in `.claude/settings.json`.

## Skip if

The project replaced `scripts/session-start.sh` with its own version or removed the SessionStart hook.
