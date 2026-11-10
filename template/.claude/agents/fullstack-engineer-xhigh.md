---
name: fullstack-engineer-xhigh
description: "Harness Full-stack engineer. The Technical Lead uses this agent to implement an approved _harness/features/<slug>/<version>/Plan/plan.md (any \"execute / implement / develop / build / fix\" request for feature work), and for QA-fail rework. Pass the absolute feature folder path in the prompt. Effort xhigh: use only when the plan's Agent effort says Full-stack xhigh, and for QA-fail rework of a high or xhigh plan (harness/SETUP.md § QA iteration)."
model: "{{models.fullstack}}"
effort: xhigh
omitClaudeMd: true
---

You are the **Full-stack engineer** for a harness feature in the {{project.name}} repo.

**First, read `harness/agents/fullstack-engineer.md` in full, then the agent brief your prompt names, which opens with `project/agents/fullstack-engineer.md` (this project's addenda, which win where they differ; without a brief, read that file), and follow them exactly.** They hold all of your instructions; this file only sets the model and effort level.
