---
id: 2026-10-16-deploy-after-ci
title: Automatic deploys wait for CI, and the back-merge is its own release step
kind: fix
release: 2026-10-16
applies_to: { modules: [] }
files:
  - harness/modules/ci-cd/README.md
  - harness/modules/ci-cd/github/ci.yml
  - harness/modules/ci-cd/github/deploy.yml
  - harness/RELEASE.md
  - .github/pull_request_template.md
removed: []
---

## What changed

- **ci-cd module:** the deploy workflow's automatic deploy on a push to the integration branch now
  runs the CI workflow on that commit first and deploys only when it passes. The CI workflow can be
  called for this (`workflow_call`), and a called run always checks everything (no docs-only skip).
  A deploy the owner starts by hand doesn't wait for CI, as before.
- **Release steps:** bringing the production branch back into the integration branch after a release
  is now step 8 of `harness/RELEASE.md` § Release steps, done in the same turn as the tag, and the
  PR template's **Release** section has a box for the back-merge PR.

## Why

A push to the integration branch deployed even when CI hadn't run or had failed on that commit. The
back-merge was a sentence at the end of step 7, and nothing reminded anyone of it, so the next
release PR showed the last release's commits again.

## How to apply

1. With the `ci-cd` module and a deploy workflow that deploys on push: add the `ci` job to
   `.github/workflows/deploy.yml` and the `needs` and `if` lines to the deploy job, as in the kit's
   scaffold (`.github/workflows/ci.yml` must exist). In `ci.yml`, add `workflow_call:` to `on:` and
   change the scope step's condition so only `pull_request` runs can skip as docs-only. Keep every
   project-filled step. Show the owner the diff: a pipeline change is a `risk_areas` change.
2. `harness/RELEASE.md`: take step 8. In the PR template's **Release** section, add the back-merge
   box.

## Skip if

Step 1: without the ci-cd module, without a deploy workflow, or when its push trigger was deleted.
