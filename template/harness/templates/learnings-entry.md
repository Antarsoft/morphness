<!-- One file per feature: _harness/learnings/<feature-slug>-v<version>.md, written by the Technical Lead with the retro, on the feature branch (harness/SETUP.md § Retrospective).
     Never write into _harness/LEARNINGS.md itself: parallel branches would conflict there. The prune condenses the entry to one line in LEARNINGS.md § Entries, moves each action item row to the matching LEARNINGS.md table, and deletes this file.
     The number of *-v*.md files in _harness/learnings/ is the prune counter. -->

# <feature-slug> v<version> learnings

### <feature-slug> v<version>, YYYY-MM-DD
- **Verdict:** pass | failed-escalated; QA rounds: N; review round: yes | no
- **Failure causes:** plan gap ×N, implementation ×N, environment ×N, process ×N (or none)
- **Cost:** ≈ $<total> (Technical Lead $…, Full-stack $…, QA $…, any other subagent $…), or `not measured (<reason>)`; Full-stack <model> <effort> <duration> / <tool calls>; QA <model> <effort> <duration> / <tool calls>
- **Trial:** <trial name>: <KPI numbers> (only when this feature ran a trial variant; omit otherwise)
- **Escaped:** <feature that passed QA with this bug, and the AC or check that missed it> (bug-fix features only; omit otherwise)
- **Lessons:** 1 to 3 one-liners
- **Retro:** [retro.md](../features/<feature-slug>/<version>/Plan/retro.md)

## Action items

Status: `open` | `approved` | `deferred` (note the feature) | `applied` (Note names the feature or file) | `skipped` (Note says why). The TL's decision, or the human's for an item that adds a human step, changes product behaviour or customer-facing copy, or costs money. Write "None" when the retro has no items. **Why raised** is copied from the retro: the finding the item answers and its evidence.

| From retro | # | Type | Action | Why raised | Status | Note |
|---|---|---|---|---|---|---|
| <feature-slug> v<version> | 1 | Code / Doc / Harness / Process | | What to improve #N: <evidence> | open | lands in: <file> |
