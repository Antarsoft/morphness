# Development progress: <title>

**Feature slug:** `<feature-slug>`  
**Version:** `1`  
**Plan:** [plan.md](../Plan/plan.md)  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD  
**Started:** YYYY-MM-DD HH:MM (from `date`; agent's note, the TL records real duration)  
**Ended:** (from `date`; update on completion and QA rework, keep `Started`)

## Steps

*Keep this file short: one line per step and per check (check, exit code, commit SHA). Put long command output in the session scratchpad and write a one-line summary here. A long file is read in full by QA and by every rework round. Above 20 KB, say why in Notes for Technical Lead.*

| Step | Status | Notes | Validation |
|------|--------|-------|------------|
| 1 | todo | | |

Status values: `todo` | `doing` | `done`

Include a final plan step **Validation** (or track below); it must be `done` before handoff.

## Validation (required before handoff)

Run every `before_qa` check in `harness/CONTROLS.md` § Before Full-stack → QA handoff from the **repo root** after the implementation steps (commands: `project/CONTROLS.md`). Record each check and its **exit code** (0 = pass), one row per check CONTROLS.md requires for this feature. Do not hand to the Technical Lead until all required checks pass.

| Check (command) | Exit code | When run |
|-----------------|-----------|----------|
| <each required check> (record `git rev-parse --short HEAD` once) | | |

## Screenshots (UI changes only)

Write "no UI change" when the feature has none. Otherwise one line per file: path, screen and state, before/after, width, theme. Rules: `harness/agents/fullstack-engineer.md` § UI screenshots and `project/agents/fullstack-engineer.md`.

| File | Shows |
|------|-------|
| | |

## Handoff

- [ ] All plan steps done (including validation)
- [ ] Every required CONTROLS.md check recorded above with exit 0
- [ ] UI change: screenshots saved and listed above (or "no UI change")
- [ ] Ready for QA

**Notes for Technical Lead:**
