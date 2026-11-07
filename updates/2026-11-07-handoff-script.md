---
id: 2026-11-07-handoff-script
title: One call per hand-off, and the plan brief holds the always-run checklist groups
kind: rule
release: v0.17.0
applies_to: { modules: [] }
files:
  - scripts/handoff.sh
  - scripts/plan-brief.sh
  - .claude/settings.json
  - harness/HANDOFFS.md
  - harness/TECHNICAL_LEAD.md
removed: []
reviewed: "It adds one allow rule to .claude/settings.json, `Bash(bash scripts/handoff.sh:*)`, for a new script that writes nothing in the work tree (it runs git commands that read and `scripts/checks.sh status`). No guard rule or other settings value changes. The guard asks before an agent edits .claude/settings.json, so the owner adds that line."
---

## What changed

- **`scripts/handoff.sh <scout|fullstack|fullstack-bug|qa|qa-repro|closer> <slug> [--version N] [--base <commit>]`** (new): prints the role's prompt block from `harness/HANDOFFS.md` § Subagent prompt blocks with the feature folder's absolute path, the code map's path and commit (the Code map line is dropped in bug mode), the Path rules line (the `.claude/rules/*.md` files whose `paths:` match the files the plan names and the branch changes), and:
  - for QA: the merge base (`--base` for round 2), `git diff --stat`, the untracked files and `bash scripts/checks.sh status`;
  - for the scout: the files from the plan brief's risk check;
  - for the closer: the mode, the commit QA passed on and `--branch <branch>` for the cost script.
  Its last lines list, by label, the fields left for the conversation, and say when `plan.md` or a full-mode feature's code map is missing. It writes nothing in the work tree (git reads run without optional locks; `checks.sh status` keeps its records in the git folder). A `--base` that names no commit is a usage error.
- **`scripts/plan-brief.sh`**: the brief also holds `harness/PLAN_CHECKLIST.md` § How to use it and the groups that always run (§ Planning and scope, § Testing, § Process; bug mode § Planning and scope only) with `project/PLAN_CHECKLIST.md`, and its last line names the `handoff.sh` call for the next step. A full-mode brief grows from about 24K to 35K characters; the Read tool takes it whole. It also gets a `Files:` line with every file it was made for, which `handoff.sh scout` passes on.
- **`harness/TECHNICAL_LEAD.md`** § Full mode, step by step: the Map the code, Build, QA and After QA pass rows use `handoff.sh`; the Run the checklist row and § Before asking for approval print only the other groups that apply; bug mode's prompts come from `handoff.sh qa-repro` and `handoff.sh fullstack-bug`.
- **`harness/HANDOFFS.md`** § Subagent prompt blocks: one paragraph on the script. The blocks are unchanged; the script prints whatever they say.
- **`.claude/settings.json`**: `Bash(bash scripts/handoff.sh:*)` in `permissions.allow`.

## Why

In the benchmark's full-mode features the main chat took 30 to 48 turns where a plain run took 6 to 32, and every turn re-reads the whole context. Each hand-off cost a turn to print its block and one or two to fill it (merge base, diff stat, check results), and the checklist took three prints. These are mechanical steps a script can do in the same call.

## How to apply

1. Copy `scripts/handoff.sh` and `scripts/plan-brief.sh` from the kit.
2. Take the kit's rows in `harness/TECHNICAL_LEAD.md` § Full mode, step by step (Pick the mode, Map the code, Run the checklist, Build, QA, After QA pass and the bug-mode paragraph) and its sentence in § Before asking for approval.
3. Add the paragraph under `harness/HANDOFFS.md` § Subagent prompt blocks. If your blocks were customised, the script prints yours; keep the `Code map (full mode; …)` line prefixes and the `Path rules:` line starts, which it fills.
4. Owner: add `"Bash(bash scripts/handoff.sh:*)"` to `permissions.allow` in `.claude/settings.json` (the guard asks before an agent edits it).

## Skip if

Your Technical Lead runs no subagents (light and small mode only).
