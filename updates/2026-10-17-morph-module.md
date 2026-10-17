---
id: 2026-10-17-morph-module
title: Add or remove a module on a live project with /morph-module
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/README.md
  - harness.config.yml
removed: []
---

## What changed

`harness/README.md` § Modules and the `modules` comment in `harness.config.yml` now point to the new
`/morph-module add <name>` and `/morph-module remove <name>` skill. It runs a module's On install or
On remove steps on an installed project, puts the module's marked text back from the kit (or deletes
it), updates `modules` and the module's own config keys, keeps the project's own files (roadmap, legal
docs, pipelines) unless the owner says otherwise, and runs `/morph-doctor`.

## Why

A module could only be chosen at install. Adding one later meant copying marked spans by hand, and
removing one meant following the On remove section written for a fresh install, which doesn't undo
what On install added to the project's own files.

## How to apply

Replace the "To add one later" sentence in `harness/README.md` § Modules with the template's, and add
the `/morph-module` line under the `modules` comment in `harness.config.yml`. Update the Morphness
plugin so the skill is available.
