---
id: release-from-qa-tested-commit
title: Cut the release from the QA-tested commit
kind: rule
target: harness/RELEASE.md
tags: { stack: [], service: [], area: [release] }
evidence: { fired: 2, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Cut the release from the QA-tested commit

## Rule

When the integration branch moves during release QA, the release PR is cut from a release branch at the commit QA tested, not from the moving integration branch.

## Why

Two releases picked up dependency bumps and docs merged during QA that no release QA had covered.

## How to check

The release PR's head equals the commit named in the release `qa-result.md`.
