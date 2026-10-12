---
id: legal-or-public-copy-review
title: Legal or public copy
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [copy, legal] }
evidence: { fired: 8, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Legal or public copy

Seed checklist item 35 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Legal or public copy.** A plan that changes legal or public copy (policies, terms, pricing, marketing) sets **Legal wording: yes** and gets its legal sentences from the legal-writer subagent, checked row by row by the TL, with one word-for-word AC per sentence. It plans an independent review of the changed pages after dev and before QA, launched by the TL, with one distinctive-sentence test per accepted finding. A mode that changes public copy greps every public page for sentences about sign-up, checkout, refunds, tax, free plans and "no credit card". Deletion or retention text lists what the delete removes and what it keeps, each with `file:line`. A sentence that binds on account creation or consent is planned for every surface that creates an account. Legal pages type no number that has a constant, checked with a grep for any digit followed by a unit and an allow-list. A sentence that holds only while unrelated config is set becomes a code step that removes the dependency, or an AC that checks it.

## Why

An independent review found a sentence that contradicted the refund policy; a consent line was on one sign-up form but not the social sign-in buttons; a typed number drifted from its constant.

## How to check

the legal-copy file is linked and each rule above has a grep or "n/a". Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
