---
id: 2026-10-19-retro-wording
title: Retro template carries the environment-cause rule, and a few redundant sentences are gone
kind: rule
release: 2026-10-19
applies_to: { modules: [] }
files:
  - harness/templates/retro.md
  - harness/templates/learnings-entry.md
  - harness/SETUP.md
  - harness/CONTROLS.md
  - harness.config.yml
  - .claude/rules/technical-lead.md
removed: []
---

## What changed

- **Retro template:** the action-items table has a **Cause** column (the tag of the finding the item answers), the human-decision sentence now includes `cause: environment` items, and the text asks for a "why not a script, hook, test or check" line in the **Action** of any item that adds a sentence to a rule. The learnings entry template names `cause: environment` among the items the TL doesn't decide alone.
- **Who writes `settings.local.json`:** `harness/SETUP.md` § Retrospective now says the owner writes any permission change themself; an agent adding to its own permissions is the escalation the rule exists to stop.
- **Redundant sentences removed:** the last sentence of the prune-counter bullet in `harness/SETUP.md` (it said the hand-off ends with `Prune is DUE` even while a proposal waits) and the parenthetical about pasting the waiting line in the Technical Lead rule; "paste every line the counter prints" already covers both.
- **Wording:** the "learned:" notes in `harness/SETUP.md` (§ Retrospective, § Prune) and `harness/CONTROLS.md` § Notes keep the lesson without the counts. The security sentence in the `harness.config.yml` `risk_areas` comment no longer names a module the project may not have.

## Why

The retro template is the file the Technical Lead fills when it decides items, and it still carried the old rule. The other edits remove statements that disagreed with the counter script or named the security module in projects without it.

## How to apply

1. Copy the retro table (with the **Cause** column) and the two paragraphs above it from the kit's `harness/templates/retro.md` into yours, and the changed `Status:` sentence in `harness/templates/learnings-entry.md`.
2. In `harness/SETUP.md` merge the reworded `cause: environment` clause (Per-feature review), delete the last sentence of the **Prune counter** bullet, and drop the counts from the two "learned:" notes. Do the same for the "learned:" note in `harness/CONTROLS.md` § Notes.
3. In `.claude/rules/technical-lead.md` delete `(or paste the \`Prune proposal waiting\` line the counter prints instead, and write no second one)`.
4. In `harness.config.yml` replace the security sentence in the `risk_areas` comment with `When a security review runs before QA: \`harness/SETUP.md\` § Code review before QA.`
