---
id: existing-stubs-and-mocks
title: Existing stubs and mocks
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [testing] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Existing stubs and mocks

Seed checklist item 24 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Existing stubs and mocks.** Before planning tests in an existing spec, check that the spec doesn't stub the route or service the new tests depend on. An AC that mocks a failure the real helper can't produce is a plan gap.

## Why

A spec stubbed the very route the new test needed; a mocked impossible rejection invited a defensive code path.

## How to check

grep the spec's route and module mocks. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
