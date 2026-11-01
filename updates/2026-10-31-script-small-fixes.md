---
id: 2026-10-31-script-small-fixes
title: Session start keeps its temp files private, quotes PATH, has a time limit on macOS and names a broken python3
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/session-start.sh
  - harness/README.md
removed: []
---

## What changed

- `scripts/session-start.sh` keeps a step's output in a private folder (`mktemp -d` under `TMPDIR`, mode 700; in the git folder when `mktemp` is missing), never under a guessable name in a shared `/tmp` (the old `/tmp/morphness-start.<pid>` fallback, and the `.path` file next to the temp file) where another user of the machine could plant a link.
- A PATH the toolchain step changed is written to the session's env file quoted (`printf %q`), so a `"`, `$` or backtick in it stays text instead of breaking every later Bash call.
- Without `timeout` or `gtimeout` (stock macOS), perl bounds each step the same way: after `MORPHNESS_START_TIMEOUT` seconds it stops the command and everything it started, and the step reports `timed out`. A TERM, INT or HUP sent to session start reaches the step too. Only with no perl either does it run unbounded (and says so).
- It checks that `python3`, on the PATH the hooks run with, is a working Python 3.7 or later. A stub (macOS before the Command Line Tools are installed, the Microsoft Store alias) or an older Python passes `command -v` but can't run the guard; session start now says so instead of leaving the guard to block every call or let calls through unchecked.
- A failed step's last output line no longer runs into the next message when it doesn't end in a newline.
- `harness/README.md` § Modules: the module removal command handles file paths with spaces (they were split and left unedited) and no longer waits on stdin when no file matches. It exits non-zero when perl fails on any file, and works the same in zsh (the macOS default shell).

## Why

The kit's audit found these in the shell scripts: a guessable temp file name on a shared machine, a PATH line that could break the env file, no time limit on macOS, stub python3 installs that pass the tool check, and a removal command that skipped files with spaces in their path.

## How to apply

1. Copy `scripts/session-start.sh` from the kit, then put back your two commands (`TOOLCHAIN_SETUP` and `INSTALL_CMD`) from your copy. If you edited the script otherwise, keep your edits and take: the private folder block after `TIMEOUT_BIN=`, the `bounded` function, in `run_step` the `MORPHNESS_PATH_FILE="$work/path"` line, the `if [ -n "$TIMEOUT_BIN" ] || command -v perl` branch with its `bounded "$LIMIT"` call, the `printf '%s\n' "$(tail …)"` line and the `$work/path` read-back, the python3 check before `start_path=`, and the `printf '%q'` PATH line.
2. In `harness/README.md` § Modules → **Module markers.**, replace the command in the code block with the kit's (it starts `m=legal; grep -rl --null`).
