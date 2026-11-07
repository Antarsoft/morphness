---
id: 2026-11-07-plan-reads
title: While a full-mode plan is written, the guard sends whole-file prints of source back to the code scout's line ranges
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/GUARD.md
  - harness/TECHNICAL_LEAD.md
  - scripts/guard.sh
removed: []
reviewed: "It adds one deny to scripts/guard.sh, in the main chat only and only while a full-mode plan is a draft: a Read without a range, or a cat-like print that reaches the chat, of a source file over 80 lines. It loosens nothing. harness.config.yml gains one guard switch, plan_reads (on by default; off turns the rule off); no other setting or permission changes."
---

## What changed

- **`scripts/guard.sh`** has a cost rule. In the main chat (not a subagent), while a full-mode plan is written, it denies a whole print of a text file over 80 lines:
  - a Read with no limit, no offset past line 1 and no page range;
  - a `cat`, `nl`, `tac`, `less` or `more` whose output reaches the chat: last in its pipeline (or piped only into another of them, as in `cat f | less`), not inside a substitution, not redirected to a file. A `cd` earlier in the command, `sudo` or `timeout` in front, and globs are followed.

  "A full-mode plan is written" means the newest `Plan/brief.md` from `scripts/plan-brief.sh` is a full-mode one under 12 hours old, no other feature's `plan.md` is newer, and its own `plan.md` is missing or still `draft`. Docs, data and config files, binary files, and files under `_harness/`, `harness/`, `project/`, `.claude/`, `docs/` and `scripts/` pass. The message names the file's length and says how to read a range: Read with offset and limit, or `sed -n 'START,ENDp'`. A Read with offset and limit passes even when it covers the whole file, so the Technical Lead can still read all of it on purpose. Subagents are told apart by the `agent_id` Claude Code puts in their hook input; on a version without it, a subagent's call is treated as the main chat's.
- **`harness.config.yml`** → `guard:` gains `plan_reads: on`; `off` turns the rule off.
- **`harness/GUARD.md`** describes the rule under **Cost rule**, and **`harness/TECHNICAL_LEAD.md`**'s Write the plan row points to it.

## Why

In the benchmark rerun, the code scout's map came back and the main chat still printed whole files with `cat`, so the scout added a step and saved nothing. The rule said to read the map's ranges, but `cat` through Bash was read as something else. A deny with the way out costs one call and keeps the rest of the plan step on ranges.

## How to apply

1. Copy `scripts/guard.sh` from the kit. Agents can't write it, so the owner copies it by hand (`/morph-update` prints the `cp`).
2. In `harness.config.yml`, add the kit's `plan_reads` comment lines under `guard:`'s comment, and `plan_reads: on` to the `guard:` line. The rule is on when the key is missing, too.
3. In `harness/GUARD.md`, take the kit's **Cost rule** paragraph and the changed sentences in the opening paragraph, **Switches** and **What it does not see**.
4. In `harness/TECHNICAL_LEAD.md` § Full mode, step by step, take the kit's Write the plan row.

## Skip if

You don't use the code scout, or your source files are short; or set `plan_reads: off`.
