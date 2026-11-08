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
  - scripts/auto/run.sh
  - scripts/auto/driver.py
  - scripts/auto/card.sh
  - scripts/auto/tracker.sh
  - harness/README.md
  - harness/templates/plan.md
  - harness/templates/small-plan.md
  - harness/templates/bug-plan.md
  - harness.config.yml
removed: []
reviewed: "It adds a module folder, templates, an auto: config block that is off, lines marked module:autonomous, and a driver under scripts/auto/ that only an owner runs from a terminal. The driver refuses to start inside a Claude Code session, on a dirty tree, with auto.enabled false or a zero budget, starts sessions with --permission-prompts none and --max-budget-usd (never a mode that skips permissions), and pushes only the run and feature branches, never the integration, production or an environment branch. It changes no guard rule or settings file and makes no network call of its own beyond git push. The guard rules for a run are reviewed in their own note; the /morph-auto skill runs none of the driver's run steps itself. On install it adds only read-only allow rules (date, git show, git grep, git rev-parse, a formatter check that writes nothing). Before a run makes a branch it checks the sign-in with `claude auth status` and a one-word session on the small model in an empty temporary folder (under $0.05, same flags); a sign-in error refuses and is never retried as a crash. A not-a-bug card settles only a fix the run inserted, and only with evidence."
---

## What changed

- A new optional module, **autonomous**: the run rules, phases, stop conditions and files for an unattended run that goes from `docs/brief.md` to the first version on its own branch. The owner approves the product docs once; each feature then runs through the normal harness in its own session, and owner items go to the feature's steps file and, through the driver, the version checklist's § Needs you.
- Templates and prompts in `harness/templates/auto/`, and an `auto:` block in `harness.config.yml` (`enabled: false`).
- With the module, one line in each plan template's § Approval points to the run rules. It is marked `module:autonomous`, so installs without the module don't get it. `harness/TECHNICAL_LEAD.md` is unchanged: the driver's prompts point the Technical Lead to the run rules.
- The driver, `bash scripts/auto/run.sh` (`start`, `approve`, `run`, `resume`, `status`, `stop`), with `card.sh` and `tracker.sh`. It keeps the live run state and session logs in the git folder, starts each session with `--permission-prompts none` and `--max-budget-usd`, checks every card against the feature's own records before it merges into the run branch, and redraws `_harness/auto/tracker.md` after each feature.
- The driver checks that Claude Code is signed in before `start`, `run` and `resume` make a branch or a commit, and treats a session that can't authenticate as its own stop (never a crash or a try), with the `/login` steps in `exit.md`. It commits nothing when the director wrote no docs. Sessions stream (`--output-format stream-json`): the terminal shows a line per tool call and "still running" after two quiet minutes, and each session's log (`.jsonl`) is written as it runs.
- A fix the run inserted can end with a `status: not-a-bug` card (`reason:` and `evidence:`), which the driver settles as `skipped`. A § Bugs found line about an assumed decision or an owner item goes to § Needs you instead of a fix. After a "tries used up" exit, resume passes the reason and the stopped card to the retry.
- Feature prompts list the owner's answers recorded since the feature started (their Decisions rows, ticked or annotated owner items), and a `waiting_owner` card whose items are all answered gets one more session with them.
- `auto.session_hours` (default 4): a wall-clock limit for one session. A card lists the items the driver acts on as body sections (§ Owner items, § Bugs found, § Split into), one line each.
- With the module, `/morph-module add autonomous` also adds four read-only allow rules to `.claude/settings.json` (`date`, `git show`, `git grep`, `git rev-parse`) and a read-only formatter check, and offers a `smoke` named check, so a run's sessions, which get no prompts, can check their work.
- The guard rules for a run are in their own note (`2026-11-07-guard-autonomous-run`); the plugin's `/morph-auto` skill prepares each step of a run (brief, budgets, review of the docs, status, stop, resume, the run's PR).

## Why

Owners asked for a way to hand the harness a brief and come back to a built first version, with the guard, checks and QA still in place and every human-only step written down instead of blocking the run.

## How to apply

Offer the module; skip it unless the owner wants it. It needs the roadmap module. On a yes, `/morph-module add autonomous` follows its § On install: put back the marked lines, copy `harness/templates/auto/`, add the `auto:` block with `enabled: false`, copy `scripts/auto/`, and ask about `mode.bug_repro: fullstack`.

## Skip if

The owner wants to approve every plan, or the project has no roadmap module.
