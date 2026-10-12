# QA result: <title>

**Feature slug:** `<feature-slug>`  
**Version:** `1`  
**Plan:** [plan.md](../Plan/plan.md)  
**Progress:** [progress.md](../Development/progress.md)  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD  
**Started:** YYYY-MM-DD HH:MM (from `date`; agent's note, the TL records real duration)  
**Ended:** (from `date`; separate times per round if using Round 2)

## Environment

*Keep evidence to one line per AC (command or file:line, result). Put long output in the scratchpad. Above 20 KB, say why under Notes.*

- **Branch:**
- **Commit / PR:** (`git rev-parse HEAD`; the merge gate checks the final commit)
- **Checks run:** one line per `before_signoff` check with its exit code (harness/CONTROLS.md § Before QA pass → human handoff), or the reuse record (§ After merging the integration branch)
- **Data-access feature (from plan):** yes | no | n/a
- **Legal wording (from plan):** yes | no | n/a

## Data-access validation

*With the `data-access` module, only when the plan says **Data-access feature: yes**. Copy the stage A table (local, part of this QA pass) from `harness/modules/data-access/README.md` and fill one row per check with its evidence. Delete this section otherwise.*

### Data-access validation: post-apply

*Stage B, read-only on the integration environment, filled in a later short QA pass when the TL asks (after the migrations are applied there). Copy the stage B table from `harness/modules/data-access/README.md`; record the date, the environment id targeted and each query run. Until it runs, write `not run: waiting for the apply`.*

## Legal wording

*With the `legal` module, only when the plan says **Legal wording: yes**. One row per sentence in `<feature>/Legal/legal-copy.md`. A missing or reworded sentence is a fail. Delete this section otherwise.*

| # | Sentence (first words) | Where (`legal-copy.md` target) | Found word for word | Evidence |
|---|------------------------|-------------------------------|---------------------|----------|
| L1 | | | yes / no | |

## Test cases (from acceptance criteria)

| Test case (AC #) | Status | Notes |
|------------------|--------|-------|
| AC-1 | pass / fail / skip / deferred: local | |

*`deferred: local` only for ACs the plan lists under **Needs live app/services**, and only when those services are unreachable here (record the check you ran). Cover every part of the AC that doesn't need them and note it.*

*Review items: when `Plan/review.md` exists, one row per `fix` item confirming it.*

## Round 2

(Only if applicable: the second QA pass after dev fixes.)

Commits: round 1 `<sha>` → round 2 `<sha>`. Scope: scoped | full (reason). Tracker: re-verified ACs with evidence; the rest `pass (round 1, unaffected)` with a one-line reason.

## Verdict

- **Result:** pass | fail
- **Deferred to local run:** none | AC #s (the Technical Lead copies these into the steps file)

### Blocking issues (if fail)

1. 

## Notes for Technical Lead
