---
id: 2026-10-19-supply-chain-pins
title: CI workflows pin actions to a commit, third-party skills install from a pinned commit
kind: fix
release: 2026-10-19.2
applies_to: { modules: [] }
files:
  - project/SKILLS_AND_MCPS.md
  - harness/modules/ci-cd/github/ci.yml
  - harness/modules/ci-cd/github/deploy.yml
  - harness/modules/ci-cd/github/migrations.yml
  - harness/modules/ci-cd/github/tag.yml
removed: []
---

## What changed

- The CI workflow scaffolds use `actions/checkout` pinned to a full commit (with the version in a comment) instead of the floating `@v4`.
- `project/SKILLS_AND_MCPS.md` § Installed (repo) has a third column, "Source and pinned commit", for each installed skill.

## Why

A moved tag or a renamed upstream repository would otherwise put new workflow code or new agent instructions into every project at its next run or install, with nobody reading the change.

## How to apply

In a project that already has CI workflows, replace `uses: actions/checkout@v4` with `uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262   # v4.4.0` in each `.github/workflows/*.yml`, and pin any other `uses:` line to the commit its tag points to. Add the "Source and pinned commit" column to § Installed (repo) and fill it for each installed skill as `<owner/repo>@<40-character commit>`; `/morph-doctor` now compares each installed skill with its pinned source and reports differences.
