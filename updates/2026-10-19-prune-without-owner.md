---
id: 2026-10-19-prune-without-owner
title: The prune proposal is written without waiting for the owner
kind: rule
release: 2026-10-19
applies_to: { modules: [] }
files:
  - harness/SETUP.md
  - .claude/rules/technical-lead.md
  - _harness/LEARNINGS.md
  - harness/modules/claude-projects/README.md
removed: []
---

## What changed

- When `bash scripts/prune-counter.sh` prints `Prune is DUE`, the Technical Lead writes the prune
  proposal (`harness/SETUP.md` § Prune, steps 1-4) as its next task, before the hand-off, without
  asking the owner first. It commits `_harness/prunes/<date>.md` with status `proposed` on the current
  branch, and the hand-off ends with `Prune is DUE: proposal written at <path>`.
- The owner only decides the rows (step 5). Nothing is applied without that approval, and the next
  feature doesn't wait for it. While a proposal is still `proposed`, later hand-offs name it instead of
  writing another.
- Claude Projects playbook: the coordinator posts once per proposal, linking the thread, and never
  starts or applies the prune.
- `/morph-doctor` names the `proposed` file waiting for the owner, or says no proposal is written yet.

## Why

In a long unattended run the prune came due and never ran, because the Technical Lead waited for
the owner to start it. The proposal costs nothing to write and changes nothing until the
owner approves rows, so there was no reason to wait.

## How to apply

1. Merge the wording into `harness/SETUP.md` § Retrospective → Hand-off message and § Prune (the
   due paragraph and steps 4 and 5).
2. In `.claude/rules/technical-lead.md`, replace "When it prints `Prune is DUE`, propose the prune"
   with the template's sentence, and add `_harness/prunes/` to the files the Technical Lead edits.
3. Update the sentence about proposing a prune at the top of `_harness/LEARNINGS.md`.
4. With the `claude-projects` module: update the two prune lines in the playbook and paste the
   playbook into the Project instructions again.
