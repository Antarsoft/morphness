---
id: 2026-11-02-checks-as-code
title: The fast checks run as code when a task ends
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/settings.json
  - harness.config.yml
  - harness/CONTROLS.md
  - harness/GUARD.md
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/STRATEGY.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/modules/security/README.md
  - harness/templates/progress.md
  - harness/templates/qa-result.md
  - harness/templates/small-plan.md
  - project/CONTROLS.md
  - scripts/checks.sh
  - scripts/guard.sh
removed: []
reviewed: "It adds two hooks (Stop, and SubagentStop for the Full-stack agents) that run scripts/checks.sh, and one allow rule for that script; no settings deny or ask rule changes. The script runs only the commands in project/CONTROLS.md as committed on the integration branch, never a working-copy edit, and never prints a secret scan's log. harness.config.yml gains checks.on_stop and checks.stop_retries. The guard gains one entry: a tool-call write to .git/morphness/ (the check records) asks. GUARD.md says the hook runs outside the guard, with no prompt, and runs code agents wrote, as a test run does."
---

## What changed

- **New `scripts/checks.sh`.** It runs named checks as code and records each result in the git folder, keyed by the content of every file that isn't documentation:
  - `hook` is the end-of-task hook;
  - `status` lists the results for the code as it is now;
  - `run <check> ...` runs and records checks in one call.
- **Two hooks in `.claude/settings.json`.** `Stop` (each main chat turn end) and `SubagentStop` for the `fullstack-engineer*` agents run `scripts/checks.sh hook`, which runs the checks in the new `harness.config.yml` → `checks.on_stop` (`typecheck`, `lint`, `unit`; plus `secrets` with the security module):
  - it runs only when the code differs from the integration branch and from the code the checks last ran on, so documentation and `_harness/` edits never rerun them;
  - a pass prints nothing and costs no model turn;
  - a failure sends the agent back with the check, its exit code and the end of its log; a fix that still fails sends it back again, at most `checks.stop_retries` (2) times in a row, and finishing with no code change since the failure isn't sent back.
- **Commands come from the integration branch.** The hook runs outside the guard, so it reads `project/CONTROLS.md` § Named checks as merged, never the working copy. The new § End-of-task checks → **Run through:** names a wrapper or lock command each check runs inside. `harness/GUARD.md` § What it does not see says what that means: like any test run, the hook runs code agents wrote, with no prompt, and an agent that moves the integration branch in its own clone gets around the merged-commands rule.
- **Records are guarded.** `scripts/guard.sh` asks before a tool-call write to `.git/morphness/`, where the records live, so an agent can't write itself a pass.
- **The record replaces the rerun.** Full-stack writes `end-of-task hook` for the `on_stop` checks in `progress.md` § Validation, and small mode does the same in the plan's § Check. QA records `pass (end-of-task hook)` for any check `checks.sh status` shows as passed on the final commit's code, and runs only the rest. The merge gate reads the same `status` (`harness/CONTROLS.md` § End-of-task checks and § Merge gate).

## Why

QA and Full-stack each ran typecheck, lint and unit tests by hand, and each run cost model turns to start, wait for and read, even when everything passed. Run as code, a passing check costs no model turn, and a model sees a check only when it fails.

## How to apply

1. Add `scripts/checks.sh`. Add `".git/morphness/*"` to `GUARD_FILES` in `scripts/guard.sh`, by hand: the guard never lets a tool call write it. Merge `.claude/settings.json`: the `Stop` and `SubagentStop` hooks and the `Bash(bash scripts/checks.sh:*)` allow rule. A trial Full-stack variant needs a name that starts with `fullstack-engineer` for the `SubagentStop` matcher to see it. Claude Code picks up new hooks in a new session, or after you review them in `/hooks`.
2. In `harness.config.yml` → `checks`, add `on_stop` with the fast checks this project has among `typecheck`, `lint` and `unit` (plus `secrets` with the security module), and `stop_retries: 2`. Leave out a check that takes more than a few minutes. The hook runs them with no prompt, so leave `on_stop: []` (off) when your settings don't already allow the check commands without one.
3. Add `project/CONTROLS.md` § End-of-task checks. When `project/agents/qa-engineer.md` names a wrapper that keeps commands on the local stack, or § Shared resources names a lock command, put it on the **Run through:** line in backticks; otherwise leave `none`. Delete the `morph-init: fill` comment under it. Check that each `on_stop` check's Command cell is one command in backticks: a cell with more is recorded as not run.
4. Merge `harness/CONTROLS.md` (§ End-of-task checks, § Merge gate, § Before Full-stack → QA handoff, § Before QA pass → human handoff, § Documentation paths), `harness/GUARD.md`, `harness/HANDOFFS.md`, `harness/MODES.md`, `harness/STRATEGY.md`, both role bodies, the security module README and the three templates.
5. Commit, open the PR and merge it when you're ready (the human's merge, as for any PR): the hook reads the commands from the integration branch. Then change a code file and end a turn; `bash scripts/checks.sh status` should list each `on_stop` check as `pass`.

## Skip if

`checks.on_stop` would be empty: the project has no typecheck, lint or unit command yet. Apply it with the first one.
