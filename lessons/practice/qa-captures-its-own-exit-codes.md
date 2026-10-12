---
id: qa-captures-its-own-exit-codes
title: QA records its own exit codes
kind: agent-rule
target: harness/agents/qa-engineer.md
in_template: true
tags: { stack: [], service: [], area: [qa] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# QA records its own exit codes

## Rule

QA captures the exit code of every check it reports, including the full browser suite, from its own run; reading a log or another agent's exit file is not a recorded result.

## Why

QA's run is the merge gate when CI is off, and a log read once passed as a full-suite result.

## How to check

`qa-result.md` lists each check with an exit code from QA's own run on the final commit.
