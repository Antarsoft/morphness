---
id: 2026-10-16-module-markers
title: Module-only text is marked, so modules come and go mechanically
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/README.md
  - harness/HANDOFFS.md
  - harness/SETUP.md
  - harness/CONTROLS.md
  - harness/SKILLS_AND_MCPS.md
  - harness/STRATEGY.md
  - harness/templates/qa-result.md
  - harness/modules/browser-e2e/README.md
  - harness/modules/ci-cd/README.md
  - harness/modules/claude-projects/README.md
  - harness/modules/data-access/README.md
  - harness/modules/legal/README.md
  - harness/modules/roadmap/README.md
  - project/CONTROLS.md
  - project/HARNESS_AGENTS.md
  - project/STACK.md
  - project/TESTING.md
  - project/agents/fullstack-engineer.md
  - project/agents/qa-engineer.md
  - .github/pull_request_template.md
removed: []
---

## What changed

Text in the kit that exists only for one optional module now carries a marker: a block between
`<!-- module:<name> -->` and `<!-- /module:<name> -->` lines, the same pair inside a line for part of
a sentence, or a line (a table row, a list item) ending in `<!-- module:<name> -->`.
`harness/README.md` § Modules → **Module markers** has the one command that removes a module's
marked text. Each module's § On remove now says to run it and lists only what can't carry a marker:
always-loaded files (`AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, kept marker-free so they don't
grow), `harness.config.yml` and folder trees in code blocks. `harness/HANDOFFS.md` § Mandatory flow
item 5 is now **Features with migrations:** for everyone, with the stage B sentences marked
`data-access`. `/morph-update` copies a module's marked spans when the owner adds it later, and
`/morph-doctor` reports markers left for a module that isn't enabled.

## Why

Removing a module was text surgery across a dozen files from a hand-written list, and the lists had
drifted from the files (the legal list still described the agents sentence before the researcher
was added). Adding a module after install had no recipe beyond a `kind: module` note.

## How to apply

1. For each file listed, add the markers around the kit's marked spans that this copy still has.
   Text the project already removed with its module gets no marker. Text for an enabled module keeps
   its words; only the markers are added. Never move or reword a project rule to fit a marker.
2. Rows and list items take a trailing `<!-- module:<name> -->` (Markdown ignores the extra table
   cell). Don't add markers to `AGENTS.md`, `CLAUDE.md` or `.claude/rules/`.
3. In `harness/HANDOFFS.md` § Mandatory flow, item 5: rename **Data-access features:** to
   **Features with migrations:** (a copy without the data-access module already has it).
4. Replace each enabled module's § On remove with the kit's, and add the **Module markers**
   paragraph to `harness/README.md` § Modules.

## Skip if

The project never adds or removes modules after install and the owner prefers unmarked files.
