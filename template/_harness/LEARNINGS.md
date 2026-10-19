# Harness learnings

Trends across features, one short entry per feature retro (`Plan/retro.md`). Each feature writes its entry and its new action items to **its own file**, `_harness/learnings/<feature-slug>-v<version>.md` ([learnings/README.md](./learnings/README.md)), never to this file, so parallel feature branches don't conflict here. The prune folds those files into this one (§ Entries, § Action items) and deletes them. When a prune is due (§ Prune status), the Technical Lead writes the proposal without waiting for the owner, who then decides its rows.

## Prune status

Procedure: [harness/SETUP.md](../harness/SETUP.md) § Prune. Only a prune edits this table. The count of features since the last prune is the number of feature files in `_harness/learnings/` (`ls _harness/learnings/*-v*.md | wc -l`), not a number stored here, so no feature branch edits this table.

| Field | Value |
|-------|-------|
| Last prune | none yet |
| Counting from | the start; every file in `_harness/learnings/` counts |
| Threshold | `loop.prune_every` in `harness.config.yml` |

The prune is `DUE` when `_harness/learnings/` holds Threshold feature files or more, `ok` below that. After a prune is approved and applied: set Last prune to the date and the proposal path (`_harness/prunes/<date>.md`) and Counting from to the newest folded entry; the folded files are deleted, so the count starts again from 0. When this file grows long, a prune may move closed rows and old entries to `LEARNINGS-archive.md` and link it here.

## Entry format

```markdown
### <feature-slug> v<version>, YYYY-MM-DD
- **Verdict:** pass | failed-escalated; QA rounds: N; review round: yes | no
- **Failure causes:** plan gap ×N, implementation ×N, environment ×N, process ×N (or none)
- **Cost:** ≈ $<total> (Technical Lead $…, Full-stack $…, QA $…, any other subagent $…), or `not measured (<reason>)`; Full-stack <model> <effort> <duration> / <tool calls>; QA <model> <effort> <duration> / <tool calls>
- **Trial:** <trial-slug> (only when this feature ran a trial; omit otherwise)
- **Escaped:** <feature that passed QA with this bug, and the AC or check that missed it> (bug-fix features only; omit otherwise)
- **Lessons:** 1–3 one-liners
- **Retro:** [retro.md](./features/<feature-slug>/<version>/Plan/retro.md)
```

The template is also in [harness/templates/learnings-entry.md](../harness/templates/learnings-entry.md).

## Trials

Each trial is its own file in [trials/](./trials/), one per change under trial ([harness/MORPHING.md](../harness/MORPHING.md) § Trials). A feature that ran one says so on its learnings file's **Trial** line; the prune reads the numbers and proposes keep or revert.

## Action items

Every action item from a retro, split by state so open work isn't buried. A new retro's items go in the feature's own file, `_harness/learnings/<feature-slug>-v<version>.md` § Action items (same columns as **Open**), and the decision is recorded there ([harness/SETUP.md](../harness/SETUP.md) § Retrospective); the prune moves them into the tables below. Open work is therefore the **Open** table plus the § Action items of every file in `_harness/learnings/`. Here, when the state changes, **move the row** to the matching table; never edit a status in place. **Why raised** (the finding the item answers and its evidence) moves with the row, so the prune can check whether the problem came back after the item landed.

| State | Meaning | Table |
|-------|---------|-------|
| `open` | Not yet decided | Open |
| `approved` | The Technical Lead (or the owner) said yes, not done yet | Open |
| `deferred` | Reviewed and postponed; note the feature. Deferred at two consecutive retros must be approved or skipped | Open |
| `applied` | Landed; "Where" names the feature or file | Applied |
| `skipped` | The Technical Lead (or the owner) said no; "Why skipped" says why | Skipped |

A new state gets its own table under this heading, with a row added to the list above.

### Open

| From retro | # | Type | Action | Why raised | Status | Note |
|---|---|---|---|---|---|---|

### Applied

| From retro | # | Type | Action | Why raised | Where |
|---|---|---|---|---|---|

### Skipped

| From retro | # | Type | Action | Why raised | Why skipped |
|---|---|---|---|---|---|

## Entries

Entries since the last prune are in `_harness/learnings/` (one file per feature, format above). The lines below are the condensed ones a prune folded in, one each: `- <feature-slug> v<version>, YYYY-MM-DD: <verdict>, QA rounds N, ≈ $<cost>; <lesson> ([retro](…))`. Keep the date: `scripts/prune-counter.sh --prune` counts features since a rule landed from it.

None yet.
