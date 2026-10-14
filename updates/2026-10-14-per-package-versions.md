---
id: 2026-10-14-per-package-versions
title: Per-package versions for monorepos
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/RELEASE.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/modules/ci-cd/README.md
  - project/RELEASE.md
  - .github/pull_request_template.md
removed: []
---

## What changed

`release_tags` takes a third value, `per-package`, for monorepos whose packages carry their own
versions through a tool such as Changesets, Nx release or release-please (`harness/RELEASE.md`
§ Per-package versions). Full-stack adds the tool's change file for each versioned package a feature
changes, and QA checks they are there. Releases are named by date, the release PR lists each
package's next version, and the tool, not the harness, writes the `<package>@x.y.z` tags. `true` and
`false` work as before.

## Why

The kit assumed one `vX.Y.Z` per repo. A monorepo that publishes several packages had to either
drop tags or fight the tag workflow, and nothing reminded a feature to record its version bumps.

## How to apply

1. Add the `per-package` lines to the `release_tags` comment in `harness.config.yml`. Change the
   value only when the repo already uses a per-package versioning tool, and ask the owner first.
2. Merge § Per-package versions and the step 7 and hotfix sentences into `harness/RELEASE.md`, and the
   one-line additions into the Full-stack and QA agent bodies and the ci-cd README (if present).
3. Add § Versions to `project/RELEASE.md` (before § Rollback). With `per-package`, fill it with the
   tool, its config, the change-file and dry-run commands, and what runs the publish step.
4. Add the package-versions line to the PR template's Release section (with `per-package` only) and
   the per-package note to its Hotfix tag line. With `per-package`, replace `vX.Y.Z` in the Release
   and Hotfix comments with a date, and remove the Morphness tag workflow if `ci_cd.tags` has one.

## Skip if

The repo ships under one version, or doesn't tag releases.
