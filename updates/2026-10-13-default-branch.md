---
id: 2026-10-13-default-branch
title: Choose the code host's default branch
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/RELEASE.md
  - .claude/rules/technical-lead.md
  - project/RELEASE.md
removed: []
---

## What changed

`branches.default` in `harness.config.yml` records the code host's default branch, and the kit now
recommends the integration branch for it whenever it is separate from production (the production
branch for a public library or tool whose visitors should see what shipped; the only branch in a
single-branch flow). `harness/RELEASE.md` § Default branch lists the trade-offs, and `/morph-doctor`
checks the host matches.

## Why

The kit only worked around the question ("the default branch may be the production branch", so
always pass `--base`). With production as the default, new PRs, dependency bot PRs and fresh clones
land on the wrong branch, and "Fixes #N" leaves issues open until the next release.

## How to apply

1. Read the host's current default branch (`git remote show origin`). Ask the owner: "Make
   `<integration>` the default branch? New PRs, dependency bots and clones then land there, and
   issues close when a feature merges; visitors see unreleased work in its README." Suggest keeping
   production for a public library or tool.
2. Add `default: <answer>` under `branches` in `harness.config.yml`, with the template's comment.
3. Merge `harness/RELEASE.md` (§ Default branch and the § Branches sentence) and the
   `.claude/rules/technical-lead.md` sentence on explicit bases.
4. When the host differs from the answer, add the owner step "set the repository's default branch
   to `<branch>`" to `project/RELEASE.md` § Manual steps. Agents never change it themselves.
5. If `.github/dependabot.yml` or `renovate.json` exists and the default branch stays production,
   set their target branch to the integration branch.
