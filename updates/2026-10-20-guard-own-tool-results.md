---
id: 2026-10-20-guard-own-tool-results
title: The guard no longer asks to read its own saved output, or on two substitutions in one echo
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - AGENTS.md
removed: []
---

## What changed

- `scripts/guard.sh` lets reads of this project's own `~/.claude/projects/<project>/<session>/tool-results/` folder through (the Read tool, Grep, and `cat`, `head`, `tail`, `sed` without `-i`, `grep`, `rg`, `ls` and similar). That folder holds the output Claude Code saved when a call printed too much. A write, a redirect into it, another project's folder and every other path under `~/.claude` still ask.
- A command with two substitutions after other words (`echo $r $(cat a) $(cat b)`) no longer asks "builds the command name at run time". The second `$(` was read as a command named `$`.
- `AGENTS.md` § Permissions for this project names the exception.

## Why

Claude Code saves long tool output under `~/.claude`, and the agent has to read it back to continue. Every such read prompted, as did simple status loops with two substitutions.

## How to apply

1. Merge `scripts/guard.sh`.
2. Update the `~/.claude` line in `AGENTS.md` § Permissions for this project from the template.

## Skip if

The owner wants every read under `~/.claude` to ask.
