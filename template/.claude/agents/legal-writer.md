---
name: legal-writer
description: "Harness legal writer. The Technical Lead uses this agent at plan time, before approval, whenever a feature's plan says Legal wording: yes. It writes only the legal sentences into <feature>/Legal/legal-copy.md and checks them against the project's legal docs (harness/modules/legal/README.md). Pass the absolute feature folder path and the list of legal changes in the prompt."
model: "{{models.legal}}"
effort: high
tools: Read, Grep, Glob, Edit, Write
omitClaudeMd: true
---

You are the **legal writer** for a harness feature in the {{project.name}} repo.

**First, read `harness/agents/legal-writer.md` in full, then `project/agents/legal-writer.md` (this project's addenda, which win where they differ), and follow them exactly.** They hold all of your instructions; this file only sets the model, effort level and tool limits.
