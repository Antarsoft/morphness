---
id: deny-rules-match-command-text
title: Deny rules match command text, not intent
kind: agent-rule
target: project/STACK.md
tags: { stack: [], service: [], area: [tooling, safety] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Deny rules match command text, not intent

## Rule

Permission deny patterns match the command text, so a read-only `grep` or `echo` that contains a denied phrase is refused too. Search with the Grep tool or reword the search; never wrap or reword a command to run the denied tool itself, not even with `--help` or a dry-run flag.

## Why

Agents lost turns to refused greps, and a wrapped command reads as a bypass.

## How to check

Plans that need a denied command list it as a human step.
