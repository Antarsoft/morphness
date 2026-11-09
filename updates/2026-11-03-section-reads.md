---
id: 2026-11-03-section-reads
title: The Technical Lead prints the section a step needs instead of reading whole harness docs
kind: template
release: v0.16.0
applies_to: { modules: [] }
files:
  - .claude/settings.json
  - harness/HANDOFFS.md
  - harness/PLAN_CHECKLIST.md
  - harness/TECHNICAL_LEAD.md
  - scripts/doc-section.sh
removed: []
reviewed: "It adds one allow rule to .claude/settings.json, `Bash(bash scripts/doc-section.sh:*)`, for a new read-only script that prints sections of a Markdown file; no other setting, guard rule, permission or config value changes."
---

## What changed

- **New `scripts/doc-section.sh`.** `bash scripts/doc-section.sh <file.md> "<heading>" …` prints the named sections of a Markdown file, each with its subsections; with no heading it lists the headings and their sizes. A name can be the start of a heading ("Choosing mode"), and may keep the docs' `§`, backticks or a `→` subsection path. A name that matches no heading, or more than one, exits 1 and lists the headings. It is read-only.
- **`harness/TECHNICAL_LEAD.md` says what to read.** The opening says to print the linked section instead of reading a whole harness doc, and names the few files read in full. The new § Full mode, step by step lists the section to print at each step, from picking the mode to the prune, with the bug mode and research mode differences.
- **The plan checklist is printed by group.** `harness/TECHNICAL_LEAD.md` § Before asking for approval and `harness/PLAN_CHECKLIST.md` § Group index print § How to use it and the index first, then only the groups the index doesn't skip, in one call.
- **`harness/HANDOFFS.md` § Subagent prompt blocks** gives each block its own `###` heading (Full-stack engineer, QA engineer, the two bug-mode blocks, Researcher), so one block can be printed alone. The text of the blocks doesn't change.
- **`.claude/settings.json`** allows `bash scripts/doc-section.sh`.

## Why

The main chat read the long harness docs whole, some of them more than once, and each one stayed in its context for every later step of the feature. The plan checklist alone is read whole even when most of its groups don't apply. Printing the section a step names keeps the rules the same and the context smaller.

## How to apply

1. Copy `scripts/doc-section.sh` and make it executable (`chmod +x`).
2. Add `"Bash(bash scripts/doc-section.sh:*)"` to `permissions.allow` in `.claude/settings.json`, next to the other `bash scripts/` rules.
3. Merge the opening and the new § Full mode, step by step in `harness/TECHNICAL_LEAD.md`, and its § Before asking for approval.
4. In `harness/HANDOFFS.md` § Subagent prompt blocks, turn each bold block label into a `###` heading; the bug reproduction and bug-mode labels' notes become one line under the heading.
5. Merge the § Group index sentence in `harness/PLAN_CHECKLIST.md`.

## Skip if

Never: every install reads the harness docs.
