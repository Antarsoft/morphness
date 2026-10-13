---
id: 2026-10-13-upstream-updates
title: Kit updates from upstream, checked at every prune
kind: rule
release: 2026-10-13
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/README.md
  - harness/MORPHING.md
  - harness/SETUP.md
  - harness/templates/prune.md
removed: []
---

## What changed

Installed harnesses can now take in changes to the kit itself, not only community lessons.
`/morph-update` lists the kit update notes and lessons added upstream since this copy last synced,
and applies the ones the owner accepts, merged with local edits. Every prune now runs that listing
read-only and puts the pending items in the proposal for the owner to decide.

## Why

A copy changed only through its own retros, so fixes and new modules made upstream never reached
it unless someone re-ran the install or copied files by hand.

## How to apply

1. In `harness.config.yml`, turn `installed_from` into the block form from the template: keep `repo`
   and `commit`, add `release` (the Morphness release of that commit, or the oldest release when it
   isn't known) and `updates: { applied: [], declined: [], deferred: [] }`. `/morph-update` does this
   itself on its first run; check it's there.
2. Merge the `MORPHING.md` § Health check and upstream updates section, the extra sentence in
   `SETUP.md` § Prune step 3 and the upstream wording in steps 5 and 6, and `templates/prune.md`
   § 3c. Where the project renumbered or reworded the prune steps, add the upstream check to its own
   proposal step instead.
