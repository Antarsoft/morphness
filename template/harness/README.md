# Agent harness (kit)

A **plan → build → QA** workflow for multi-agent development in Claude Code. The Technical Lead plans and delegates in the main chat; a Full-stack subagent builds; a QA subagent validates against testable acceptance criteria; a read-only researcher subagent answers questions about the code or the web when that's all the human wants, or before a plan; the human approves plans, decides merges and runs releases.

This folder is the **kit**. It was installed from Morphness, but it now belongs to this repository and is expected to change: retros and prunes edit it as the project learns ([MORPHING.md](./MORPHING.md)).

## What to read

| Document | Purpose |
|----------|---------|
| [SETUP.md](./SETUP.md) | Runbook: lifecycle, QA rounds, code review, after QA pass, retrospective, prune, effort per feature, where QA can run |
| [STRATEGY.md](./STRATEGY.md) | Agent roles, rules, responsibilities, folder layout |
| [MODES.md](./MODES.md) | Full harness, light mode, bug mode and research mode |
| [HANDOFFS.md](./HANDOFFS.md) | Document ownership, minimum sections, steps file, prompt blocks |
| [CONTROLS.md](./CONTROLS.md) | When each named check runs, command output discipline, cross-cutting paths, the merge gate |
| [RELEASE.md](./RELEASE.md) | Release from the integration branch to the production branch: steps, roles, rollback, hotfix |
| [MORPHING.md](./MORPHING.md) | How this harness changes itself: where lessons land, trials, pruning, sharing upstream |
| [SKILLS_AND_MCPS.md](./SKILLS_AND_MCPS.md) | When to use skills and MCPs (project details in `project/SKILLS_AND_MCPS.md`) |
| [PLAN_CHECKLIST.md](./PLAN_CHECKLIST.md) | The Technical Lead's checklist before asking for plan approval |
| [templates/](./templates/) | `feature.md`, `plan.md`, `bug-plan.md`, `progress.md`, `qa-result.md`, `retro.md`, `prune.md`, `research.md`, `trial.md`, `release-qa-result.md`,<!-- module:roadmap --> `version.md`, `version-checklist.md`,<!-- /module:roadmap --> `learnings-entry.md`, `steps.md` |
| [agents/](./agents/) | Generic role bodies for the Full-stack, QA<!-- module:legal -->, legal-writer<!-- /module:legal --> and researcher subagents (project addenda in `project/agents/`) |
| [modules/](./modules/) | Optional parts, switched on in `harness.config.yml` → `modules` |

## Layers

| Path | Role |
|------|------|
| `harness/` | **Kit**: process, templates, role bodies, modules. Generic prose; owned and morphed by this repo |
| `harness.config.yml` | **Structural facts**: branches, PR host, enabled modules, named checks, CI gate, risk areas, agent levels, loop limits |
| `project/` | **This project's facts**: stack, commands for each named check, cross-cutting paths, effort mapping, project-only checklist items, release specifics |
| `_harness/features/` | **Runtime**: one folder per feature and version |
| `_harness/LEARNINGS.md`, `_harness/learnings/` | **Runtime**: one learnings file per feature until the prune folds it into `LEARNINGS.md` ([SETUP.md § Retrospective](./SETUP.md#retrospective)) |
| `_harness/prunes/`, `_harness/releases/`, `_harness/research/` | **Runtime**: prune proposals, release QA records and research files |
| `AGENTS.md`, `CLAUDE.md` | **Entry points**: agents read these first |

## Modules

Switched on in `harness.config.yml` → `modules`. A module that is off is ignored: its flags in the plan template read `no` or `n/a`.

| Module | Adds |
|--------|------|
| `roadmap` | A roadmap file and per-version docs and checklists; steps files live under the version ([modules/roadmap/](./modules/roadmap/README.md)) | <!-- module:roadmap -->
| `data-access` | QA stages for database schema and access-control features: stage A local, stage B read-only on the integration environment ([modules/data-access/](./modules/data-access/README.md)) | <!-- module:data-access -->
| `browser-e2e` | Browser end-to-end and accessibility test rules, targeted vs full suite ([modules/browser-e2e/](./modules/browser-e2e/README.md)) | <!-- module:browser-e2e -->
| `legal` | The legal-writer flow for legal pages, consent lines and data-handling promises ([modules/legal/](./modules/legal/README.md)) | <!-- module:legal -->
| `ci-cd` | Pipelines the harness sets up and checks: CI running the named checks on PRs, owner-run deploy and migrations workflows, and release tags from the PR title ([modules/ci-cd/](./modules/ci-cd/README.md)) | <!-- module:ci-cd -->
| `claude-projects` | Running the harness in Claude projects: coordinator, one feature per thread, thread effort ([modules/claude-projects/](./modules/claude-projects/)) | <!-- module:claude-projects -->

**Module markers.** Text in the kit that exists only for one module is marked, so adding or removing a module is mechanical: a block between `<!-- module:<name> -->` and `<!-- /module:<name> -->` lines, the same pair inside a line for part of a sentence, or a line (a table row, a list item) ending in `<!-- module:<name> -->`. To remove a module, delete every marked span and line for it:

```bash
m=legal; perl -0pi -e "s/^<!-- module:$m -->\n.*?^<!-- \/module:$m -->\n\n?//msg; s/<!-- module:$m -->[^\n]*?<!-- \/module:$m -->//g; s/^[^\n]*<!-- module:$m -->\n//mg" $(grep -rl "module:$m -->" --include='*.md' harness project .github .gitlab 2>/dev/null)
```

To add one later, copy each marked span for it from the kit's copy of the same file to the same place. Markers of modules that stay are kept. Always-loaded files (`AGENTS.md`, `CLAUDE.md`, `.claude/rules/`), `harness.config.yml` and code blocks carry no markers; each module's § On remove lists their lines.

## Rule owners

Each rule lives in **one** owner file. Every other doc links to the owner instead of restating the rule, so a change lands in one place.

| Rule | Owner file | Everyone else |
|------|-----------|---------------|
| Which checks run when, and which are required | [CONTROLS.md](./CONTROLS.md) | Link to it by section name; never list commands |
| Command for each named check | `project/CONTROLS.md` | (none) |
| Roles and responsibilities | [STRATEGY.md](./STRATEGY.md) | (none) |
| Document ownership, minimum sections, prompt blocks | [HANDOFFS.md](./HANDOFFS.md) | (none) |
| Lifecycle, QA rounds, runbook (review, retro, prune) | [SETUP.md](./SETUP.md) | (none) |
| Effort levels and where QA can run (process) | [SETUP.md](./SETUP.md) | (none) |
| Subagent names, models, effort mapping, project trials | `project/HARNESS_AGENTS.md` | (none) |
| Release flow | [RELEASE.md](./RELEASE.md) | Link to it |
| How the harness changes itself | [MORPHING.md](./MORPHING.md) | (none) |
| TL hard limits (incl. commit policy) | `.claude/rules/technical-lead.md` | `AGENTS.md` keeps a one-line pointer |
| What tests to write and where | `.claude/rules/testing.md` and `project/TESTING.md` | (none) |

## Wired or not

| State | Meaning |
|-------|---------|
| **Installed** | `harness/`, `_harness/` scaffold, `project/` stubs, `AGENTS.md`, `CLAUDE.md`, `.claude/` and `harness.config.yml` exist |
| **Wired** | `harness.config.yml` answered, `project/*` filled (above all a command for every named check in `project/CONTROLS.md`), the checks run green on the current code |

The `/morph-init` skill does the wiring; `/morph-doctor` checks it later and `/morph-update` brings in upstream changes ([MORPHING.md](./MORPHING.md) § Health check and upstream updates). The first feature then starts under `_harness/features/<slug>/1/` from the [templates](./templates/).
