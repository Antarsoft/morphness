---
id: ui-screenshots-before-and-after
title: Full-stack delivers before and after screenshots
kind: agent-rule
target: harness/agents/fullstack-engineer.md
in_template: true
tags: { stack: [], service: [], area: [ui, process] }
evidence: { fired: 2, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Full-stack delivers before and after screenshots

## Rule

Every UI change lists before and after screenshots in `progress.md` § Screenshots, at each planned width and theme. After a copy rework round, every shot whose page shows changed text is retaken (grep the changed strings). Screenshot scripts wait for overlay close animations or use reduced motion. The lead checks the files exist before QA and shows them to the human at hand-off.

## Why

Without shots the human signs off a UI change blind; shots taken mid fade-out or before a copy round showed the wrong state.

## How to check

`ls` every file listed in § Screenshots before delegating QA.
