---
id: locators-a-change-makes-ambiguous
title: Locators a change makes ambiguous
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [testing, e2e] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Locators a change makes ambiguous

Seed checklist item 23 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Locators a change makes ambiguous.** When a plan adds repeated elements (headings, disclosures, list items), an element that broad locators would also match, an always-mounted live region or status element, a control whose accessible name contains an existing control's name, a new item in a keyboard order, or a page in a literal list in tests, it greps the tests for locators and lists that the change breaks (element counts, unscoped role queries, non-exact name matches, tab-order and page lists). When it removes a theme or mode, it greps the helpers that emulate it. When it adds external links to a page built as inline HTML, it greps that page's tests for bans on external references.

## Why

New disclosures broke heading counts; an empty status region broke two page-wide status queries; a name containing an existing name made substring locators ambiguous.

## How to check

each locator grep and its hits. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
