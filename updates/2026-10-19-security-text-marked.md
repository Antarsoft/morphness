---
id: 2026-10-19-security-text-marked
title: Security wording marked so projects without the module don't load it
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/rules/technical-lead.md
  - harness/SETUP.md
  - harness/HANDOFFS.md
  - harness/README.md
  - harness/modules/security/README.md
removed: []
---

## What changed

The "with the `security` module" clause in the Technical Lead rule, and the same wording in
`harness/SETUP.md` and `harness/HANDOFFS.md`, are now marked `module:security`, so a project without
the module no longer carries them. The module marker command also covers `.claude/rules/`. The kit
self-test fails when a project without the module still has security module text.

## Why

A project installed without the security module still loaded a sentence in every session that
pointed at a `plan.md` § Security section it doesn't have.

## How to apply

Only for a project that does not have the `security` module (`modules` in `harness.config.yml`): in
`.claude/rules/technical-lead.md`, change the review bullet to "When the plan's Full-stack effort is
`xhigh`, run …" (drop "or, with the `security` module, the plan … says Security feature: yes …").
In `harness/SETUP.md` and `harness/HANDOFFS.md`, drop the "or, with the `security` module, a
security feature" wording the same way. Projects with the module need nothing.
