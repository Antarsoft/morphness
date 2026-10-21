---
id: 2026-10-21-find-delete
title: The guard asks before find deletes the whole repo
kind: fix
release: v0.13.0
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - AGENTS.md
removed: []
---

## What changed

- `scripts/guard.sh` asks before `find` with `-delete`, or `-exec rm` (also `unlink`, `shred`), when it starts at the repo root, its `.git`, or outside the repo, and has no name, path or age filter (`-name`, `-path`, `-regex`, `-newer`, `-mtime` and the like). `find . -name '*.log' -delete` and `find build -delete` still run.
- `AGENTS.md` § Permissions for this project lists it under **Asks**, and **What it does not see** now names a project-wide search that prints lines from a secret file and reads outside the project.

## Why

`rm -rf .` asked, but `find . -delete` removed the same files, `.git` included, with no check.

## How to apply

1. Copy `FIND_FILTERS` and `check_find` from the kit's `scripts/guard.sh` above the "known deploy, cloud and database CLIs" block, and the two lines that call it after the `check_rm` call.
2. Add the `find` item to the `rm -r` line of `AGENTS.md` § Permissions for this project → **Asks**, and the two items to **What it does not see**.

## Skip if

Never: it closes a gap in the guard.
