---
id: 2026-11-06-guard-env-ref-moves
title: The guard asks before a command moves an environment branch in the local clone
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
removed: []
reviewed: "It makes scripts/guard.sh ask (not pass) on git update-ref, fetch refspecs and checkout -B / switch -C that write an environment branch locally; it loosens nothing, and no setting or config value changes."
---

## What changed

- **`scripts/guard.sh`** asks before:
  - `git update-ref` on an environment branch, written as `refs/heads/<b>`, `refs/remotes/<remote>/<b>`, a bare `<remote>/<b>` (git resolves that from `.git/<remote>/<b>` first) or the name alone, and `git update-ref --stdin`, whose refs it can't see;
  - a `git fetch` refspec whose destination is one (`git fetch origin x:refs/remotes/origin/dev`);
  - `git checkout -B <b>` and `git switch -C <b>` with an environment branch's name.
  A plain `git fetch origin <b>` still passes.

## Why

The end-of-task checks and the merge gate read the project's checks from the integration branch as the clone has it. An agent that moved that branch locally changed which commands they ran, and the guard didn't ask.

## How to apply

1. Copy `scripts/guard.sh` from the kit. Agents can't write it, so the owner copies it by hand (`/morph-update` prints the `cp`).

## Skip if

Never: it closes a way around the checks.
