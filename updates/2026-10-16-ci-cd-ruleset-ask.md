---
id: 2026-10-16-ci-cd-ruleset-ask
title: The ci-cd module no longer blocks applying branch protection
kind: fix
release: 2026-10-16
applies_to: { modules: [ci-cd] }
files:
  - harness/modules/ci-cd/README.md
  - harness/RELEASE.md
removed: []
---

## What changed

The ci-cd module's permission rules for `gh api` calls on rulesets and branch protection are now
`ask` instead of `deny`. `/morph-init` and `/morph-doctor` can apply the branch protection after the
owner says yes again: each call shows a permission prompt the owner allows. `harness/RELEASE.md`
§ Branch protection says so. Feature agents still never touch rulesets or protection.

## Why

The module added `deny` rules for `Bash(gh api*rulesets*)` and `Bash(gh api*protection*)` on
install, and modules are installed before `/morph-init` applies the protection. A deny can't be
approved past, so with ci-cd on, the owner-approved apply always failed and fell back to manual
steps, and `/morph-doctor` could never apply it later either.

## How to apply

1. In `.claude/settings.json`, remove `Bash(gh api*rulesets*)` and `Bash(gh api*protection*)` from
   `permissions.deny` and add both to `permissions.ask`. Keep every other deny the module added.
2. Update the line for them in `project/SKILLS_AND_MCPS.md` § Permission rules added for this project
   (ask, with the reason: the owner-approved protection apply).
3. If the protection was never applied because of the deny (`project/RELEASE.md` § Manual steps still
   has the ruleset row), offer to run `/morph-doctor`, which applies it on the owner's yes.

## Skip if

The owner wants agents never to run these commands at all, even with a prompt, and applies the
protection by hand.
