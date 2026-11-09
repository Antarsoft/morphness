---
id: 2026-11-09-guard-git-grep-pager
title: The guard asks before git grep -O, which runs a command
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - harness/GUARD.md
  - scripts/guard.sh
removed: []
reviewed: "It adds one ask to scripts/guard.sh: git grep with -O or --open-files-in-pager (any abbreviation), which runs the command it names. An autonomous run turns that ask into a deny. Plain git grep still passes. It adds no setting, permission or network call."
---

## What changed

- **`scripts/guard.sh`** asks before `git grep -O<command>` and `--open-files-in-pager=<command>` (also abbreviated, or inside a short-flag cluster such as `-nO`). In an autonomous run the ask is a deny. A plain `git grep` still passes.
- **`harness/GUARD.md`** names it in the asks list.

## Why

The autonomous module allows `Bash(git grep:*)` so a run's sessions can search with no prompt. `git grep -O<command>` runs that command on the matching files, so the read-only rule could run any command with no prompt.

## How to apply

1. Copy `scripts/guard.sh` from the kit. Agents can't write it, so the owner copies it by hand (`/morph-update` prints the `cp`).
2. In `harness/GUARD.md`, take the kit's words about `git grep -O` in the asks list.

## Skip if

Never: the hole exists wherever `git grep` is allowed.
