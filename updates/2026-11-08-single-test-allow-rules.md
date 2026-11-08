---
id: 2026-11-08-single-test-allow-rules
title: Agents can run one test file without a prompt, and QA always writes a result
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/settings.json
  - harness/agents/qa-engineer.md
  - harness/agents/fullstack-engineer.md
  - scripts/auto/driver.py
  - harness/modules/autonomous/README.md
removed: []
reviewed: "It adds allow rules only for a test runner a named check already runs (npx jest, npx vitest run, npx mocha, npx playwright test, pytest, python -m pytest, go test, cargo test), never a bare interpreter, shell or npx alone, and only with the owner's yes. The agent docs add a retry through the named check and a blocked verdict. The driver change only reads the session log it already writes and adds text to exit.md; it runs nothing new."
---

## What changed

- `/morph-init` allows each test runner's own single-file form next to the named check that runs it (`Bash(npx jest:*)` next to `npm test`), so an agent can run one test file or a name pattern without a prompt. `/morph-doctor` warns when a runner has no such rule.
- The QA and Full-stack agent docs say how to run one test file (the runner's form or `<named command> -- <path>`). When a command is refused, QA retries it once through the named check, records it word for word, and never leaves `qa-result.md` missing: it writes **Result:** `blocked: permission` instead.
- With the autonomous module, the driver tells a missing `qa-result.md`, a blocked one and a failing one apart. When a feature exits because its card says passed but QA doesn't, the driver reads the session's log, subagents included, for refused commands, and `exit.md` names them and the allow rule to add.

## Why

In an autonomous run, QA ran one new test file with `npx jest <path>`. Only `npm test` and the scoped jest command had allow rules, so the run refused it with no prompt, and QA never wrote `qa-result.md`. The run stopped on "verdict is not pass", which hid the cause. The session's own list of refused commands was empty, because the refusal happened inside a subagent.

## How to apply

1. For each named check in `project/CONTROLS.md` that runs a test runner, ask the owner once: "Allow `<runner rule>`, so agents can run one test file without a prompt?" On yes, add it to `.claude/settings.json` → `permissions.allow` and list it in `project/SKILLS_AND_MCPS.md` § Permission rules added. A project that answered no to Q14 (`allow_checks: false`) keeps its prompts; skip this step.
2. Merge the two agent docs and, with the autonomous module, `scripts/auto/driver.py` and the module README from the kit.

## Skip if

No named check runs a test runner (step 1 only).
