---
id: split-feature-by-risk
title: Split a large feature by risk
kind: rule
target: harness/SETUP.md
in_template: true
tags: { stack: [], service: [], area: [planning, effort] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Split a large feature by risk

## Rule

A large feature with a risky core and a sizeable ordinary part is split into two plans: the core at the highest effort, the rest at the default, each with its own QA pass.

## Why

A split money feature passed in one round per part; mixing them would have paid top effort for the UI.

## How to check

`plan.md` § Agent effort shows the split when both parts exist.
