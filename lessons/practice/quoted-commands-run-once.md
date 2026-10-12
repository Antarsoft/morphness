---
id: quoted-commands-run-once
title: Quoted commands
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [planning, tooling] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Quoted commands

Seed checklist item 8 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Quoted commands.** Every command a step or AC quotes is run once by the TL (read-only, or on a scratch copy) or marked "Full-stack to confirm". Grep the deny rules in `.claude/settings.json` for each command an AC needs; a denied command becomes a human step in § QA scope, not an AC.

## Why

A command that looked right failed on the installed tool version; a denied command can't be run by QA.

## How to check

each quoted command has a run result or the marker. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
