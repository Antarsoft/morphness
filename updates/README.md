# Kit updates

Changes to the kit (`template/`) that an already installed harness may want. Each one is a short
note an agent can apply to a copy that has morphed since it was installed. `/morph-update` (or
[UPDATE.md](../UPDATE.md) for agents without the plugin) lists the notes a project hasn't seen yet,
explains each one, and applies only the ones the owner accepts, merged with the project's own edits.

Community **lessons** (`lessons/`) are single rules and need no note; `/morph-update` offers those
too. A note is for everything else: a new module, a changed process rule, a new template, a new
config key, a fix to a wrong instruction.

## When to write one

Every PR that changes a file under `template/` adds one note (or extends one written for the same
release). `scripts/check-updates.sh --since origin/main` fails when a changed template file isn't
listed in any new note. Changes to the skills (`skills/`) need no note: they reach installs through
the plugin, and their changelog fragment (`changelog.d/`) covers them.

## File format

One note per file, named `<id>.md`, with the id starting with the date it was added.

```markdown
---
id: 2026-10-13-ci-cd-module      # YYYY-MM-DD-<kebab-case>, unique, same as the file name
title: Optional ci-cd module for pipelines
kind: module                     # module | rule | template | config | fix
release: 2026-10-13              # the release it ships in (2026-10-13, or 2026-10-13.2 for a later one that day), or unreleased
applies_to: { modules: [] }      # empty: every install. Listed modules: only installs that have one
offer_module: ci-cd              # kind module only: the module this note adds, offered as opt-in
files:                           # every template/ path it adds or changes, relative to template/
  - harness/modules/ci-cd/README.md
removed: []                      # template/ paths it deletes, if any
---

## What changed

Two or three sentences a project owner can read: what is new or different.

## Why

The problem it solves, ideally the failure that taught it.

## How to apply

Steps for an agent working in a morphed copy, beyond the file merge `/morph-update` already does:
questions to ask, config keys to add, rendered files to adjust, links to fix.

## Skip if

When a project doesn't need it (optional).
```

`kind: fix` is for a kit instruction that was wrong or unsafe. `/morph-update` lists fixes first,
and a fix goes out in a release the same day (CONTRIBUTING.md § Releases).

## How a note is applied

`/morph-update` does a three-way comparison for every file a note lists: the template at the commit
the project last synced to (`harness.config.yml` → `installed_from.commit`), the template now, and the
project's file. An unedited file takes the new version as is; an edited one gets a merge that keeps
the project's rules, shown to the owner before it is written. Files with render placeholders are
adjusted by hand from the template's diff. Nothing is overwritten silently, and a declined note is
never offered again.
