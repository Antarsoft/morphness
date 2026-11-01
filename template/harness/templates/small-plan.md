# Small plan: <title>

**Mode:** small (`harness/MODES.md` § Small mode)  
**Status:** draft  <!-- draft | awaiting-approval | approved | passed | failed-escalated (harness/SETUP.md § Lifecycle status) -->  
**Feature slug:** `<slug>`  
**Steps file:** set at QA pass: the steps file path | none  
**Version:** `1`  
**Created:** YYYY-MM-DD

This short plan replaces `feature.md` and the full plan. The main chat builds and checks it itself, with no subagent (`harness/MODES.md` § Working alone). A change that turns out to need more than § Limit allows gets a full plan, with this file linked.

## Why small

The output of `bash scripts/risk-check.sh <the files below>` (it must print `Mode: plain`), and one line on what behaviour changes (`harness/MODES.md` § Choosing mode).

## Change

What to build, in the requester's words and then in exact terms: flags, fields, messages, formats.

## Files

The paths to change and the function in each, read before planning (`file:line`). The change touches nothing else.

## Acceptance criteria

3 to 8 numbered, testable criteria, each with the test that proves it (file and test name). Include the unchanged behaviour the change must keep.

## Limit

Stop before the change, and write a full plan with this one linked, when it needs: a file not listed, a risk path (`project/CONTROLS.md` § Risk paths), a change to who can read or change data, to what a customer is charged or where money moves, to how secrets are handled, to deleting or sharing people's data, a schema change, a new dependency, a new page or flow, or behaviour § Acceptance criteria doesn't name.

## QA scope

- **UI change:** yes | no. If **yes**, before and after screenshots (`harness/agents/fullstack-engineer.md` § UI screenshots), listed in § Check.
- **Needs live app/services:** none | AC #s, as in `harness/templates/plan.md`.
- **Apps touched:** n/a | the app names.
- **Targeted e2e specs:** n/a (browser-e2e module off) | none | spec paths.
- **Human steps:** none | each step only a human can do, with why no connector did it.

## Approval

**Approver:** · **Date:** · **Answers:**

## Check

Filled on the final commit, in place of `progress.md` and `qa-result.md`.

- **Commit:** the `git rev-parse HEAD` the `before_signoff` checks ran on. Later commits may change only this plan and other documentation, or the checks run again.
- **Checks:** each `before_qa` check (with its scope) and each `before_signoff` check, with its exit code; **not run** with the reason for any the environment refused.
- **Criteria:** one line per acceptance criterion: met, with the test name or the output that shows it, or `deferred: local` (needs a live service, `harness/agents/qa-engineer.md`).
- **Screenshots:** the files, when **UI change** is yes.
- **Risk check at hand-off:** the first line of `bash scripts/risk-check.sh` with no files (it must still print `Mode: plain`).

## Decisions

One dated line per decision the human makes in chat after approval, written the same turn.
