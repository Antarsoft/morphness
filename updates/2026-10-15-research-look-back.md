---
id: 2026-10-15-research-look-back
title: A short look-back on each research file, read by the prune
kind: template
release: 2026-10-15.2
applies_to: { modules: [] }
files:
  - harness/templates/research.md
  - harness/templates/prune.md
  - harness/MODES.md
  - harness/SETUP.md
  - .claude/rules/technical-lead.md
removed: []
---

## What changed

Research files get a § How it went section with three lines the Technical Lead fills when it records
§ Decision: whether its check confirmed the researcher's findings, whether the scope and researcher
effort were right, and whether the answer got used. The prune's research table (§ 1c) now carries
those columns and a **Proposals** line, and the prune step reads them to suggest tweaks, such as a
default researcher effort for a kind of question. Research still has no retro and never counts
toward the prune counter; `harness/MODES.md` and `harness/SETUP.md` now say so explicitly.

## Why

A full retro on research would be mostly empty (no code, QA or PR to look back on), and counting
research files would bring prunes forward although nothing in the build process changed. But
research quality was invisible: a researcher variant that keeps getting overruled on one kind of
question, or questions that keep coming back too wide, left no trace. Three lines per file are
enough for the prune to spot the pattern.

## How to apply

1. Add § How it went (the paragraph and the three bullets) after § Decision in
   `harness/templates/research.md`. Existing research files can stay as they are; add the lines
   only if the owner wants them in the next prune.
2. Replace the § 1c table in `harness/templates/prune.md` with the six-column one and add the
   **Proposals** line under it.
3. Merge the added sentences: step 4 and the paragraph after the steps in `harness/MODES.md`
   § Research mode; the end of step 1 in `harness/SETUP.md` § Prune; and the research-mode bullet
   in `.claude/rules/technical-lead.md`.

## Skip if

The project doesn't use research mode.
