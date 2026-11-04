<!-- One file per feature: _harness/learnings/<feature-slug>-v<version>.md, the feature's closing record and its retro, written by the Technical Lead on the feature branch (harness/SETUP.md § Retrospective).
     Never write into _harness/LEARNINGS.md itself: parallel branches would conflict there. The prune condenses the entry to one line in LEARNINGS.md § Entries, moves each action item row to the matching LEARNINGS.md table, and deletes this file.
     The number of *-v*.md files in _harness/learnings/ is the prune counter. -->

# <feature-slug> v<version> learnings

### <feature-slug> v<version>, YYYY-MM-DD
- **Verdict:** pass | failed-escalated; QA rounds: N (small mode: `QA rounds: none (small mode)`); review round: yes | no
- **Failure causes:** plan gap ×N, implementation ×N, environment ×N, process ×N (or none)
- **Cost:** ≈ $<total> (Technical Lead $…, Full-stack $…, QA $…, any other subagent $…), pasted from `bash scripts/feature-cost.sh`, or `not measured (<reason>)`; Full-stack <model> <effort> <duration> / <tool calls>; QA <model> <effort> <duration> / <tool calls> (from each completion notice, one entry per round)
- **Trial:** <trial-slug> (only when this feature ran a trial from `_harness/trials/`; add `, reverted: <why>` when it hit the revert condition; omit otherwise)
- **Fired:** <source slug of each tagged rule (`(from <slug>, <date>)`) that caught or prevented something in this feature; omit when none>
- **Escaped:** <feature that passed QA with this bug, and the AC or check that missed it> (bug-fix features only; omit otherwise)
- **Lessons:** 1 to 3 one-liners, or omit when the feature taught nothing new

## What went wrong

Only what did: a failed QA round, a review finding that needed a fix, a human correction or unblock, rework, an agent that stopped or failed, a bug found after a pass. One line each, tagged with its cause and its evidence (the round, the finding, the message, the file). Nothing went wrong: write `None.` and no action items.

1. (cause: plan gap | implementation | environment | process) what happened; evidence

## Action items

Only from the lines above, as many as they call for and never padded (`harness/SETUP.md` § Retrospective). **Why raised** names the line it answers and its evidence. Status: `open` | `approved` | `deferred` (note the feature) | `applied` (Note names the feature or file) | `skipped` (Note says why). The TL's decision, or the human's for an item that adds a human step, changes product behaviour or customer-facing copy, costs money, or is tagged `cause: environment`. Write "None" when there are no items.

| From retro | # | Type | Action | Why raised | Status | Note |
|---|---|---|---|---|---|---|
| <feature-slug> v<version> | 1 | Code / Doc / Harness / Process | | What went wrong #N: <evidence> | open | lands in: <file> |
