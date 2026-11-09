---
id: 2026-11-09-run-branch-base
title: In an autonomous run, the risk check and the QA hand-off compare a feature with the run branch
kind: fix
release: v0.18.0
applies_to: { modules: [] }
files:
  - scripts/risk-check.sh
  - scripts/handoff.sh
  - harness/modules/autonomous/README.md
removed: []
reviewed: "Both scripts stay read-only. They read two environment variables the driver already sets (MORPH_AUTO, MORPH_AUTO_BRANCH) to pick the commit they diff against; outside a run nothing changes. No guard rule, settings file or permission changes."
---

## What changed

- In a session an autonomous run started (`MORPH_AUTO=1`), `scripts/risk-check.sh` compares a feature branch with the run branch it left (`MORPH_AUTO_BRANCH`, such as `auto/v1`), not with the integration branch. On the run branch itself, and outside a run, it compares with the integration branch as before.
- `scripts/handoff.sh` does the same for the QA base, the diff stat it prints and the bug-order check's list of the branch's own commits. `--base` still wins.
- The module README's run rule 2 says so.

## Why

A run builds every feature on a branch made from the run branch. Both scripts measured the change from where the branch left the integration branch, so each feature's change included every feature already merged into the run. A two-file fix showed a 169-file diff stat and was raised to full mode, and QA was handed the whole run to review. Features reported it about ten times, in the plan, the risk check and the QA hand-off.

## How to apply

Merge `scripts/risk-check.sh`, `scripts/handoff.sh` and, with the autonomous module, its README from the kit. Nothing else changes.

## Skip if

Never: the scripts change only inside an autonomous run.
