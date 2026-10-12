---
id: concept-grep-every-affected-file
title: Every affected file
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [planning, refactor] }
evidence: { fired: 2, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Every affected file

Seed checklist item 6 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Every affected file.** For a rename, a removed behavior or a cross-file doc or rule change, run a case-insensitive whole-repo grep for the concept in every spelling (hyphenated, spaced, camel case), including docs, checklists, CI and bot config. Each hit is in the steps or in the AC's allowed-leftover list. When a gate, redirect or the set of public pages changes, compare it with every list of public routes (sitemap, robots rules, literal lists in tests). When a helper starts running more than once per page load or request, grep it for once-only assumptions (single registrations, unique names).

## Why

Stale doc lines reached QA; a second spelling was missed; a sitemap listed pages a gate still blocked; a policy object created once per page broke when created per call.

## How to check

the greps and their counts are in Greps; every hit is accounted for. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
