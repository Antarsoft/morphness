---
id: cloud-sessions-cannot-push-tags
title: Cloud sessions can't push tags
kind: rule
target: harness/RELEASE.md
in_template: true
tags: { stack: [], service: [claude-code-web], area: [release] }
evidence: { fired: 2, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Cloud sessions can't push tags

## Rule

In a cloud session the git proxy refuses tag pushes, so the release steps give the tag push to the human.

## Why

Two releases stalled on a 403 at the tag step.

## How to check

The release steps file lists the tag push as a human step.
