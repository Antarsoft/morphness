---
id: 2026-10-31-guard-one-yes
title: One approval can no longer switch a guard protection off
kind: fix
release: v0.15.0
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - AGENTS.md
removed: []
---

## What changed

- `scripts/guard.sh` and `scripts/lib/` are denied to every tool call that writes them: Write, Edit, a redirect, `rm`, `chmod` on the file, `sed -i`, an interpreter one-liner (also with spaces around the path), `git checkout|restore|update-index` (also under `git -C scripts`), and now also writes that ran with no prompt before: `cp`, `mv`, `install` or `rsync` into `scripts/` (also `cp -t`, `cp -rT dir .`, `rsync -a dir/ .`, where the guard looks inside the source folder), `ln` to them (a write through the link), `curl -o|-O` and `wget` (by the remote file name, `-P` and `--output-dir` too), `git apply`, `git am` and `patch` (the patch file is read; a patch from a pipe asks), `tar -x` and `unzip` (the archive is listed; one that can't be listed asks), `git checkout <commit> -- <paths>`, `git restore --source` and `git stash pop|apply` when they would bring another copy of a guarded file. Removing or moving `scripts/`, `scripts/lib/` or `.claude/` is denied too. A new file in `scripts/` or `scripts/lib/` is fine. The message tells the agent to leave a new copy under `/tmp` and give the owner the `cp` command.
- `.claude/settings.json` and `harness.config.yml` change through Edit or Write only. The guard works out the file after the change and denies it when it drops a protection: for settings, the guard hook removed, narrowed (matcher, also one that is not a valid pattern), changed (command or type) or given a timeout under 30 s, any `disableAllHooks` value but `false`, a deny or ask rule removed, `defaultMode: bypassPermissions`, any `env` entry (every variable reaches the hook), a new or changed hook or helper command (`statusLine`, `apiKeyHelper` …), or a file Claude Code would not read (`NaN`, deep nesting); for the config, a `guard:` switch turned off, `pr_writes` from ask to allow, a new `allow_hosts` entry, `fail_open: true`, or an environment branch that would no longer be protected. Any other change still asks. A Bash write to either file is denied, because its result can't be worked out.
- `/morph-update` leaves guard file updates for the owner to copy in, and `/morph-doctor` reports a guard that differs from the kit's copy, a missing or changed guard hook, a missing shipped deny rule and every switch that is off.
- `AGENTS.md` § Permissions for this project moves these from the asks to the denies, names a checkout or merge that brings another copy of the guard as a known limit (the doctor check finds it), and words other items shorter with no rule change, to keep the always-loaded text the same size.

## Why

The audit showed that one approved prompt (an edit of `scripts/guard.sh`, of `.claude/settings.json`, or `guard: { network: off }` in the config) removed a protection for every later call, and text written to win that approval is easy to plant in a fetched page or a note.

## How to apply

1. Merge `scripts/guard.sh` last, after every other file in this update: once it is in place it denies writes to itself and to `scripts/lib/`. The changes are the `GUARD_LIB_DIR` and `GUARD_FAIL_OPEN` lines in the prelude, `config_branches(env)`, `switch`, `pr_allow`, `allow_hosts` and `fail_open` taking a config, the file lists (`CORE_FILES`, `HOLDER_DIRS`, `SETTINGS_FILES`, `CONFIG_FILES`, `GUARD_FILES`), `rels_to_root` and `protected_kind`, `read_config`, `config_lost`, `COMMAND_SETTINGS`, `guard_hooks`, `hook_commands`, `matcher_covers`, `settings_lost`, `planned_text`, the new `protect`, `copy_targets`, `patch_paths`, `archive_paths`, `git_globals`, `guarded_files`, `git_restores` and `guard_file_write`, and the file-tool branch of the dispatch.
2. Update `AGENTS.md` § Permissions for this project (the **Denies** item on the owner's file and the guard's own files, the first **Asks** item and **What it does not see**); the other reworded items are optional.
3. Run `/morph-doctor`: its guard integrity check lists anything the owner should restore by hand.

## Skip if

Never: it closes a gap in the guard.
