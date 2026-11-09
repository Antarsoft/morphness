---
id: 2026-11-09-guard-handoff-cloud
title: A kit update hands the merged guard to the owner through the update branch in a cloud session
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - harness/GUARD.md
removed: []
reviewed: "It changes only the text of the guard's deny message for its own files and one line of harness/GUARD.md saying a staged copy under _harness/updates/ is not the guard. No rule, switch, settings file or permission changes: agents still never write scripts/guard.sh or scripts/lib/."
---

## What changed

- `/morph-update` (and `UPDATE.md`) now picks where the merged guard file waits by where the agent runs. On the owner's machine it stays under `/tmp/morphness-update/` with a `cp` command. In a cloud session or a Claude Projects thread it is committed on the update branch under `_harness/updates/<YYYY-MM-DD>/` with a `guard-sh.diff`, and the owner copies it into place in their own checkout, commits and pushes.
- The PR stays a draft until the agent has checked the owner's copy (`cmp`, `bash -n`, the push test, one test per new guard rule). Only then is the staging folder removed and the PR marked ready.
- A settings or config line the guard or the permission layer refuses is handed off the same way, with the exact line and where it goes under **Needs the owner** in the PR body and at the top of the report.
- The guard's deny message for its own files names both places, and harness/GUARD.md says the staging folder is not the guard.

## Why

The old text sent the merged guard to `/tmp` in every case. In a cloud session `/tmp` is in the agent's container, so the owner had no file to copy, and the copy wasn't on the PR branch either.

## How to apply

Take `scripts/guard.sh` through the usual guard hand-off (only its deny message changed) and merge the line in `harness/GUARD.md`. The skill text comes with the plugin update.
