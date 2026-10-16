---
id: 2026-10-16-checklist-groups
title: Plan checklist groups can be n/a in one line, and check rows follow the config
kind: rule
release: 2026-10-16
applies_to: { modules: [] }
files:
  - harness/PLAN_CHECKLIST.md
  - project/PLAN_CHECKLIST.md
  - harness/templates/plan.md
  - .claude/rules/technical-lead.md
  - harness/templates/release-qa-result.md
  - .github/pull_request_template.md
  - harness/modules/browser-e2e/README.md
removed: []
---

## What changed

- **Plan checklist:** the items and their numbers are unchanged. A group that doesn't fit the project
  or the plan (UI and interaction for a CLI tool or a library, Data for a plan that stores nothing)
  gets one Greps line with its range and the reason, for example `K14–K20 n/a: no user interface`,
  instead of one "n/a" per item. Each group heading says when that is.
- **Check names:** the release QA template has one row per name in `checks.before_signoff`, and the
  PR template's Verification line names `checks.before_qa`, instead of both listing the default
  checks. A project with other checks no longer gets wrong rows.

## Why

On a project that isn't a web app, most of the 40 items were marked n/a one by one on every plan.
The two templates were the last places that hard-coded the default check names.

## How to apply

1. `harness/PLAN_CHECKLIST.md`: take the new "A whole group can be n/a" bullet in § How to use it and
   the italic line under each group heading. Keep the project's own items, numbers and sharpened
   sentences. If the project renamed or regrouped headings, put each italic line under the group that
   matches.
2. `.claude/rules/technical-lead.md` § Before asking for approval, `project/PLAN_CHECKLIST.md` and
   the plan template's **Greps** line: take the wording.
3. `harness/templates/release-qa-result.md` § Checks: replace the fixed rows with the kit's single
   placeholder row. The PR template: replace the named checks in the first Verification line.
4. `harness/modules/browser-e2e/README.md` § On remove: take the wording (the release QA template no
   longer has a browser-e2e row).
