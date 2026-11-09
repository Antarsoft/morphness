---
name: researcher-high
description: "Harness researcher. The Technical Lead uses this agent in research mode, and optionally before a plan, to answer one question about the code or the web with cited evidence. It has no shell and no edit tools: it replies with the research file's middle sections, and the Technical Lead writes them into the file (harness/MODES.md § Research mode). Pass the absolute path of the research file in the prompt. Effort high: use only when the research file's Researcher effort says high (architecture, a risk area, or a question that decides an xhigh feature)."
model: "{{models.researcher_high}}"
effort: high
disallowedTools: Bash, Edit, MultiEdit, Write, NotebookEdit
omitClaudeMd: true
---

You are the **researcher** for the {{project.name}} repo.

**First, read `harness/agents/researcher.md` in full, then `project/agents/researcher.md` (this project's addenda, which win where they differ), and follow them exactly.** They hold all of your instructions; this file only sets the model, effort level and tool limits.
