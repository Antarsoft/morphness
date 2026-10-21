---
id: 2026-10-21-pr-stays-draft
title: A feature PR is ready only when no more code will land on its branch
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/RELEASE.md
removed: []
---

## What changed

`harness/RELEASE.md` § Feature PRs: the Ready bullet now starts "only when no more code will land on the branch".

## Why

A PR was marked ready for the owner's review, then gained code on the same branch, so "ready" no longer meant that the reviewed state was final.

## How to apply

In your `harness/RELEASE.md` § Feature PRs, change the start of the Ready bullet from "**Ready** once QA **pass**" to "**Ready** only when no more code will land on the branch, once QA **pass**". Nothing else changes.
