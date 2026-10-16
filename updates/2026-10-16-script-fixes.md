---
id: 2026-10-16-script-fixes
title: Scripts read the config in any style, count prunes right and skip unchanged installs
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/lib/config.sh
  - scripts/prune-counter.sh
  - scripts/feature-cost.sh
  - scripts/session-start.sh
  - harness/SETUP.md
removed: []
---

## What changed

- **One config reader.** `scripts/lib/config.sh` reads `harness.config.yml` in block style and in
  one-line `{ key: value }` style alike. `prune-counter.sh` and `feature-cost.sh` both use it, so
  `branches: { integration: dev }` and a block-style `cost:` with `track: false` are now read.
- **`--since` is UTC.** `feature-cost.sh --since 2026-10-15T09:30` now means 09:30 UTC, as its usage
  text always said; before, a time with no zone was read as the machine's local time.
- **The prune counter no longer counts pruned files again.** On a branch cut before a prune, the
  learnings files the prune folded on the integration branch used to count until the branch merged.
  Now a branch counts only the files it added, plus the ones still on the integration branch.
- **Dependency install only when something changed.** `session-start.sh` skips the install when the
  lockfiles at the repo root and the install command match its last successful run in this clone
  (the hash lives in the git folder, `morphness-install.hash`; delete it to force an install). With no
  known lockfile it installs every session, as before.

## Why

A review found that both scripts read the config with a pattern that only matched one YAML style
each, so a valid config silently gave the wrong branch or kept cost tracking on; that the prune
counter over-counted after a prune; and that large projects paid for a full install on every session.

## How to apply

1. Add `scripts/lib/config.sh` as it is.
2. `scripts/prune-counter.sh`, `scripts/feature-cost.sh`: take the kit's version unless the project
   changed them; then merge, keeping the `config_get` calls.
3. `scripts/session-start.sh`: keep the project's two commands (`TOOLCHAIN_SETUP`, `INSTALL_CMD`)
   and take the rest. If the project's lockfile isn't in `LOCKFILES` (or sits in a subfolder), add
   its path there. Check with `bash -n scripts/session-start.sh`; don't run it.
4. Check: `bash -c '. scripts/lib/config.sh; config_get branches.integration'` prints the integration
   branch, and `bash scripts/prune-counter.sh` prints the counter.

## Skip if

Never for steps 1 and 2. Step 3 may be skipped when installs are already fast.
