---
id: 2026-10-13-release-tags
title: Release tags become optional and can be automated
kind: config
release: 2026-10-13.2
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/RELEASE.md
  - harness/README.md
  - harness/modules/ci-cd/README.md
  - harness/modules/ci-cd/github/tag.yml
removed: []
---

## What changed

A new `release_tags` key says whether merges to the production branch get a version tag (default
`true`, as before). The `ci-cd` module gains a tag workflow that tags each merge from the merged PR's
title (`Release vX.Y.Z` or `Hotfix vX.Y.Z`) and creates its release, so nobody pushes tags by hand.
Hotfix PRs are now titled `Hotfix vX.Y.Z`, and release step 7 checks the tag instead of pushing it
when the workflow is there.

## Why

Cloud sessions can't push tags, so every release and hotfix ended with the Technical Lead handing
the owner a command, and a hotfix counted as unfinished until the owner ran it. Nothing in the
harness reads tags back, so projects that don't want them can now turn them off.

## How to apply

1. Ask the owner: "Tag each release with its version? Nothing in the harness needs tags; they mark
   what shipped." Add `release_tags: true` or `false` to `harness.config.yml` after `pr_host`, with
   the template's comment.
2. Merge `harness/RELEASE.md` (step 7, § Versions, § Hotfix, the single-branch note). Keep the
   project's own version scheme if `project/RELEASE.md` names one.
3. With the `ci-cd` module, `release_tags: true` and GitHub or GitLab, offer the tag workflow. On a
   yes, copy `harness/modules/ci-cd/github/tag.yml` to `.github/workflows/tag.yml` (never over an
   existing one), fill `{{branches.production}}` and the `VERSION_RE` fill line, set
   `ci_cd.tags: .github/workflows/tag.yml`, and merge the module README's new lines (pipeline row,
   tag rule, owner step, On install line). Then run morph-init's render.md § Self-checks item 7 on it.
   Without the module, add `tags: none` to `ci_cd` only if the block exists.
4. If the project already tags releases in its own workflow, keep that one and record its path in
   `ci_cd.tags` instead.

## Skip if

Skip step 3 when the project's own release tooling (semantic-release, release-please, changesets)
already creates tags and releases; steps 1 and 2 still apply.
