---
id: 2026-11-07-autonomous-module
title: Optional autonomous module (rules and templates for an unattended run from a brief to the first version)
kind: module
release: unreleased
applies_to: { modules: [] }
offer_module: autonomous
files:
  - harness/modules/autonomous/README.md
  - harness/templates/auto/brief.md
  - harness/templates/auto/product.md
  - harness/templates/auto/tech.md
  - harness/templates/auto/design.md
  - harness/templates/auto/finance.md
  - harness/templates/auto/card.md
  - harness/templates/auto/exit.md
  - harness/templates/auto/director-prompt.md
  - harness/templates/auto/replan-prompt.md
  - harness/templates/auto/feature-prompt.md
  - harness/templates/auto/resume-prompt.md
  - harness/templates/auto/prune-prompt.md
  - harness/README.md
  - harness/templates/plan.md
  - harness/templates/small-plan.md
  - harness/templates/bug-plan.md
  - harness.config.yml
removed: []
reviewed: "It adds a module folder, templates, an auto: config block that is off and read by nothing yet, and lines marked module:autonomous that only apply with MORPH_AUTO=1 set. It changes no guard rule, setting, permission or script, and makes no network call. The run rules forbid pushes, merges, deploys, publishes, store builds and secrets."
---

## What changed

- A new optional module, **autonomous**: the run rules, phases, stop conditions and files for an unattended run that goes from `docs/brief.md` to the first version on its own branch. The owner approves the product docs once; each feature then runs through the normal harness in its own session, and owner items go to the feature's steps file and, through the driver, the version checklist's § Needs you.
- Templates and prompts in `harness/templates/auto/`, and an `auto:` block in `harness.config.yml` (`enabled: false`).
- With the module, one line in each plan template's § Approval points to the run rules. It is marked `module:autonomous`, so installs without the module don't get it. `harness/TECHNICAL_LEAD.md` is unchanged: the driver's prompts point the Technical Lead to the run rules.
- The driver (`scripts/auto/`), its guard rules and the `/morph-auto` skill come in a later release; until then the module can't start a run.

## Why

Owners asked for a way to hand the harness a brief and come back to a built first version, with the guard, checks and QA still in place and every human-only step written down instead of blocking the run.

## How to apply

Offer the module; skip it unless the owner wants it. It needs the roadmap module. On a yes, `/morph-module add autonomous` follows its § On install: put back the marked lines, copy `harness/templates/auto/`, add the `auto:` block with `enabled: false`, add `_harness/auto/logs/` to `.gitignore`, and ask about `mode.bug_repro: fullstack`.

## Skip if

The owner wants to approve every plan, or the project has no roadmap module.
