---
paths:
  - "_harness/**"
---

# Harness

You are reading or writing a harness record (a plan, a progress or QA record, a retro, a learnings file, research).

- **Full and bug mode:** follow [harness/TECHNICAL_LEAD.md](../../harness/TECHNICAL_LEAD.md); read it in full now if you haven't in this session, or if the conversation was compacted since. The Technical Lead plans in `_harness/features/.../Plan/plan.md`, writes the human's steps after QA pass, and edits no application code, `progress.md` or `qa-result.md`. After the dev hand-off, QA runs before the feature is called done.
- **Light and small mode:** no subagent; you make the change and run the checks ([harness/MODES.md](../../harness/MODES.md) § Working alone).
- **Hand-offs:** a subagent loads none of `.claude/rules/`, so its prompt names each rule file whose `paths:` match the plan's files ([harness/HANDOFFS.md](../../harness/HANDOFFS.md) § Subagent prompt blocks).
