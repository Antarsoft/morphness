# Small plan: <title>

**Mode:** small (`harness/MODES.md` § Small mode)  
**Status:** draft  <!-- draft | awaiting-approval | approved | passed | failed-escalated (harness/SETUP.md § Lifecycle status) -->  
**Feature slug:** `<slug>`  
**Steps file:** set at QA pass: the steps file path | none  
**Version:** `1`  
**Created:** YYYY-MM-DD

This short plan replaces `feature.md` and the full plan. The sections the agents rely on keep their names, so Full-stack and QA read it like any plan. A change that turns out to need more than § Limit allows gets a full plan, with this file linked.

## Why small

One line per test in `harness/MODES.md` § Small mode → Use when: the request says exactly what to build, the files below are the whole change, and the change alters no access, money, stored data's shape or deletion, secrets, dependency or flow.

## Change

What to build, in the requester's words and then in exact terms: flags, fields, messages, formats.

## Files

The paths to change and the function in each, read by the TL itself (`file:line`). Full-stack touches nothing else.

## Acceptance criteria

3 to 8 numbered, testable criteria, each with the test that proves it (file and test name). Include the unchanged behaviour the change must keep.

## Limit

Full-stack stops and hands back, without the change, when it needs: a file not listed, a change to who can read or change data, to what a customer is charged or where money moves, to how secrets are handled, to deleting or sharing people's data, a schema change, a new dependency, a new page or flow, or behaviour § Acceptance criteria doesn't name.

## QA scope

- **UI change:** yes | no. If **yes**, Full-stack provides screenshots and QA runs its layout pass.
- **Needs live app/services:** none | AC #s, as in `harness/templates/plan.md`.
- **Apps touched:** n/a | the app names.
- **Targeted e2e specs:** n/a (browser-e2e module off) | none | spec paths.
- **Human steps:** none | each step only a human can do, with why no connector did it.

## Agent effort

Full-stack `medium` · QA `medium` (small mode default; raise one with a one-line reason).

## Approval

**Approver:** · **Date:** · **Answers:**

## Decisions

One dated line per decision the human makes in chat after approval, written the same turn.
