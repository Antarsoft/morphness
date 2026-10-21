---
id: 2026-10-21-learned-rules-list
title: List what the harness has learned, with source and last fired
kind: rule
release: v0.14.0
applies_to: { modules: [] }
files:
  - scripts/learned-rules.sh
  - .claude/settings.json
  - harness/MORPHING.md
  - harness/SETUP.md
  - harness/templates/learnings-entry.md
  - _harness/LEARNINGS.md
removed: []
---

## What changed

`bash scripts/learned-rules.sh` prints one row per rule that carries a provenance tag: file and line,
the finding it came from, the day it landed, the last day a learnings entry said it fired, and the rule
text. Rules with no tag are counted per file (`--all` lists them with blank columns). The learnings entry
gains an optional `**Fired:**` line, and the prune keeps it when it folds the entry.

## Why

Provenance and the prune's rule audit lived in separate places, so seeing what the harness had learned,
and which of it was ever used, meant reading every owner file and retro by hand.

## How to apply

1. Merge the listed files; `chmod +x scripts/learned-rules.sh`. The `.claude/settings.json` change is one
   allow rule, `Bash(bash scripts/learned-rules.sh:*)`.
2. From the next retro on, the TL adds a `Fired:` line to the learnings entry when a tagged rule caught
   something. Entries written before this have none, so last fired stays blank for them.

## Skip if

The copy has no `(from …)` tags yet; the list would be empty.
