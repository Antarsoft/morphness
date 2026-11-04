---
id: 2026-11-02-small-bug-fixes
title: A bug fix off the risk paths runs in small mode, failing test first
kind: rule
release: v0.16.0
applies_to: { modules: [] }
files:
  - .claude/rules/testing.md
  - AGENTS.md
  - harness/MODES.md
  - harness/MORPHING.md
  - harness/SETUP.md
  - harness/TECHNICAL_LEAD.md
  - harness/templates/prune.md
  - harness/templates/small-plan.md
removed: []
reviewed: "Its only .claude/ file is .claude/rules/testing.md, where one sentence names the small-mode fix as its own failing-test proof; no settings, guard, permission or config change."
---

## What changed

- **The risk check picks a bug fix's mode too.** For a bug fix, the Technical Lead now names the files the fix will touch and runs `bash scripts/risk-check.sh <files>` (`harness/MODES.md` § Choosing mode, step 2):
  - `Mode: full` → bug mode, as before (QA writes the failing test, Full-stack fixes, QA re-runs).
  - `Mode: plain` → small mode, with the new § Fixing a bug.
  - A production hotfix is bug mode whatever the script prints.
- **New `harness/MODES.md` § Fixing a bug.** The main chat keeps bug mode's order, alone:
  - the regression test is written, run and committed alone (`WIP(<slug>): failing test`) before any fix;
  - the root cause is written down before the code changes;
  - the fix is the smallest one that turns the test green;
  - the learnings file keeps bug mode's **Escaped** line and its action item.

  A fix that turns out to need a risk path, or a bug no automated test can reach, goes to bug mode; so does a fix the hand-off risk check sends to `Mode: full`, which reuses the failing-test commit. Same-pattern hits are fixed only once the human adds their files to the plan.
- **Proof at the end.** The small plan's § Check shows the regression test failed at the failing-test commit, passes now, is unchanged since, and that the reproduction no longer shows.
- **`harness/templates/small-plan.md` gains § Bug.** It holds the symptom, what should happen and its source, the reproduction, the regression test with its failing-test commit, and the root cause. Delete it for anything that isn't a bug fix.
- `AGENTS.md`, `harness/TECHNICAL_LEAD.md`, `harness/SETUP.md` (the mode table and the prune's Escaped list), `harness/MORPHING.md` and `harness/templates/prune.md` (escapes for trials) and `.claude/rules/testing.md` say the same.

## Why

A small fix off every risk path still ran a bug plan, Full-stack and QA runs, and cost several times a plain session for the same fix. The risk check already decides when a change needs the agents, and the parts of bug mode that make a fix trustworthy (the failing test first, the root cause, the escape line) don't need a second agent.

## How to apply

1. Merge `harness/MODES.md` (§ Working alone, § Small mode with the new § Fixing a bug, § Bug mode → Use when, § Choosing mode step 2) and `harness/templates/small-plan.md` (§ Bug).
2. Merge the mode line in `AGENTS.md` § Golden rules, the bug-report bullet and the command-vocabulary row in `harness/TECHNICAL_LEAD.md`, the mode table and the prune's **Escaped** wording in `harness/SETUP.md`, and the bug-fix line in `.claude/rules/testing.md`.
3. Merge the trial wording in `harness/MORPHING.md` § Trials (step 4) and `harness/templates/prune.md`: escapes now come from small-mode fixes' learnings files too. Open bug plans carry on as written.

## Skip if

Never: every project has bug fixes.
