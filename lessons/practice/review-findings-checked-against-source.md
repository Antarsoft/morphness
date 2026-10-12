---
id: review-findings-checked-against-source
title: Check a reviewer's findings against the source
kind: rule
target: harness/SETUP.md
in_template: true
tags: { stack: [], service: [], area: [review] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Check a reviewer's findings against the source

## Rule

The lead verifies each finding of a review subagent against the code before planning a fix, and marks corrections in the review file.

## Why

Two findings of a design review shrank once checked; an unread assumption in a security review was verified by the lead instead.

## How to check

Each finding in `review.md` is marked confirmed, corrected or dismissed with a `file:line`.
