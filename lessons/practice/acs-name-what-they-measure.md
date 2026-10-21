---
id: acs-name-what-they-measure
title: Acceptance criteria name the seam and the branch they run on
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
tags: { stack: [], service: [], area: [testing, planning] }
evidence: { fired: 3, features: 14, source: "prune audits" }
added: 2026-10-21
reports:
  - { fired: 3, features: 14, source: "prune audits", added: 2026-10-21 }
status: active
---

# Acceptance criteria name the seam and the branch they run on

## Rule

**ACs name how their check will run.** An AC that needs a forced failure names the test seam that forces it, or is a unit AC. An AC for an error or not-found page is run on the integration branch at plan time. A spec is named as coverage only after grepping it for the control, and seeded limits are checked against schema constraints. (Layout sizes, overflow and element counts: `measured-layout-acs`.)

## Why

Plan gaps across three features: failure criteria with no way to force the failure, error pages that already behaved differently on the base branch, and specs named as coverage that never touched the control.

## How to check

The AC list shows the seam, the base-branch run or the grep for each item that needs one.
