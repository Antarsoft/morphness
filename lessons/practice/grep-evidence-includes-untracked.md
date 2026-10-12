---
id: grep-evidence-includes-untracked
title: Grep evidence covers untracked files
kind: rule
target: harness/CONTROLS.md
in_template: true
tags: { stack: [], service: [], area: [testing, git] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Grep evidence covers untracked files

## Rule

A `git grep` quoted as acceptance evidence runs with `--untracked` (or after the WIP commit).

## Why

Plain `git grep` ignores untracked files, so before a commit it checks nothing new.

## How to check

Every quoted `git grep` in `qa-result.md` has `--untracked` or follows a commit.
