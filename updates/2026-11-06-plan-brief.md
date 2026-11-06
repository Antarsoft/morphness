---
id: 2026-11-06-plan-brief
title: One script gathers the plan step's docs into a brief the Technical Lead reads in one call
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/settings.json
  - AGENTS.md
  - harness/TECHNICAL_LEAD.md
  - scripts/plan-brief.sh
removed: []
reviewed: "It adds one allow rule to .claude/settings.json, `Bash(bash scripts/plan-brief.sh:*)`, for a new script that runs the read-only risk check and writes one ignored copy of four harness docs under _harness/features/; no other setting, guard rule, permission or config value changes."
---

## What changed

- **`scripts/plan-brief.sh <slug> <files>`** (new) runs `scripts/risk-check.sh` on the files and prints its answer. On `Mode: full` it writes `_harness/features/<slug>/<version>/Plan/brief.md`, which holds:
  - the risk check;
  - `harness/MODES.md` § Full harness;
  - `.claude/rules/testing.md`;
  - `harness/SETUP.md` § Effort per feature and § Where QA can run;
  - the plan template.

  `--bug` adds § Bug mode and swaps in `bug-plan.md`. `--version N` names the feature version (default 1), and the script says so when that version already has a `plan.md`. On `Mode: plain` it writes nothing. It prints the same answer as the risk check, so it can replace the first `risk-check.sh` call. A one-line `.gitignore` next to the brief keeps it out of commits.
- **`harness/TECHNICAL_LEAD.md`**: the step table's first rows run the script, then Read the brief in one call, in place of four or five separate prints. The bug-mode line does the same with `--bug`.
- **`AGENTS.md`**: § Golden rules names the script as the risk-check call for a change that looks risky, and sends full and bug mode to the brief for their mode section.
- **`.claude/settings.json`** allows `bash scripts/plan-brief.sh`.

## Why

In the benchmark runs, the full-mode main chat spent a call per doc on the plan step, and one batched print was cut and had to be read again. Each call re-reads the whole conversation, so fewer calls on the same text costs less. The brief is about 23,000 characters, too big for one print but fine for one Read. What the plan is written from is unchanged.

## How to apply

1. Copy `scripts/plan-brief.sh` from the kit and make it executable.
2. Add `"Bash(bash scripts/plan-brief.sh:*)"` to `permissions.allow` in `.claude/settings.json`, next to the other `bash scripts/` rules.
3. In `harness/TECHNICAL_LEAD.md`, take the kit's:
   - sentence on what to read in full, above § Full mode, step by step;
   - first two rows of that section's step table, and its bug-mode line under the table;
   - **Keep each print under about 12,000 characters** paragraph;
   - § Must do bullets on `.claude/rules/testing.md` and on picking the mode.
4. In `AGENTS.md` § Golden rules, take the kit's **Pick the mode first** bullet.

## Skip if

Your project changed which docs the plan step reads; then keep your own list, or edit the script's list of sections to match.
