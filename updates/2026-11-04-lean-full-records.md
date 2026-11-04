---
id: 2026-11-04-lean-full-records
title: A full-mode feature keeps one plan file and one closing record, and prints only the checklist groups it needs
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - _harness/README.md
  - _harness/learnings/README.md
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/MORPHING.md
  - harness/PLAN_CHECKLIST.md
  - harness/README.md
  - harness/SETUP.md
  - harness/STRATEGY.md
  - harness/TECHNICAL_LEAD.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/templates/bug-plan.md
  - harness/templates/learnings-entry.md
  - harness/templates/plan.md
  - harness/templates/prune.md
  - harness/templates/small-plan.md
  - scripts/evidence.sh
  - scripts/feature-cost.sh
removed:
  - harness/templates/feature.md
  - harness/templates/retro.md
reviewed: "It changes the Full-stack engineer's ownership limits in harness/agents/fullstack-engineer.md and the HANDOFFS.md prompt: Full-stack may now edit the facts the plan's steps name in project/PROJECT.md and the domain docs, each with an acceptance criterion QA checks, never PROJECT.md's source-path list and never a doc of rules or process (project/CONTROLS.md, PLAN_CHECKLIST.md, TESTING.md, HARNESS_AGENTS.md, PROCESS.md, RELEASE.md, SKILLS_AND_MCPS.md, project/agents/). The plan checklist's skip conditions are as broad as before or broader. No guard rule, setting, permission or config value changes."
---

## What changed

- **One plan file.** `harness/templates/feature.md` is gone. The owner's request is `plan.md` § Request (what we want, why, what success looks like, constraints, links), and the owner may still draft it.
- **One closing record.** `harness/templates/retro.md` is gone. The feature's learnings file is the closing record, with the retro inside it:
  - the verdict, failure causes and cost lines as before, with each subagent run's duration and tool calls noted as its completion notice arrives (the retro's § Agent runs table is gone);
  - **§ What went wrong**, one line per miss with its cause and evidence, or `None.`;
  - action items, only from those lines.

  `harness/SETUP.md` § Retrospective is shorter. Its rules on items stay: rules come from misses, mechanism over memo, the per-feature review and where items land. The close takes three steps: the cost script, the learnings file written with the file tool, then the commit and the prune counter in one shell call. The prune counter's gauge details moved to § Prune. The prune's fold keeps each § What went wrong line (its cause and a few words) in the condensed `LEARNINGS.md` entry, so later prunes can see a problem come back. `scripts/evidence.sh` now finds a bug-mode feature by its **Escaped** line, since the **Retro:** line is gone. The prune proposal's table links the learnings file instead of a retro run table.
- **Fewer hand-off checks.** `harness/SETUP.md` § After QA pass reads QA's record of the `before_signoff` checks and doesn't run them again. Screenshots are checked once, before QA. The project fact docs are now plan steps that Full-stack writes with the code and QA checks, instead of edits the Technical Lead makes after the pass. The Technical Lead still owns `project/CONTROLS.md` and `project/PLAN_CHECKLIST.md`.
- **Only the checklist groups a plan needs, in one call.** The group index moved from `harness/PLAN_CHECKLIST.md` into `harness/TECHNICAL_LEAD.md` § Before asking for approval, which the main chat reads in full anyway. Its skip conditions match the line under each group heading, and none is narrower than before: Planning, Testing and Process always run, and Security, Data and Release now also name changes to what exists. The main chat prints the rules, the groups that apply and the project checklist in one call. `PLAN_CHECKLIST.md` § Group index points to the new place.

## Why

The full-mode main chat cost more than the agents it ran. A large part of its turns went to records and re-checks that repeated something already on file:
- a second file for the request;
- a 60-line retro template filled even when nothing went wrong;
- a second run of the checks QA had recorded;
- project doc edits after the pass;
- a separate call to read the checklist index.

Each turn re-reads the whole context, so every turn cut saves the most late in a feature.

## How to apply

1. Delete `harness/templates/feature.md` and `harness/templates/retro.md`. Features already under `_harness/features/` keep their `feature.md` and `retro.md` files: they are records.
2. Replace `harness/templates/learnings-entry.md` with the kit's version, and merge § Request and the project-docs sentence under § Implementation steps into `harness/templates/plan.md`.
3. Merge the edited sections: `harness/SETUP.md` § After QA pass, § Retrospective and § Prune; `harness/TECHNICAL_LEAD.md`, including the group index table in § Before asking for approval; `harness/PLAN_CHECKLIST.md` § Group index and the n/a lines of the Testing, Data, Security and Release groups; and the other files listed. Where this project changed a group's range or added a group, keep the index rows in step with its headings.
4. In `harness/agents/fullstack-engineer.md` § Ownership limits, keep any extra paths this project allows.

## Skip if

Never: every mode's look-back now uses the same learnings file.
