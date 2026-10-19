---
id: 2026-10-19-process-rules
title: Three retro and check rules from the run review
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/SETUP.md
  - harness/CONTROLS.md
  - harness/MORPHING.md
  - .claude/rules/technical-lead.md
removed: []
---

## What changed

- **Mechanism over memo:** a retro item that adds a sentence says why a script, hook, test or check
  can't do the job instead. A rule whose problem came back is converted into a mechanism, not extended.
- **Environment causes go to the owner:** a retro item tagged `cause: environment` (narrow
  permissions, a shared session id, a missing tool) is no longer decided by the Technical Lead alone.
  The owner decides it, or it goes in `.claude/settings.local.json`; it never becomes a `project/` or
  `harness/` rule on the TL's own yes.
- **A refused check is "not run":** a check the environment refused to run is recorded as not run,
  with the refusal. An "equivalent" command is never counted as a pass.

## Why

In a headless run, the retro turned a session's command limits into permanent project rules and
approved them itself, and agents counted a different command as a pass after their lint command
was refused. Across older features, the rules that held changed how something works; the ones
that were sentences asking an agent to remember something saw the problem return.

## How to apply

1. Merge the "Mechanism over memo" bullet and the `cause: environment` clause into
   `harness/SETUP.md` § Retrospective (Per-feature review), and the same clause into the list of items
   that go to the human in `harness/MORPHING.md` § How rules change.
2. Add the refused-check sentence to `harness/CONTROLS.md` § Notes.
3. In `.claude/rules/technical-lead.md`, add `or is tagged \`cause: environment\`` to the list of
   action items you don't decide alone (the "Then write `Plan/retro.md`" bullet).
