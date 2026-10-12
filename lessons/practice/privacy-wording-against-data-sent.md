---
id: privacy-wording-against-data-sent
title: Privacy and data-handling wording against what is sent
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [copy, privacy, legal] }
evidence: { fired: 3, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Privacy and data-handling wording against what is sent

Seed checklist item 34 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Privacy and data-handling wording against what is sent.** Claims about what the product sends, stores or does not do are diffed against the published privacy pages and against the exact payload, stored keys and fields the code sends, before approval; every class of data the code sends appears in the wording. An inventory of what the product stores in the browser includes scripts loaded by layouts and the content-security-policy sources. A sentence about what a vendor records cites a sample of the recorded values or the request's origin, not only that a column exists. When a plan adds a stored key or a field sent off-device, it greps the privacy pages for it.

## Why

Draft copy said "only the account id" while labels were sent too; a storage inventory missed the product's own script in the root layout.

## How to check

the diff and the payload table are in the plan. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
