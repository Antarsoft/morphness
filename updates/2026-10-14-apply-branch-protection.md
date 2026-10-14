---
id: 2026-10-14-apply-branch-protection
title: Apply branch protection for the owner, and delete merged branches
kind: config
release: 2026-10-14.2
applies_to: { modules: [] }
files:
  - harness.config.yml
  - harness/RELEASE.md
  - harness/modules/ci-cd/README.md
removed: []
---

## What changed

`/morph-init` and `/morph-doctor` can now apply the environment-branches ruleset with `gh api` when
the owner says yes and has admin rights, and read it back. When they can't, they hand the owner the
file, the import steps and the command. A new `branch_protection.delete_merged_branches` (default
`true` with protection on) turns on the host's automatic deletion of a PR's branch after it merges.

## Why

The ruleset was only ever a file for the owner to import by hand, even when the session could have
applied it, and nothing suggested cleaning up merged branches, so feature branches piled up.

## How to apply

1. Merge `harness/RELEASE.md` § Branch protection (the apply path, § Delete merged branches, § Who
   changes these settings) and the `branch_protection` comment in `harness.config.yml`.
2. With `branch_protection.enabled: true`, ask: "Delete a PR's branch automatically once it merges?"
   Add `delete_merged_branches: true` or `false` under `branch_protection`. With protection off,
   add `false`.
3. Run `/morph-doctor`: it compares the live ruleset and the branch-deletion setting with the config
   and offers to apply them (morph-init's render.md § 7b), on the owner's yes.

## Skip if

Skip step 2 when the host isn't GitHub or GitLab.
