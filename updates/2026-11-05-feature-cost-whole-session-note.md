---
id: 2026-11-05-feature-cost-whole-session-note
title: The feature cost line says when it counts a session that began long before the branch
kind: template
release: v0.17.0
applies_to: { modules: [] }
files:
  - scripts/feature-cost.sh
removed: []
reviewed: "It adds a read-only note to the output of scripts/feature-cost.sh, using git log on the branch; no setting, guard rule, permission or config value changes."
---

## What changed

- **`scripts/feature-cost.sh`**: with no `--since`, `--branch` or `--session`, when the session's first API call is more than three hours before the branch's first commit (against `origin/HEAD`, `origin/main` or `origin/master`), the `Cost ≈` line ends with a note that it counts the whole session and to pass `--since`. The figure itself is unchanged.

## Why

With no option the script counts the whole session, so a session that did other work first gave a cost figure that looked like the feature's. The Technical Lead pasted it into the learnings file and hand-off without a hint it was too high.

## How to apply

1. Copy `scripts/feature-cost.sh` from the kit. Projects rarely edit it; if yours did, keep your edits and add the note block before the `if not calls:` line.
2. Run `bash scripts/feature-cost.sh` once; on a branch with no base ref it prints no note.

## Skip if

You always pass `--since` or `--branch`.
