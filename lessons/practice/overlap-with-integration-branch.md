---
id: overlap-with-integration-branch
title: Overlap with the integration branch
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [planning, git] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Overlap with the integration branch

Seed checklist item 3 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Overlap with the integration branch.** Fetch the integration branch (`branches.integration` in `harness.config.yml`) and list what landed on the paths the plan touches: `git log --oneline HEAD..origin/<integration> -- <paths>`. Merge it in or plan around it. Repeat before each dev handoff, and after each merge re-grep the contract the plan changes (a count, a role literal, a field name) over the code merged since approval.

## Why

Parallel work merged mid-build broke a contract the plan had changed.

## How to check

the log output and the re-grep hit counts are in Greps. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
