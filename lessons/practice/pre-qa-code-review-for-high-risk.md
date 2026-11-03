---
id: pre-qa-code-review-for-high-risk
title: Run a read-only code review before QA on high-risk work
kind: rule
target: harness/SETUP.md
in_template: true
tags: { stack: [], service: [], area: [review, security] }
evidence: { fired: 6, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Run a read-only code review before QA on high-risk work

## Rule

When a plan touches a risk path (money, tenancy, auth, migrations, code on customers' sites) or its Full-stack effort is the highest level, a read-only code review runs after dev and before QA, and a security review too when the change touches sign-in, access rules, money or a public API. The security review lists the files it read in full and its tool-call count; a pass of a handful of calls doesn't count. The lead checks every finding against the source before acting on it.

## Why

Pre-QA reviews found real issues in most high-risk features (a cross-account path, an inverted pending check, a wrapper breakout); thin security passes missed them twice.

## How to check

`review.md` lists findings, files read and tool-call count before QA starts.
