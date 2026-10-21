---
id: nextjs-long-steps-not-inline-in-renders
title: Steps that take minutes don't run inline in a page render
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
tags: { stack: [nextjs], service: [], area: [concurrency, background-jobs, performance] }
evidence: { fired: 3, features: 14, source: "prune audits" }
added: 2026-10-20
reports:
  - { fired: 2, features: 14, source: "prune audits", added: 2026-10-20 }
  - { fired: 1, features: 14, source: "prune audits", added: 2026-10-21 }
status: active
---

# Steps that take minutes don't run inline in a page render

## Rule

**Steps finished from page renders.** A step that a render or sync finishes (an agent run, a git push, a vendor call that can take minutes) runs as a detached command the render only reads, or from the background job or `after()`, never inline in the render. The plan states what two renders at once do (one claims it, the other waits), its time limit counted from a stored start, and what happens when the result landed but the turn still failed, each with a test, and greps the end-to-end specs for any that assume the old timing.

## Why

Two features ran a push or a commit inline in page renders; code and security review found races and double runs in both. A later move of work into `after()` missed end-to-end specs that read the old timing.

## How to check

The plan names the claim/wait rule and the stored start time, and a test covers each case. Grep the changed pages for awaited long calls in the render path. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
