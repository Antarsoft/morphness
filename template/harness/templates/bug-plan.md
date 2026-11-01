# Bug plan: <title>

**Mode:** bug (`harness/MODES.md` § Bug mode)  
**Status:** draft  <!-- draft | awaiting-approval | approved | passed | failed-escalated (harness/SETUP.md § Lifecycle status) -->  
**Steps file:** set at QA pass: the steps file path | none  
**Feature slug:** `<bug-slug>`  
**Version:** `1`  
**Branch:** integration (default) | hotfix (a production bug that can't wait for the next release: `harness/RELEASE.md` § Hotfix; the human approves it with this plan)  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD

This short plan replaces `feature.md` and the full plan. The sections the agents rely on keep their names, so Full-stack and QA read it like any plan. A fix that turns out to need more than § Fix limit allows gets a full plan, with this file linked.

## Symptom

What goes wrong, in the reporter's words and then in exact terms: the error text, the wrong value, the screen. Link the report (issue, message, log line).

## Where seen

- **Environment:** production | staging | local | CI; the deployed version or commit.
- **How often:** every time | under a condition (which) | once.
- **Who is affected:** all users | a group (which) | unknown.
- **Rollback:** for a production bug, whether rolling back (`harness/RELEASE.md` § Rollback) would stop it, and what the human decided. "n/a" otherwise.

## Expected

What should happen instead, and the source that says so: an AC with its plan path, a doc, earlier behaviour with the commit, or the human's word. A bug with no source for "expected" is a product question for the human first.

## Reproduction

The steps, data and settings that show the symptom, as far as the TL got them to work (`harness/PLAN_CHECKLIST.md` item 5). "Not yet reproduced" with what was tried, when the TL could not.

## Code path read

The `file:line` of each function on the path the TL read itself, and the suspected spot. This is where to look, not a fix design: Full-stack finds and records the cause.

## Regression test

Written by **QA** before any fix (`harness/MODES.md` § Bug mode, step 2). QA adds only this test.

- **Level:** unit | integration | browser e2e: one-line reason (the lowest level that shows the symptom).
- **File:** the test file path (new or existing).
- **Asserts:** what the test checks, as the expected behaviour above.
- **Fails today because:** the failure QA should see (the error, the wrong value), so a red test for another reason doesn't count.
- When no automated test can reach the bug (a third-party console, a device), say why; QA records a manual reproduction instead and AC 1 and 2 use it.

## Fix limit

The fix is the smallest change that makes the regression test pass.

- **May touch:** the files or folder of the suspected spot, and the same-pattern places Full-stack finds.
- **Stop and hand back if the fix needs:** new behaviour, a migration or stored data change, a public API or contract change, a `risk_areas` entry the plan doesn't name, or files beyond the line above.
- **Not in this fix:** refactors and cleanups nearby; they go to their own task.

## References

- **Greps:** `harness/PLAN_CHECKLIST.md` § Planning and scope (K1 to K8) always, K5 with the reproduction above; other groups only when the fix area needs them, else one "n/a" line per group (`K14–K20 n/a: <reason>`).
- Each reference as `file § section` or `file:line`.

## QA scope

- **UI change:** yes | no. If **yes**, Full-stack provides screenshots of the fixed state (and the broken one, from the failing-test commit, when it can be shown).
- **Needs live app/services:** none | AC #s, as in `harness/templates/plan.md`.
- **Apps touched:** n/a | the app names, as in `harness/templates/plan.md`.
- **Checks:** scoped (default) | full (with the reason).
- **Targeted e2e specs:** n/a (browser-e2e module off) | none | spec paths (the regression test's spec included).
- **Human steps:** none | each step only a human can do, with why no connector did it (for a hotfix, at least checking the fix in production after the merge).

## Agent effort

`harness/SETUP.md` § Effort per feature; the human approves it with the plan.

- **Full-stack:** medium | high | xhigh: one-line reason (a fix that touches a risk path, `bash scripts/risk-check.sh` printing full, is never `medium`).
- **QA:** medium | high: one-line reason. The same variant writes the regression test and runs the re-run.
- **Code review before QA:** yes (Full-stack xhigh) | no.
- **Security review before QA:** yes when the fix changes who can sign in or read or change data, moves money, handles secrets, or deletes or shares people's data (`harness/modules/security/README.md`) | no. <!-- module:security -->

## Acceptance criteria

1. The regression test fails on the failing-test commit (`WIP(<slug>): failing test`) for the reason in § Regression test (`qa-result.md` § Reproduction).
2. On the final commit the regression test passes, and `git diff <failing-test commit> -- <test file>` is empty (or each change is explained in `progress.md` and accepted by the TL).
3. The reproduction steps above no longer show the symptom (or `deferred: local` under **Needs live app/services**).
4. Each same-pattern place in `progress.md` § Root cause is fixed, with a test where it can have one, or listed as out of scope with a reason.
5. (More only when the fix needs them: behaviour next to the bug that must not change, an error message the fix adds.)

Full-stack **must** pass the `before_qa` checks in `harness/CONTROLS.md` § Before Full-stack → QA handoff before QA; record them in `progress.md`.

## Open questions

| # | Question | Suggested default |
|---|----------|-------------------|
| 1 | | |

## Approval

- **Approver:**
- **Date:**

## Decisions

| Date | Decision | Where decided |
|------|----------|---------------|
| | | |
