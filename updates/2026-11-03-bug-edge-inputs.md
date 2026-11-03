---
id: 2026-11-03-bug-edge-inputs
title: A bug fix names and tests the edge inputs next to the symptom, ties included
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/rules/testing.md
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/agents/fullstack-engineer.md
  - harness/templates/bug-plan.md
  - harness/templates/small-plan.md
removed: []
reviewed: "It adds one sentence to the bug fix bullet of the path rule .claude/rules/testing.md, asking the regression test to cover the edge inputs the plan names; no setting, guard rule, permission or config value changes."
---

## What changed

- **`harness/templates/small-plan.md` § Bug and `harness/templates/bug-plan.md` § Regression test** gain an **Edge inputs** line: the inputs next to the symptom that the fix must also get right, those that apply, each one in the test. They are equal values (two items with the same sort key or timestamp), none, one, exactly at a limit or page edge, and a last page that is not full. A bug where none apply writes one `n/a` line. When the bug is in an order, the order ends with a unique key such as the id, so items with equal values keep one order every time. Only the reported case must fail before the fix; the edge cases may pass.
- **The fix covers them too.** `harness/MODES.md` § Fixing a bug and § Bug mode, the bug-mode prompt blocks in `harness/HANDOFFS.md` and `harness/agents/fullstack-engineer.md` § Bug mode say the fix holds for the edge inputs, and the checks after the fix look for them. QA's reproduction block lets it add the edge cases and no longer asks every test to fail today, only the reported case.
- **`harness/templates/small-plan.md` § Check**, the bug fix line: the test passes with its edge inputs.
- **`.claude/rules/testing.md`**, the bug fix bullet: the regression test also covers the plan's edge inputs.

## Why

A paging fix sorted by a timestamp alone passed its regression test, yet items with equal timestamps could still move between pages. The test checked the reported case only, and the fix stopped once that test was green. Naming the inputs around the symptom in the plan puts them in the test and in the fix.

## How to apply

1. Add the **Edge inputs** line to `harness/templates/small-plan.md` § Bug, before **Root cause**, and to `harness/templates/bug-plan.md` § Regression test, after **Fails today because**. Merge the small plan's § Check bug fix line.
2. Merge the edge input wording in `harness/MODES.md` § Fixing a bug (the **Plan**, **Failing test first** and **Root cause** bullets) and § Bug mode steps 3 and 4.
3. Merge the two bug-mode prompt blocks in `harness/HANDOFFS.md` (QA engineer, bug reproduction; Full-stack engineer, bug mode) and step 2 of `harness/agents/fullstack-engineer.md` § Bug mode. Keep any project wording in them.
4. Merge the sentence in the bug fix bullet of `.claude/rules/testing.md` § When to add tests.

## Skip if

Never: every install fixes bugs.
