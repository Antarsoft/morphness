---
id: 2026-10-15-no-remote-yet
title: Agents work on local branches until the project is online
kind: rule
release: 2026-10-15
applies_to: { modules: [] }
files:
  - AGENTS.md
removed: []
---

## What changed

`AGENTS.md` has a new golden rule for a project with no remote yet: every `origin/<branch>` in the
harness means the local branch, fetches and pushes are skipped, and the Technical Lead merges on this
computer on the owner's ask, as with `pr_host: none`. `/morph-doctor` now notices when the project
has gone online since the install and offers to finish the code host setup (pull requests, CI,
branch protection).

## Why

A project installed before it had a GitHub repository hit failing commands wherever the harness
reads the remote copy of a branch (starting a feature, the diff for check scope, releases), with
nothing saying to use the local branch instead.

## How to apply

1. Merge the "No remote yet" bullet into this copy's `AGENTS.md` golden rules, after "Commit and
   push".
2. If this project has no remote today, or went online after `/morph-init` with `pr_host: none`, run
   `/morph-doctor` to finish the code host setup.

## Skip if

The project had a remote at install time and still has one.
