---
id: 2026-10-21-pr-stays-draft
title: A feature PR stays draft while more code will land on its branch
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/RELEASE.md
removed: []
---

## What changed

`harness/RELEASE.md` § Feature PRs gains one bullet between Draft and Ready: the PR stays a draft while more code will land on the branch, and docs-only work that shares a branch with a build gets its own PR.

## Why

A PR was marked ready for the owner's review, then gained code on the same branch, so "ready" no longer meant that the reviewed state was final.

## How to apply

Add the bullet to your `harness/RELEASE.md` § Feature PRs, before the Ready bullet. Nothing else changes.
