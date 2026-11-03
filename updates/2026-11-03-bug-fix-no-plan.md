---
id: 2026-11-03-bug-fix-no-plan
title: A bug fix off the risk paths writes no plan file, and learnings only when something went wrong
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/rules/testing.md
  - harness/CONTROLS.md
  - harness/MODES.md
  - harness/SETUP.md
  - harness/TECHNICAL_LEAD.md
  - harness/templates/small-plan.md
removed: []
reviewed: "It changes one phrase in the path rule .claude/rules/testing.md: a small-mode bug fix records its negative test run in the fix commit's record instead of the plan's § Bug, which this update removes; no setting, guard rule, permission or config value changes."
---

## What changed

- **`harness/MODES.md` § Fixing a bug** keeps the failing test first, the root cause before the fix, the edge inputs and the checks, but writes no plan file. The record is the commits and the PR, as in light mode:
  - The failing-test commit's message holds the risk check's output, the symptom, what should happen and its source, the edge inputs and the failure's tail.
  - The fix commit's message and the PR hold the commit the checks ran on, the root cause, the **Escaped** line, the proof that the test failed before and passes now unchanged, the checks with their exit codes, screenshots for a UI change, and the hand-off risk check's first line.
  - The owner's report is the approval only for restoring behaviour: what worked before, or what an AC or the docs already promise. A fix that adds behaviour nobody promised is not a bug fix: it gets a small plan the human approves.
  - A fix that needs a risk path goes to bug mode with the failing-test commit and the root cause. A fix that needs new behaviour gets a plan.
  - No learnings file unless something went wrong or the harness should change: the test didn't fail for the reported reason, a check failed after the fix, the fix took more than one try, the hand-off risk check printed `Mode: full`, or the **Escaped** line points to a harness rule, checklist item or named check that would have caught the bug.
- **`harness/templates/small-plan.md`** loses § Bug and the bug fix line in § Check.
- **`harness/CONTROLS.md` § Merge gate**, **`harness/MODES.md` § Working alone, § Small mode and § Choosing mode**, **`harness/SETUP.md`** (the mode table and § Retrospective), **`harness/TECHNICAL_LEAD.md`** and **`.claude/rules/testing.md`** say where a bug fix's record goes.

## Why

A small bug fix the main chat made alone still cost far more than a plain session for the same fix. Most of the extra turns went to the plan file, the check record in it and the learnings file. The commits already carry the failing test and the fix, so they can carry the record too. The trade-off: a clean fix's escape now lives in its commits, where the prune doesn't read it. Only an escape that points to a harness rule or check writes a learnings file, so the prune still sees the ones it can act on.

## How to apply

1. Replace `harness/MODES.md` § Fixing a bug with the new text, and merge the § Small mode, § Working alone and § Choosing mode step 3 sentences that name it. Keep any project wording.
2. Delete § Bug and the `- **Bug fix:**` line of § Check from `harness/templates/small-plan.md`. A small plan in flight that has § Bug can keep it until it closes.
3. Merge the small mode row of the mode table and the sentence in § Retrospective in `harness/SETUP.md`, the two § Merge gate phrases in `harness/CONTROLS.md`, the small mode sentence in `harness/TECHNICAL_LEAD.md` § Must do, and the phrase in the bug fix bullet of `.claude/rules/testing.md`.

## Skip if

Never: every install fixes bugs.
