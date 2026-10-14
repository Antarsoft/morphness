---
id: 2026-10-14-monorepo-apps
title: Optional apps list for monorepos
kind: config
release: 2026-10-14
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/RELEASE.md
  - harness/templates/plan.md
  - harness/modules/browser-e2e/README.md
  - harness/modules/ci-cd/README.md
  - harness/modules/ci-cd/github/deploy.yml
  - project/STACK.md
  - project/RELEASE.md
removed: []
---

## What changed

`harness.config.yml` has an optional `apps` list for monorepos: each app's folder, stack, browser
spec folder and, per environment, how it deploys (`harness/RELEASE.md` § Apps). Plans get an
**Apps touched** line, and targeted browser specs come from the touched apps. `project/STACK.md`
gets § Apps, `project/RELEASE.md` § Where things deploy gets an App column, and the ci-cd deploy
workflow gets one job per app that a workflow deploys. With `apps: []` (the default) nothing changes.

## Why

A monorepo whose apps deploy to different places (a web app on one host, an API on another) had
nowhere to say which app goes where, and plans didn't say which apps a change touched, so targeted
browser tests and deploy steps were guesswork once a repo had more than one app.

## How to apply

1. Add `apps: []` and its comment to `harness.config.yml` (before `pr_host`). For a single-app repo
   stop here, and mark the plan line `n/a` from now on.
2. For a monorepo, ask the owner which workspace packages are apps (built, tested or deployed on
   their own; shared libraries are not), and fill one entry each, with `deploy` keyed by the names in
   `environments`.
3. Merge § Apps into `harness/RELEASE.md` (after § Environments), the **Apps touched** line and the
   spec-folder note into `harness/templates/plan.md` § QA scope, and the bullets into the browser-e2e
   and ci-cd module READMEs when the copy has them.
4. Fill `project/STACK.md` § Apps and add the App column to `project/RELEASE.md` § Where things
   deploy. With the ci-cd module and an app deployed by workflow, split the deploy job per app.
5. Run `/morph-doctor`.

## Skip if

The repo has one app, or several that always build and deploy as one.
