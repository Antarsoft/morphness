---
id: identity-values-trusted
title: Identity values trusted
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [security, auth] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Identity values trusted

Seed checklist item 30 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Identity values trusted.** A plan that compares or trusts an identity value (an email, a domain, an account id from a third party) names where it comes from, what verifies it and the setting that makes the verification true, and lists that setting as a prerequisite for whoever owns it. A vendor default the design leans on is read from the vendor docs at plan time.

## Why

With email confirmation off, anyone could sign up with a victim's email.

## How to check

source, verifier and setting are named with a cite. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
