---
id: 2026-10-16-one-owner-per-rule
title: One owner per rule, and settings and hooks are never "docs only"
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/CONTROLS.md
  - project/CONTROLS.md
  - project/HARNESS_AGENTS.md
  - harness/templates/plan.md
  - harness/HANDOFFS.md
  - harness/SETUP.md
  - harness/MODES.md
  - harness/PLAN_CHECKLIST.md
  - harness/agents/qa-engineer.md
  - harness/modules/ci-cd/README.md
  - harness/modules/ci-cd/github/ci.yml
  - harness/modules/claude-projects/README.md
  - harness/modules/roadmap/README.md
  - _harness/README.md
removed: []
---

## What changed

Rules that were written out in several files now live in their owner file, with links elsewhere
(`harness/README.md` § Rule owners). The process is the same, with one exception: changes to
`.claude/settings.json`, hook scripts and skill scripts no longer count as documentation, so they
get every check.

- **Documentation paths:** `harness/CONTROLS.md` § Documentation paths is the only list.
  `project/CONTROLS.md` § Documentation paths now holds only this project's additions and removals.
  `.claude/` as a whole is replaced by `.claude/agents/` and `.claude/rules/`, and `.agents/` by its
  `*.md` files (already covered by "any `*.md`").
- **Effort and where QA can run:** `project/HARNESS_AGENTS.md` keeps its agents table, risk areas
  and environment table, and links `harness/SETUP.md` for the levels, how to choose one, splitting
  by risk and the QA order. The plan template's **Agent effort** lines link there too.
- **Plan status:** § Approval in `plan.md` no longer has a **State** line; the **Status** line at the
  top says whether the plan is approved, and § Approval records who and when.
- **Smaller ones:** the QA body links `CONTROLS.md` § Merge gate instead of restating it; checklist
  items 39 and 40 link their owner sections; the claude-projects README links `HANDOFFS.md` §
  Threads instead of repeating it; the roadmap README uses the template's section names (**Human-only
  steps from features**); `_harness/README.md` shows `steps.md` for when the roadmap module is off.

## Why

Each copy drifted on its own (two names for the same checklist section, two different documentation
lists), and the documentation list let a change to `.claude/settings.json` or a hook skip every
check, though those are the most security-relevant files in the repo.

## How to apply

1. `harness/CONTROLS.md` § Documentation paths: take the kit's paragraph, then carry any project
   changes from it into `project/CONTROLS.md` § Documentation paths as a bullet each. Any path the
   project's old `project/CONTROLS.md` list had beyond the kit's becomes a bullet there too.
2. With the `ci-cd` module, rebuild `DOCS` in the CI workflow so it no longer matches
   `.claude/settings.json`, hooks or skill scripts (for example `\.claude/(agents|rules)/` in place of
   `\.claude/`). Show the owner the old and new regex.
3. `project/HARNESS_AGENTS.md`: replace the generic effort table, "Choosing a level", "Split large
   features by risk" and the QA order and concurrency bullets with the kit's links. Keep the project's
   own risk areas, environment table, seed data and any bullet a retro or prune added (with its
   provenance); a project-specific effort tweak stays as a bullet in § Effort per feature.
4. In open plans, drop the **State** line from § Approval only if **Status** already says the same.
5. Take the remaining text changes as they are.

## Skip if

Never for step 1 and 2. The rest is cleanup a project may skip when it has already reworded those
files.
