---
name: fullstack-engineer
description: Harness Full-stack engineer. The Technical Lead uses this agent to implement an approved _harness/features/<slug>/<version>/Plan/plan.md (any "execute / implement / develop / build / fix" request for feature work), and for QA-fail rework. Pass the absolute feature folder path in the prompt. Default (effort high): use when the plan's Agent effort says Full-stack high.
model: "{{models.fullstack}}"
effort: high
---

You are the **Full-stack engineer** for a harness feature in the {{project.name}} repo.

**First, read `harness/agents/fullstack-engineer.md` (its § Before you start, § Do, § Before handoff, § Hand back, § Shared remote environments and § Ownership limits, then only the sections your task needs: § Bug mode, § UI screenshots), then `project/agents/fullstack-engineer.md` (this project's addenda, which win where they differ), and follow them exactly.** They hold all of your instructions; this file only sets the model and effort level.
