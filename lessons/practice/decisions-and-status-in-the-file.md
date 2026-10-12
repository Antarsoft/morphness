---
id: decisions-and-status-in-the-file
title: Decisions and status in the file
kind: checklist-item
target: harness/PLAN_CHECKLIST.md
in_template: true
tags: { stack: [], service: [], area: [process] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Decisions and status in the file

Seed checklist item 39 in `harness/PLAN_CHECKLIST.md`. Install it there, or in `project/PLAN_CHECKLIST.md` if your harness predates it.

## Rule

**Decisions and status in the file.** Every decision the owner makes in chat is a dated line in `plan.md` § Decisions in the same turn, and the plan's Status and § Approval are set before the first delegation; the next agent reads the file, not the chat. A plan step that edits a TL-owned doc says so, so the builder leaves it to the TL.

## Why

A builder stopped on a plan that still said pending; a decision left in chat was lost at a thread hand-over.

## How to check

§ Decisions matches the chat; Status reads approved before delegating. Record the result in `plan.md` § References → **Greps**, or "n/a" with a reason.
