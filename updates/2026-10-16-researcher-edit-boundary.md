---
id: 2026-10-16-researcher-edit-boundary
title: The researcher writes only between the two lines of its research file
kind: fix
release: 2026-10-16
applies_to: { modules: [] }
files:
  - .claude/rules/harness.md
  - harness/agents/researcher.md
  - harness/HANDOFFS.md
  - harness/SETUP.md
  - harness/STRATEGY.md
  - harness/templates/research.md
removed: []
---

## What changed

The researcher's edit boundary now reads the same everywhere: it writes only the sections between
the two `---` lines of its research file (§ Answer to § Sources). The Technical Lead owns the
sections above the first line and below the second (§ Check, § Decision, § How it went).

## Why

Five files said "below the first line", while `harness/HANDOFFS.md` (the researcher brief) said "between the two
lines". Read literally, "below the first line" let the researcher fill § Check and § Decision, the
Technical Lead's own check and call.

## How to apply

1. In `.claude/rules/harness.md` (researcher bullet), `harness/agents/researcher.md` (§ Write the
   research file and § Limits), `harness/SETUP.md` (researcher row) and `harness/STRATEGY.md` (researcher
   role), replace "below the first line" / "below its first line" with "between the two lines" /
   "between its two lines". The agent's edit rule also names § Check, § Decision and § How it went
   as off limits.
2. In `harness/templates/research.md`, the Process line says who writes each part: the Technical
   Lead above the first line, the researcher between the two lines, the Technical Lead below the
   second.
3. In `harness/HANDOFFS.md` § Ownership, the research row gives the Technical Lead § How it
   went as well.
4. If the project's research template lost one of its two lines, put it back (above § Check).

## Skip if

The project has no research mode files and has removed the researcher agent.
