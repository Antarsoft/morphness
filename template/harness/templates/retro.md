# Retro: <feature-slug> v<version>

**Feature slug:** `<feature-slug>`  
**Version:** `1`  
**Author:** Technical Lead  
**Date:** YYYY-MM-DD  
**Outcome:** pass | failed-escalated; QA rounds: N (review round: yes | no)

Process: `harness/SETUP.md` § Retrospective. Keep it to about 10 to 25 lines. No retro in light mode.

## Agent runs

One row per subagent completion notice, filled as each notice arrives (Duration and Tool calls). Agents' own Started and Ended are notes only; these numbers are the record. **Est. $** comes from `bash scripts/feature-cost.sh` at the end (`harness/SETUP.md` § Retrospective → Feature cost), never from the notice's token figure: the script prints one row per subagent run in start order, so each round takes its own row's figure.

| Run | subagent_type | Duration | Tool calls | Est. $ |
|-----|---------------|----------|------------|--------|
| Dev round 1 | | | | |
| QA round 1 | | | | |
| Technical Lead (main session) | | | | |
| **Total** | | | | `Cost ≈ $…` line, or `not measured (reason)` |

## Answers

One line each.

- **Plan:** which deviations or QA findings trace back to a gap or error in the plan? Were effort levels right?
- **Development:** what cost the most time, tokens or dollars (the Est. $ column), and was it necessary? Any rework and why?
- **QA:** did QA test the right things (ACs, deviations), anything duplicated or missed, any deferrals that could have been avoided?
- **Handoff:** does the steps file hold only what agents can't do, and could QA have closed any deferred AC?
- **Human touchpoints:** where did the human have to correct or unblock the TL or agents?
- **Trials:** if this feature ran a trial (`_harness/trials/`), its slug and whether it hit the revert condition; the learnings file's **Trial** line records it.

## What went well

-

## What to improve

Tag each finding with its cause: `plan gap` | `implementation` | `environment` | `process`.

1. (cause: …)

## Action items (usually up to `loop.retro_max_items`; decided by the TL)

Only as many as the findings call for: "None" is a normal answer, and items are never padded to reach a number. More than `loop.retro_max_items` is fine when each extra item comes from a different finding; add one line under the table saying why this feature needed more (`harness/SETUP.md` § Retrospective → How many items). **Cause** is the tag of the finding the item answers. An item that adds a sentence to a rule, checklist or agent body says in its **Action** why a script, hook, test or check can't do the job instead (`harness/SETUP.md` § Retrospective → Mechanism over memo). **Why raised** names the finding the item answers (`What to improve #N`, or an Answers line) and its evidence (a QA round, a human correction, a cost figure, a file). No finding, no item.

The TL proposes and decides each item (`harness/SETUP.md` § Retrospective → Per-feature review). An item that adds a step for the human, changes product behaviour or customer-facing copy, costs money, or is tagged `cause: environment` still goes to the human (it never becomes a rule on the TL's own yes; the owner writes any `settings.local.json` change themself). Where each lands: `harness/MORPHING.md` § Where a lesson lands. An item that changes how a role works is `approve (trial)` by default: name the trial slug in **Action** and write `_harness/trials/<slug>.md` with its Baseline (`harness/MORPHING.md` § Trials). `approve (permanent, why)` is for a mechanism, a project fact or an owner call, with the reason in one line.

| # | Type (Code/Doc/Harness/Process) | Cause | Action | Why raised | Lands in | Decision |
|---|------|-------|--------|------------|----------|----------|
| 1 | | plan gap · implementation · environment · process | | What to improve #N: <evidence> | | approve (trial) · approve (permanent, why) · skip (why) · defer |

Routing:

| Type | Example | Where it goes |
|------|---------|---------------|
| Code change | Tighten a shared schema | A new harness feature (`feature.md`) or a task suggestion |
| Doc change | Note a project fact in `project/PROJECT.md` | Light-mode docs change, own commit on this feature's PR |
| Harness change | Split large features by risk | The owner file per MORPHING.md, own commit on this feature's PR (a large one gets its own plan); the rule ends with `(from <feature-slug>, <date>)` |
| Process change | Run a code review before QA for xhigh work | Same as a harness change; a trial (`_harness/trials/`) first whenever it changes how a role works |

---

Summarised in `_harness/learnings/<feature-slug>-v<version>.md`: yes | no · Action items added to its § Action items: yes | none · Decisions listed in the hand-off: yes · Cost line in the hand-off: yes · Prune counter: N/<loop.prune_every> (DUE | ok) · Rules: X/<loop.rule_budget_kb> KB · Checklists: X/<loop.checklist_budget_kb> KB · Project docs: X/<loop.project_docs_budget_kb> KB · Trial and proposal-waiting lines: pasted | none
