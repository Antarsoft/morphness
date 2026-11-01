---
id: 2026-11-01-risk-check
title: A script picks the mode from the files a change touches
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/rules/harness.md
  - harness.config.yml
  - harness/MODES.md
  - harness/SETUP.md
  - harness/TECHNICAL_LEAD.md
  - harness/templates/bug-plan.md
  - harness/templates/small-plan.md
  - project/CONTROLS.md
  - .claude/settings.json
  - project/HARNESS_AGENTS.md
  - scripts/risk-check.sh
removed: []
---

## What changed

- New `scripts/risk-check.sh`: given the files a change will touch (and whatever the branch has already changed), it prints `Mode: full` when one is on a risk path, when an added line deletes stored data (`DROP TABLE`, `TRUNCATE`, `DELETE FROM` and the like) or when more than `mode.plain_max_files` files change, and `Mode: plain` otherwise. It fails toward full when it can't decide.
- New `project/CONTROLS.md` § Risk paths: the paths behind each `risk_areas` entry, which the script reads. The kit ships three generic rows (schema and migrations, sign-in and sessions, money); `project/HARNESS_AGENTS.md` now points there instead of keeping its own list.
- New config block `mode:` (`plain_max_files: 6`, `force: auto`).
- `harness/MODES.md` § Choosing mode is one ordered list, first match wins: a question is research, a reported breakage is bug mode, any other change runs the script (full → full mode; plain → light mode when nothing behaves differently, small mode otherwise). The script runs again before the hand-off on the real diff. The human's wording ("quick fix", "no time for QA") never lowers the mode; only the owner choosing one does (`--force`).
- Light mode is only for changes that alter no behaviour, and the Technical Lead edits documentation itself in it (before, no role was allowed to edit a README). A question one or two files answer gets a direct answer instead of a research file. Plan approval is required in every mode that has a plan.

## Why

The same request, install and model got small mode with QA in one run and light mode without QA in another, because the mode rules overlapped and the model chose which to follow. A script gives the same answer every time, and the answer can be checked.

## How to apply

1. Copy `scripts/risk-check.sh` and make it executable. Add the `mode:` block after `risk_areas` in `harness.config.yml`, and `"Bash(bash scripts/risk-check.sh:*)"` at the end of `permissions.allow` in `.claude/settings.json` (without it every mode choice stops at a permission prompt). The guard stops an agent's edit to either file, so the owner makes both.
2. Add `project/CONTROLS.md` § Risk paths from the kit, before § Security paths. Fill it from your `project/HARNESS_AGENTS.md` risk-area bullets (each path in backticks, `.gitignore` style), narrow or drop the three generic rows to match this repo, then replace those bullets with the kit's one-line pointer. Check it: `bash scripts/risk-check.sh <a file in each area>` prints `Mode: full`.
3. Merge `harness/MODES.md`, `harness/TECHNICAL_LEAD.md`, `.claude/rules/harness.md`, `harness/SETUP.md` and the small and bug plan templates. If a retro added a mode rule of its own (a phrase that picks light mode, a "judge by what the change does" exception), it conflicts with the script: bring it to the owner, and keep it only as a reason to raise plain to full.

## Skip if

Never: without it the mode, and whether QA runs, depends on the model's reading of the request.
