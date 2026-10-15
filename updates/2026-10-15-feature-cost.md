---
id: 2026-10-15-feature-cost
title: An estimated dollar cost for every feature, from Claude Code's own transcripts
kind: template
release: 2026-10-15.2
applies_to: { modules: [] }
files:
  - scripts/feature-cost.sh
  - harness/MODEL_PRICES.md
  - harness.config.yml
  - harness/SETUP.md
  - harness/MODES.md
  - harness/MORPHING.md
  - harness/templates/retro.md
  - harness/templates/learnings-entry.md
  - harness/templates/prune.md
  - harness/templates/research.md
  - harness/modules/claude-projects/README.md
  - _harness/LEARNINGS.md
  - .claude/rules/technical-lead.md
  - project/HARNESS_AGENTS.md
removed: []
---

## What changed

Every feature now records what its Claude Code work would cost at public API prices, split by the
Technical Lead and each subagent. A new read-only script, `scripts/feature-cost.sh`, reads Claude
Code's own session transcripts and prices them from a table in `harness/MODEL_PRICES.md`. Its
`Cost ≈ $…` line goes in the retro's run table (new Est. $ column, Technical Lead and Total rows),
on the learnings **Cost** line and at the end of the hand-off message. Light-mode tasks end their
closing message with it, research files carry it in their header, and the prune shows each
feature's cost with the window's total and average next to the previous window's.

## Why

The harness recorded tokens from the subagents' completion notices, which can't be priced: one
number with no split between cache reads (a small fraction of the input price), cache writes and
output. A test notice said 70k tokens for a run whose transcript showed 211k input tokens, most of
them cache reads. The Technical Lead's own session, often the largest share in a long thread, was
never counted. The transcripts record every API call's model and tokens by kind, the same on an API
key, Pro or Max, so the dollar figure is comparable across features even when nothing is billed per
call.

## How to apply

1. Copy `scripts/feature-cost.sh` and make it executable (`chmod +x`). It needs `python3`; without
   it, it prints `Cost: not measured (python3 not found)`.
2. Copy `harness/MODEL_PRICES.md`. A project on its own rates (Amazon Bedrock, Google Cloud, a
   discount) edits the numbers and the date there.
3. Add the `cost:` line and its comment to `harness.config.yml` above `loop:`. Ask the owner whether
   to keep it on (`track: true`, the default).
4. Merge the template and rule changes: the run table and its paragraph in `retro.md`, the **Cost**
   line in `learnings-entry.md` and `_harness/LEARNINGS.md` § format, the § 1 table and **Cost** line
   in `prune.md`, the **Cost** header line in `research.md`, the Feature cost bullet and prune
   wording in `harness/SETUP.md`, the light-mode bullet and research step in `harness/MODES.md`, the
   hand-off sentence in `.claude/rules/technical-lead.md`, the KPI wording in `harness/MORPHING.md`
   and `project/HARNESS_AGENTS.md`, and the hand-off line in the claude-projects module. A copy that
   renamed the Full-stack or QA columns keeps its names; only the Tokens column goes, replaced by
   Est. $.
5. Existing learnings files and retros stay as they are; the prune writes `not measured` for
   features finished before this update.
6. With the `claude-projects` module: re-paste the feature-thread lines of the playbook into the
   Project instructions, so threads end with the cost line.

## Skip if

The owner doesn't want cost figures (or set `cost: { track: false }` instead, which keeps the files).
