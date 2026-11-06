---
id: 2026-11-05-doc-paths-config
title: A project's documentation-path changes are read by the end-of-task checks
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/CONTROLS.md
  - project/CONTROLS.md
  - scripts/checks.sh
removed: []
reviewed: "It adds two config keys that change which paths scripts/checks.sh treats as documentation (a removed path is checked more, an added one less), set only in harness.config.yml, which agents can't write; scripts, hooks and settings never count as documentation, and no guard rule or permission changes."
---

## What changed

- **`harness.config.yml`**: `checks.doc_paths_add` and `checks.doc_paths_remove`, both `[]` by default. Folders end in `/`; a single file is its path from the repository root.
- **`scripts/checks.sh`** reads them: a removed path is always code, an added path is documentation, and `scripts/`, `.claude/hooks/`, `.claude/skills/`, `.agents/`, `.claude/settings.json` and any path with `..` never count as documentation, whatever the lists say.
- **`harness/CONTROLS.md` § Documentation paths** and **`project/CONTROLS.md`** point to the config keys instead of saying the project's list is in `project/CONTROLS.md`, which the script never read.

## Why

`project/CONTROLS.md` § Documentation paths told a project it could add or remove paths, but `checks.sh` kept the kit's list: a docs site built from markdown was skipped by the end-of-task checks, and a path the project added was still checked. The lists are in the config, not in a document, because a document an agent edits could switch the checks off for the next change.

## How to apply

1. Copy `scripts/checks.sh` from the kit; add the two keys under `checks:` in `harness.config.yml` (the owner edits this file).
2. If `project/CONTROLS.md` § Documentation paths lists changes, copy them into the keys.
3. Merge the two doc sentences in `harness/CONTROLS.md` and `project/CONTROLS.md`.

## Skip if

You use the kit's list as it is.
