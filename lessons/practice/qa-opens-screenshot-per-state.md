---
id: qa-opens-screenshot-per-state
title: QA opens a screenshot per planned state
kind: agent-rule
target: harness/agents/qa-engineer.md
in_template: true
tags: { stack: [], service: [], area: [qa, ui] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# QA opens a screenshot per planned state

## Rule

For a UI change, QA opens at least one after-screenshot for every state the plan lists and records which files it opened.

## Why

QA had opened 5 of 24 and 12 of 88 shots on two features, missing visible defects.

## How to check

`qa-result.md` names an opened screenshot for each listed state.
