---
id: every-entry-point-of-an-action
title: Every entry point of an action
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [ui, contracts] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Every entry point of an action

Seed checklist item 16 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Every entry point of an action.** A plan that adds or changes a precondition on an action (start, delete, publish) lists every UI entry point of that action and says whether each one gates it or relies on the server's refusal. An AC that needs a page behind a plan limit or cap names the seed state that reaches it.

## Why

One page disabled the action without its precondition while another did not.

## How to check

grep the action's call sites; each is in the plan. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
