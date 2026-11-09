---
id: 2026-11-08-auto-feature-folder
title: An autonomous run's feature folder uses the exact slug, and a folder missing only the -<n> suffix still counts
kind: fix
release: v0.18.0
applies_to: { modules: [] }
files:
  - scripts/plan-brief.sh
  - scripts/auto/driver.py
  - harness/templates/auto/feature-prompt.md
  - harness/templates/auto/resume-prompt.md
  - harness/modules/autonomous/README.md
removed: []
---

## What changed

- With the autonomous module, the feature and resume prompts name the folder the session must use, `_harness/features/<slug>/<version>/`, next to the branch.
- `scripts/plan-brief.sh` refuses a slug other than the run's feature (`MORPH_AUTO_FEATURE`) in an autonomous session, and says which slug to use. Outside a run it is unchanged.
- When a passed card's folder is missing, the driver reads a folder named after the slug without its trailing `-<n>` (`fix-app-shell` for the inserted fix `fix-app-shell-1`), if the session added it on the feature branch and no feature of the run has that name. It prints a warning with the `git mv` to rename it, instead of exiting.

## Why

In an autonomous run, a session for the inserted fix `fix-app-shell-1` wrote its records under `_harness/features/fix-app-shell/1/`. QA had passed, but the driver found no folder under the exact slug and exited after the retry.

## How to apply

Merge `scripts/plan-brief.sh` from the kit. With the autonomous module, also merge `scripts/auto/driver.py`, the two prompt templates and the module README.

## Skip if

Never; the plan-brief check only applies inside an autonomous run.
