---
id: supabase-confirm-email-before-trust
title: Trust an email only with Confirm email on
kind: checklist-item
target: project/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [supabase], area: [auth, security] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Trust an email only with Confirm email on

## Rule

A plan that trusts the account email (admin lists, customer matching) requires the project's Confirm email setting on in every environment, listed as a prerequisite for the owner.

## Why

With Confirm email off, anyone could sign up with a victim's email and be matched to their records.

## How to check

The plan names the setting and the human step that checks it.
