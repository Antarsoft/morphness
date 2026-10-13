---
id: 2026-10-13-ci-cd-module
title: Optional ci-cd module for pipelines
kind: module
release: 2026-10-13
applies_to: { modules: [] }
offer_module: ci-cd
files:
  - harness/modules/ci-cd/README.md
  - harness/modules/ci-cd/github/ci.yml
  - harness/modules/ci-cd/github/deploy.yml
  - harness/modules/ci-cd/github/migrations.yml
  - harness/README.md
  - harness.config.yml
  - project/CONTROLS.md
removed: []
---

## What changed

A new optional `ci-cd` module lets the harness set up and look after the project's pipelines: CI
that runs the `before_qa` named checks on every pull request, an owner-run deploy workflow, and the
migrations workflow the `data-access` module refers to. Each pipeline is offered on its own. Agents
write pipeline files but never run, re-run or approve deploys or migrations.

## Why

Before this, the harness only described pipelines a project already had. A project without CI had
nothing running its checks on pull requests, and the `data-access` module pointed at a migrations
workflow that nothing created.

## How to apply

Ask the morph-init skill's Q9b (`skills/morph-init/references/questions.md` § Q9b) first: the
module is worth adding only for the pipelines the owner says yes to. On a yes:

1. Copy `harness/modules/ci-cd/README.md` into the project, and add `ci-cd` to
   `harness.config.yml` → `modules` plus the `ci_cd` block from the template, with `none`, `host`,
   `manual` or a workflow path for each pipeline.
2. Follow the module's § On install: copy only the accepted scaffolds to `.github/workflows/`
   (never over an existing workflow), fill their `{{…}}` keys and `# morph-init: fill` lines, add the
   deny rules, and fill `project/CONTROLS.md` § CI and `project/RELEASE.md` from the chosen pipelines.
3. Add the `ci-cd` row to `harness/README.md` § Modules.
4. Run the morph-init skill's render.md § Self-checks item 7 on the new workflows.

On a no to every pipeline, record the note as declined: nothing is written.

## Skip if

The project already has CI, deploys and migrations it is happy with, or isn't on GitHub or GitLab.
