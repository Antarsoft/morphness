---
id: 2026-10-31-guard-fails-closed
title: The guard blocks the call when it can't run or runs too long
kind: fix
release: v0.15.0
applies_to: { modules: [] }
files:
  - .claude/settings.json
  - scripts/guard.sh
  - AGENTS.md
removed: []
---

## What changed

- The guard hook command in `.claude/settings.json` (PreToolUse and ConfigChange) now turns every exit other than 0 and 2 into a block, so a missing `scripts/guard.sh`, a missing `bash` or an unset `CLAUDE_PROJECT_DIR` blocks the call with a message instead of letting it through. Both entries get `"timeout": 60`.
- `scripts/guard.sh` ends its own check after 15 seconds and blocks the call, well below the hook timeout. A `git` call that doesn't answer within 5 seconds now blocks the call too: before, its empty answer read as "not on an environment branch", so a bare `git push` on `main` passed.
- A long argument list no longer slows the guard down: one check ran once per argument, so `cat` with 20,000 arguments took minutes. It now takes about a second.
- `AGENTS.md` § Permissions for this project names the missing script and the 15-second limit under **Denies**, and says under **What it does not see** that Claude Code runs a call when the hook itself hangs past its timeout. A few lines of that section are worded shorter so the always-loaded text stays the same size.

## Why

Claude Code blocks a tool call only when the hook exits 2. When `scripts/guard.sh` was missing, bash exited 127 and every call ran with no check and no visible error. When the hook ran past Claude Code's hook timeout, the call ran too, and a long enough command made the guard that slow. A `git` that hung made the guard read the current branch as none.

## How to apply

1. In `.claude/settings.json` → `hooks.PreToolUse` and `hooks.ConfigChange`, replace the guard entry's `command` with the template's and add `"timeout": 60`. Keep any other hook entries the project added.
2. Take the kit's `scripts/guard.sh`, or merge its changes: the `too_slow` watchdog after the imports, the `TimeoutExpired` deny in `git_out`, and `redirects` / `reads_only` computed once before the per-word loop in `check_bash`.
3. Bring `AGENTS.md` § Permissions for this project in line with the template: the **Denies** line for a guard that can't run, the hook timeout under **What it does not see**, and the shorter wording of that section (same rules, fewer words, so the always-loaded text doesn't grow).

## Skip if

Never: it closes a gap in the guard.
