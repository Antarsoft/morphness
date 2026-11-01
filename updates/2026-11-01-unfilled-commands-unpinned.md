---
id: 2026-11-01-unfilled-commands-unpinned
title: Session start doesn't pin commands morph-init hasn't filled yet
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/session-start.sh
removed: []
---

## What changed

- `scripts/session-start.sh` no longer records its two commands as this clone's pin while they still hold `{{` placeholders (an existing pin is still compared, so a placeholder never lets a changed command run) (a copy `scripts/install.sh` made before `/morph-init` ran). Before, opening Claude Code to run `/morph-init` pinned the placeholders, and the first session after the install held the real commands as "changed" and installed nothing until the owner ran `--accept`.

## Why

The kit's audit found that a by-hand install made the first real session refuse to install dependencies, with nothing in the hand-off saying why.

## How to apply

In `scripts/session-start.sh`, add the kit's four lines above `if [ -n "$pin_file" ] && [ -n "$TOOLCHAIN_SETUP$INSTALL_CMD" ]; then` (two comment lines, `unfilled=0` and `case "$TOOLCHAIN_SETUP$INSTALL_CMD" in *'{''{'*) unfilled=1 ;; esac`), and start the line that writes the pin, `printf '%s\n' "$current" > "$pin_file" 2>/dev/null`, with `[ "$unfilled" = 1 ] || `. An installed copy has its commands filled, so the change only matters for the next fresh install; nothing else to do.
