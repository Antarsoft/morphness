---
id: third-party-facts-readable-source
title: Third-party facts
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [contracts, vendors] }
evidence: { fired: 2, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Third-party facts

Seed checklist item 11 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Third-party facts.** For every fact about another company, service or tool (prices, limits, plan tiers, defaults, field lists, error texts), the plan says whether an agent can read the source from the session. If not, it leaves the fact out or names the human step that supplies it. Read at plan time: the tier a vendor feature needs and whether the account has it; the vendor's changelog for an announced change to a default the plan relies on; the full field list of an endpoint the plan sends data to; the published SDK source when its behavior matters (a local no-op, delete vs invalidate); for customer instructions that set up a third-party client, what the client shows for a rejected credential and how the setup is changed. Behavior that only a real vendor account can confirm is a human step, not an AC.

## Why

A planned schedule was rejected by the vendor's plan tier; a platform default changed under a plan; setup copy quoted errors users never see.

## How to check

each vendor fact cites the line read or the human step. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
