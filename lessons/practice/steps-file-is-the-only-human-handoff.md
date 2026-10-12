---
id: steps-file-is-the-only-human-handoff
title: The steps file is the only human hand-off
kind: rule
target: harness/SETUP.md
in_template: true
tags: { stack: [], service: [], area: [process, release] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# The steps file is the only human hand-off

## Rule

After QA pass, the lead writes one steps file per feature with only what the human must do (and anything QA deferred), or records `none`.

## Why

Several hand-off documents per feature drifted apart; one file lost nothing over a window of features.

## How to check

`plan.md` Steps file line names the file or `none`.
