---
id: 2026-10-13-environments
title: Shared environments as a configurable list
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/RELEASE.md
  - harness/templates/release-qa-result.md
  - project/RELEASE.md
  - .github/pull_request_template.md
  - harness/modules/ci-cd/README.md
  - harness/modules/ci-cd/github/deploy.yml
  - harness/modules/ci-cd/github/migrations.yml
removed: []
---

## What changed

`harness.config.yml` gains an `environments` list: the shared environments in the order code moves
through them, each with its branch, how it deploys and whether it holds real data. The default is
two, `dev` on the integration branch and `production` on the production branch. A project can add a
middle one (`staging`, `uat`) on the integration branch or on its own branch with promotion PRs, or
keep fewer. Release QA now runs on the environment just before production, and the ci-cd deploy and
migrations workflows offer exactly the listed environments, each only from its own branch.

## Why

The kit assumed one environment per branch and hardcoded `staging` and `production` in the
workflows, so a dev, staging and production setup couldn't be described, and nothing checked that the
environments the owner named matched the workflows and `project/RELEASE.md`.

## How to apply

1. Build the list from what the project already has: `project/RELEASE.md` § Where things deploy, the
   deploy and migrations workflows' `options`, `environment:` keys in other workflows, and branches
   such as `staging`. Show it to the owner and ask: "Keep these, or add or remove one?" For each
   entry ask how it deploys (`host`, `workflow`, `manual`, `none`) and whether it holds real people's
   data. Write it to `harness.config.yml` after `branches`, with the template's comment. The first
   entry runs `branches.integration` and the last runs `branches.production`.
2. Merge `harness/RELEASE.md` (§ Environments, steps 2, 3 and 7, § Merge style, § Hotfix step 4) and
   the release QA wording in `harness/templates/release-qa-result.md` and the PR template.
3. Rewrite the table in `project/RELEASE.md` § Where things deploy as one row per environment, keeping
   the project's own hosting and database text, and name the release QA environment under it.
4. With the `ci-cd` module and a deploy or migrations workflow: set its `options` to the environment
   names and replace its branch guard with the template's `case` guard, one line per environment.
   Keep the project's own deploy and migrate steps. Then run morph-init's render.md § Self-checks
   items 7 and 8.
5. Remind the owner to create or rename the host's environments to match, with required reviewers on
   every `real_data: true` entry.

## Skip if

Never skip it entirely: the list is what `/morph-doctor` checks. A project with no deployments still
adds `environments: []`.
