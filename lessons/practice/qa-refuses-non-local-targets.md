---
id: qa-refuses-non-local-targets
title: QA scripts refuse non-local targets
kind: agent-rule
target: harness/agents/qa-engineer.md
in_template: true
tags: { stack: [], service: [], area: [qa, data, safety] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# QA scripts refuse non-local targets

## Rule

QA runs every command that talks to the app's database or backing services through a wrapper that loads the local environment file and exits unless every database and service URL is local, from the first command. An env-file flag does not override variables already set in the session.

## Why

A QA script reached a shared remote environment with anonymous calls because session variables won over the local env file.

## How to check

The QA log shows the wrapper's local-target check before the first data call.
