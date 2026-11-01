---
id: 2026-11-01-install-ignore-scripts
title: Session start puts --ignore-scripts on the install itself, also inside a chain
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/session-start.sh
removed: []
---

## What changed

- `scripts/session-start.sh` puts `--ignore-scripts` right after each npm, pnpm, bun or yarn 1 install's subcommand, wherever the install sits in the line: `cd app && npm ci`, `NODE_ENV=dev npm ci`, `npm --prefix web ci`, `pnpm -C web install`, `(cd api && pnpm i)`, `if …; then npm ci; else npm install; fi`, `npm ci 2>&1 | tee log`, `npm ci # a comment`, and every install in a chain. Before, it only looked at the start of the whole line and put the flag at its very end, so `npm ci && npx prisma generate` ran npm's lifecycle scripts and handed the flag to prisma, and the `cd`, `VAR=` and `--prefix` forms got no flag at all.
- A command after the install (`npx prisma generate`, `pnpm run build`) no longer gets the flag. An install where you wrote `--ignore-scripts` yourself (`--ignore-scripts=false` to run them) is left as you wrote it, and the other installs in the line still get the flag. An install behind another wrapper (`env`, `sudo`, `timeout`, `corepack`) is still left as written.

## Why

The kit's audit found that the chained and monorepo forms morph-init is likely to write skipped the protection, and that the stray flag could break the command after the install.

## How to apply

Copy `scripts/session-start.sh` from the kit, then put back your two commands (`TOOLCHAIN_SETUP` and `INSTALL_CMD`) from your copy. If you edited the script otherwise, keep your edits and replace the `safe_install` function with the kit's `safe_install`, `take_word` and `flag_install` functions, and the header comment's `--ignore-scripts` sentence.
