---
id: fakes-confirmed-against-real-service
title: Confirm platform variables and fakes against the real thing
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
tags: { stack: [], service: [], area: [testing, vendors] }
evidence: { fired: 3, features: 14, source: "prune audits" }
added: 2026-10-20
reports:
  - { fired: 3, features: 14, source: "prune audits", added: 2026-10-20 }
status: active
---

# Confirm platform variables and fakes against the real thing

## Rule

**Platform variables and fakes** (the plan's reading of vendor facts is in `third-party-facts-readable-source`; this is about what the tests run against). A plan whose code reads hosting-platform variables lists the ones the platform sets itself, cited from its docs with the date read, and the tests run with the full set. Every answer a fake of an outside service gives that the code branches on is confirmed against the real service first (a spike or a read-only live check) and cited. A feature driving such a service gets one live run on a preview before it is called done.

## Why

Three bugs passed every check because the checks ran against fakes that answered differently from the real service: the platform set an identity variable itself that the code assumed it controlled, a detached command's exit code stayed null where the fake returned the real one, and a runtime dependency was missing from the real sandbox image.

## How to check

The plan has a cited line per platform variable and per fake answer the code branches on; the QA record shows one live preview run. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
