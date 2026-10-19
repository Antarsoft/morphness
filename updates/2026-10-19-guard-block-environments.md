---
id: 2026-10-19-guard-block-environments
title: The guard protects environment branches written as a block list
kind: fix
release: 2026-10-19.2
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - scripts/lib/config.sh
removed: []
---

## What changed

The guard learned which branches to protect from the `environments:` list in `harness.config.yml`, but
only when each entry was a one-line flow map (`- { name: staging, branch: staging }`). An entry written
as a block (`- name: staging` with `branch: staging` on the next line) was skipped, so
`git push origin staging` passed. `scripts/lib/config.sh` has a new `config_env_branches` function that
reads the `branch:` of every `environments:` entry in either style, and `scripts/guard.sh` uses it.
The kit self-test now renders one sample project with a block-style list and checks that the function
prints every environment branch.

## Why

Both list styles are valid YAML and `/morph-doctor` tells owners to edit the list by hand, so a
reformatted or hand-written list silently switched protection off for its branches.

## How to apply

Add `config_env_branches` to `scripts/lib/config.sh` and replace the `sed` line in the
`GUARD_BRANCHES` block of `scripts/guard.sh` with a call to it.

## Skip if

Never; it is a fix.
