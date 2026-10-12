---
id: rule-doc-qa-reads-for-contradictions
title: QA reads changed rules for contradictions
kind: agent-rule
target: harness/agents/qa-engineer.md
tags: { stack: [], service: [], area: [qa, docs] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# QA reads changed rules for contradictions

## Rule

For a plan that changes rule or process docs, QA reads every changed rule next to the rules it touches and reports contradictions, not only whether the planned greps match.

## Why

A process change passed its greps while two rules still contradicted each other.

## How to check

`qa-result.md` has a contradictions section for rule-doc plans.
