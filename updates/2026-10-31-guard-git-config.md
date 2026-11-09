---
id: 2026-10-31-guard-git-config
title: The guard asks before git config sets a command git runs later
kind: fix
release: v0.15.0
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - AGENTS.md
removed: []
---

## What changed

- `scripts/guard.sh` asks before `git config`, `git -c` or `git --config-env` sets a key whose value git runs or reads later: `core.hooksPath`, `core.sshCommand`, `core.pager`, `core.editor`, `core.fsmonitor`, `credential.helper`, `alias.*`, `pager.*`, `filter.*.clean|smudge|process`, `diff.external`, `include.path`, `submodule.*.update` and similar keys, in any letter case and with `--global`, `-f <file>` or the `git config set` form. A section renamed into one of these (`--rename-section x alias`), a key built at run time (`git config $K …`), `git clone -c` / `--config` and `git clone|init --template` ask too. Reading a key (`--get`, a key with no value, `--list`, unless a `--no-…` flag cancels it) and removing one (`--unset`, `--remove-section`) still run, and so do `git -c core.editor=true …` and `git -c core.pager=cat …`, which only keep git quiet.
- `AGENTS.md` § Permissions for this project lists it under **Asks**.

## Why

`git config core.hooksPath /tmp/x`, `git config alias.p '!git push origin main'` or `git -c core.sshCommand=… fetch` passed with no check, and the next git call then ran a command the guard never saw, or pushed under a name (`git p`) it didn't recognise.

## How to apply

1. Merge `scripts/guard.sh`: `--config-env` in `GIT_OPTS_WITH_VALUE`, the `CMD_CONFIG_KEYS`, `QUIET_VALUE`, `CONFIG_READS`, `config_ask`, `check_config_key` and `check_config_section` block after it, the key and section checks in the `git config` branch of `follow_git` and its new `clone`/`init`/`submodule` branch, and the `-c` / `--config-env` check in the option loop of `check_git`.
2. Add the item to `AGENTS.md` § Permissions for this project → **Asks**, on the `git reset --hard` line.

## Skip if

Never: it closes a gap in the guard.
