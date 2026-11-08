---
id: 2026-11-07-guard-autonomous-run
title: During an autonomous run the guard turns asks into denies and protects the driver's files and the run branch
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - harness/GUARD.md
removed: []
reviewed: "It adds rules to scripts/guard.sh that apply only when MORPH_AUTO=1 is set, which scripts/auto/run.sh sets for the sessions it starts: asks become denies, and writes to the driver's files, harness.config.yml and (outside a director session) docs/product/, git push, merge and pull, moves of the run branch and code-host PR writes are denied. Without MORPH_AUTO every rule is as before. It loosens nothing and adds no setting, permission or network call."
---

## What changed

- **`scripts/guard.sh`**: when a session runs with `MORPH_AUTO=1` (only the autonomous driver sets it):
  - every ask is a deny, since no owner is there to answer;
  - writes to `_harness/auto/` state, ledger, tracker and exit report, `scripts/auto/`, `harness/templates/auto/`, `harness/modules/autonomous/` and `.git/morphness/auto/` are denied, and `docs/product/` too outside a director session; the feature's card in `_harness/auto/cards/` stays writable;
  - `git push`, `merge` and `pull` are denied, and so is checking out, moving or deleting the run branch (`MORPH_AUTO_BRANCH`, else `auto.branch`) or an environment branch;
  - `gh pr|repo|release|workflow` writes and the GitHub MCP PR tools are denied.
- **`harness/GUARD.md`**: a § During an autonomous run line, marked `module:autonomous`, so installs without the module don't get it.

## Why

A run has no owner at the keyboard. Without these rules a session could edit the run state or the driver, merge or push on its own, or change the approved product docs.

## How to apply

1. Copy `scripts/guard.sh` from the kit. Agents can't write it, so the owner copies it by hand (`/morph-update` prints the `cp`).
2. With the autonomous module, add the kit's marked line to `harness/GUARD.md`.

## Skip if

Never for `scripts/guard.sh` (the new rules do nothing outside a run). The `harness/GUARD.md` line only with the autonomous module.
