---
id: 2026-11-07-bug-one-qa-run
title: "A trial switch for bug mode with one QA run: Full-stack commits the failing test first"
kind: rule
release: v0.17.0
applies_to: { modules: [] }
files:
  - harness.config.yml
  - scripts/handoff.sh
  - scripts/plan-brief.sh
  - harness/MODES.md
  - harness/HANDOFFS.md
  - harness/TECHNICAL_LEAD.md
  - harness/SETUP.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/templates/progress.md
  - harness/templates/qa-result.md
  - harness/templates/bug-plan.md
removed: []
reviewed: "It adds one config key, mode.bug_repro, whose default (qa) keeps bug mode as it was. No guard rule or settings value changes. With fullstack, the test-first order is checked by handoff.sh (reads only) and by QA."
---

## What changed

- **`harness.config.yml`**: `mode.bug_repro: qa` (default, unchanged behaviour) or `fullstack` (a trial).
- With **`fullstack`**, bug mode's steps 2 and 3 are one Full-stack run ([MODES.md](../template/harness/MODES.md) § Bug mode, "One QA run"):
  - Full-stack writes the regression test and records the failure in `progress.md` § Reproduction (new template section).
  - It commits the test alone as `WIP(<slug>): failing test`, the branch's first change outside `_harness/`.
  - When the test doesn't fail for the reported reason, it hands back without a fix.
  - Then it writes the root cause and the fix as before.
- **`scripts/handoff.sh`**:
  - `fullstack-bug` prints the new `### Full-stack engineer, bug mode with its own reproduction` block.
  - `qa-repro` refuses (exit 2), since there is no reproduction run.
  - `qa` on a bug plan fills a new **Bug order** line. It reads only the branch's own commits (none reachable from the integration or production branch, so a merge of either and a round-2 `--base` don't change it) and checks three things: exactly one failing-test commit, which holds only files matching `.claude/rules/testing.md`'s `paths:` (braces expanded); no product change before it; and the test unchanged since, in later commits and the work tree. It prints `ok: …` or `PROBLEM: …`, the product files the branch changed (the ones QA puts back), and any other test file changed since, for QA to check. An unknown `mode.bug_repro` value is reported and read as `qa`.
- **QA** (`harness/agents/qa-engineer.md` § Bug mode (its first line and last paragraph); the QA block's Bug order line):
  - A PROBLEM is a fail.
  - QA also runs the regression test against the product files as they were at the failing-test commit (backups, restored after), and records the run in `qa-result.md` § Reproduction. A test that passes there is a fail.
- **`scripts/plan-brief.sh --bug`** names `handoff.sh fullstack-bug` as the next step under the trial.
- **`harness/TECHNICAL_LEAD.md`**, **`harness/SETUP.md`** (the mode table), **`harness/HANDOFFS.md`** § Mandatory flow, **`harness/agents/fullstack-engineer.md`** § Bug mode and **`harness/templates/bug-plan.md`** § Regression test (sibling tests go in later commits, in their own file) are updated to match.

## Why

In the benchmark's one-line bug fix the QA reproduction run was a third of the cost. Test-first and root-cause-first stay. What the trial gives up is a second agent reading the bug before the fix; the order is checked by a script and by QA instead of being split across agents. It stays behind a switch so a rerun can compare both settings.

## How to apply

1. Add `bug_repro: qa` under `mode:` in `harness.config.yml`, with the kit's comment (the owner approves the edit).
2. Copy `scripts/handoff.sh` and `scripts/plan-brief.sh` from the kit.
3. Add the kit's `### Full-stack engineer, bug mode with its own reproduction` block and the QA block's `Bug order (…)` line to `harness/HANDOFFS.md` § Subagent prompt blocks.
4. Take the kit's paragraphs: `harness/MODES.md` § Bug mode ("One QA run"), `harness/agents/fullstack-engineer.md` § Bug mode (last paragraph), `harness/agents/qa-engineer.md` § Bug mode (its first line and last paragraph), the `harness/TECHNICAL_LEAD.md` bug-mode sentence, the `harness/SETUP.md` mode-table row, the `harness/HANDOFFS.md` § Mandatory flow bug-mode line, and the template sections (`progress.md` § Reproduction, the note in `qa-result.md` § Reproduction, `bug-plan.md` § Regression test's first line).
5. To try it, set `bug_repro: fullstack`.

## Skip if

Your project doesn't use bug mode.
