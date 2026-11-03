---
id: 2026-11-03-mode-sections
title: The main chat prints the mode sections it needs instead of reading MODES.md whole
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - AGENTS.md
  - harness/TECHNICAL_LEAD.md
removed: []
---

## What changed

- **`AGENTS.md` § Golden rules, the mode line,** now says to print § Choosing mode with `bash scripts/doc-section.sh harness/MODES.md "Choosing mode"`. Its last sentence names the sections to print next for each mode (§ Working alone with § Small mode or § Light mode, § Full harness, § Bug mode, § Research mode), and says never to read `harness/MODES.md` whole. It no longer links the file.
- **`harness/TECHNICAL_LEAD.md` § Full mode, step by step** prints only § Full harness at the mode step, since § Choosing mode is printed already.
- **The light and small mode line** names `MODES.md` § Working alone without a link.

## Why

The main chat picks the mode before it reads `harness/TECHNICAL_LEAD.md`, so its rule to print sections came too late for this step. It followed the `AGENTS.md` link and read all of `MODES.md`, five modes, while the step needs § Choosing mode and one mode's section.

## How to apply

1. In `AGENTS.md` § Golden rules, replace the link in the **Pick the mode first** bullet with the `doc-section.sh` call, and add the last sentence that names each mode's sections. Keep the rest of the bullet, including any project wording.
2. In the next bullet, replace the `harness/MODES.md` link in the light and small mode sentence with plain text.
3. In `harness/TECHNICAL_LEAD.md` § Full mode, step by step, the **Pick the mode** row prints `"Full harness"` alone.

Needs `scripts/doc-section.sh` (update 2026-11-03-section-reads).

## Skip if

Never: every install picks a mode.
