---
id: 2026-10-14-prune-counter-script
title: A script prints the prune counter for every hand-off
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - .claude/rules/technical-lead.md
  - harness/SETUP.md
  - _harness/learnings/README.md
  - harness/modules/claude-projects/README.md
removed: []
---

## What changed

`scripts/prune-counter.sh` prints the line the Technical Lead ends every feature hand-off with:
`Prune counter: N/<loop.prune_every>`, plus `Prune is DUE` when the count reaches the threshold or
`.claude/rules/technical-lead.md` is over 20 KB. It counts this branch's learnings files together with
the integration branch's, as `harness/SETUP.md` already described. The Technical Lead now pastes its
output instead of counting. With the `claude-projects` module, the feature thread's closing reply
carries the counter and the coordinator posts one line in the project chat when a prune is due.

## Why

The counter was an instruction only: a hand-off could leave it out or count by eye and miss the
features that merged into the integration branch from other branches. In a Claude Project it was
easy to miss, because nothing told the coordinator to surface a due prune.

## How to apply

1. Copy `scripts/prune-counter.sh` and make it executable (`chmod +x`). It reads `loop.prune_every`
   and `branches.integration` from `harness.config.yml`; if this copy renamed those keys, adjust the
   two `config_value` calls.
2. Merge the counter sentences into `.claude/rules/technical-lead.md` § Must do (the retro bullet),
   `harness/SETUP.md` § Retrospective → Prune counter and `_harness/learnings/README.md`.
3. With the `claude-projects` module, merge the two playbook lines, and tell the owner to paste the
   updated playbook into the Project instructions (the Claude app doesn't read it from the repo).
4. Run the script once; it should print the same count the last hand-off did.
