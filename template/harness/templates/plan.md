# Plan: <title>

**Status:** draft  <!-- draft | awaiting-approval | approved | passed | failed-escalated (harness/SETUP.md § Lifecycle status) -->  
**Steps file:** set at QA pass: the steps file path | none  <!-- harness/SETUP.md § After QA pass, step 4 -->  
**Feature slug:** `<feature-slug>`  
**Version:** `1`  
**Ships in:** `<version id>` (roadmap module only: the roadmap's next version at plan time)  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD

## Request

The owner's ask, in their words where they gave them (they may draft this section). A few lines each, and only the ones the ask gives; the plan's own sections turn them into steps and criteria.

- **What we want:**
- **Why:**
- **Success looks like:**
- **Constraints:** deadlines, platforms, out-of-scope hints
- **Links:** tickets, screenshots, prior art

## Summary

One paragraph, human-readable.

## Acceptance criteria

The end goal, as checks an agent can run: what the change must do when it is done. Write them before the steps; each step below serves one or more of them.

1. Given … when … then …

How to word them: the plan checklist items the plan runs (K7 and K20 in particular). Full-stack **must** pass the `before_qa` checks in `harness/CONTROLS.md` § Before Full-stack → QA handoff before QA; record them in `progress.md`.

## Out of scope

- (When another plan is built in parallel: the shared files and functions it owns, harness/HANDOFFS.md § Parallel plans.)

## Framework assumptions

Each framework or library behaviour the plan depends on, with the source that confirms it. Checked by the Technical Lead **before approval**. "Already used in this repo" counts as a source only with the `file:line` that uses it, found with grep, not from memory. Write "None" only if every behaviour the plan relies on has such a `file:line`.

1. Behaviour: source (the framework's docs for the installed version, a docs MCP, or `path/to/file:42` where this repo already relies on it). If it can only be confirmed by running code, say so and make it the Full-stack engineer's first step.
2. A plan that adds a file the framework treats specially (a layout, a loading or error boundary, a not-found handler, middleware) states its effect on the response status and routing, and lists which pages under it can return an error or redirect.

## Inputs and client code

- **New inputs:** for each new user-entered field, where it ends up (database, API response, code running in someone else's environment) and what is dangerous there (URL schemes, selectors, markup). "None" if no new fields.
- **Client imports:** for each new client-side module, which shared modules it imports and that they are safe for the client runtime (project rule: `project/PROJECT.md`). "None" if no new client code.
- **Threat model (code that runs in environments you don't control):** what a hostile page, host or link could control. "None" if the plan adds no such code.
- **Size budget:** for a plan that touches a size-budgeted artifact (an embeddable script, a mobile bundle), the growth measured from a throwaway build (not a guess), the headroom left, the other open plans that compete for it, and a note to re-measure at each dev handoff. "None" if untouched.
- **Removed client checks:** for each step that removes or bypasses a client-side check, what the server does with the same input, with the `file:line`. "None" if no checks are removed.
- **Enforcement:** for each new limit or permission, every write path that could bypass it (server handlers, background jobs, direct database or storage APIs) and what blocks each one. Where access depends on who the caller is, also how that identity is verified (session check, signed token, allow-list). "None" if no new limits or permissions.

<!-- module:security -->
## Security

- **Security feature:** yes | no. Yes when the change alters who can sign in or read or change data, moves money, handles secrets, or deletes people's data (`harness/modules/security/README.md` § What counts as a security feature; this project's code: `project/CONTROLS.md` § Security paths). Touching user data alone is not enough. For **no**, delete the rest of this section.
- **Assets:** what an attacker would want from this change.
- **Entry points:** each new or changed route, handler, job, webhook, form or upload, and who can reach it.
- **Identity and ownership:** how each entry point knows the caller and checks they may touch the record, with `file:line`.
- **Threats and mitigations:**

  | # | Entry point | Threat | Mitigation | AC |
  |---|-------------|--------|------------|----|
  | 1 | | | | |

- **Secrets:** each new secret, where it lives and who sets it (never a value). "None" if none.
- **Accepted risks:** what is left open on purpose and why; the owner accepts them with the plan. "None" if none.

<!-- /module:security -->
## Implementation steps

### Phase 1 (optional)

1. Step: technical detail for the Full-stack engineer (exact files and functions, contracts, limits, error messages and UI wording). Name existing code by `file:line` and say the change in words; write out only the text that must ship as written (a policy expression, an error message, UI copy). The builder, the review and QA each read this file whole on every turn.

The project fact docs the change makes untrue (what the product does and holds: `project/PROJECT.md` and the domain docs) are steps too, written with the code, each with an acceptance criterion naming the fact the doc must state, so QA checks it. Rule and process docs (`project/CONTROLS.md` risk paths, `project/TESTING.md`, `project/PLAN_CHECKLIST.md`) stay with the Technical Lead.

## References

- **Greps:** `Plan/greps.md`, next to this file: the commands from the TL's pre-approval checklist (`harness/PLAN_CHECKLIST.md`, `project/PLAN_CHECKLIST.md`) with hit counts, or "n/a", one line per item (`K<n>` kit, `P<n>` project) or one "n/a" line for a group that doesn't apply (`K14–K20 n/a: <reason>`). It is the Technical Lead's evidence for approval, kept out of this file because every agent after it reads the plan whole. A plan with no Greps record is not ready for approval.
- Each reference as `file § section` or `file:line`, never a whole file: agents read what the plan names and carry it in their context for the whole run.
- **Code map:** `Plan/code-map.md` at commit `<short sha>` (full mode; the code scout wrote it, and the Full-stack engineer, the review and QA read the code by its line ranges).

## QA scope

- **UI change:** yes | no. If **yes**, Full-stack provides screenshots (`harness/agents/fullstack-engineer.md` § UI screenshots) and the plan lists the screens and states to capture.
- **Legal wording:** yes | no | n/a (legal module off). If **yes**, the legal sentences come from `<feature>/Legal/legal-copy.md`, written by the `legal-writer` subagent before approval (`harness/modules/legal/README.md`); link it here.
- **Data-access feature:** yes | no | n/a (data-access module off). If **yes**, QA runs `harness/modules/data-access/README.md` stage A and fills `qa-result.md` § Data-access validation; stage B follows after the migrations reach the integration environment.
- **Needs live app/services:** none | AC #s: ACs that only pass if the running app reaches its database or other services (login, data-backed screens, API calls, queues). QA runs them only where those are reachable; elsewhere it marks them `deferred: local` and they go into the steps file. Where QA can run: `harness/SETUP.md` § Where QA can run.
- **Apps touched:** n/a (no `apps` in `harness.config.yml`) | the app names whose folders the change touches, from `apps`; a change to a shared package lists every app that depends on it (`project/STACK.md` § Apps)
- **Checks:** scoped (default: Full-stack narrows `before_qa` by the diff, `harness/CONTROLS.md` § Scoping by what changed) | full (with the reason, for a change whose reach the diff doesn't show, such as a renamed export used by generated code or a config read at runtime)
- **Targeted e2e specs:** n/a (browser-e2e module off) | none (only the always-run specs) | full (the change is cross-cutting: `harness/CONTROLS.md` § Cross-cutting paths) | spec paths (with `apps`, from each touched app's `e2e` folder). Full-stack also runs the always-run specs and every spec it adds or edits; QA runs the full suite.
- **Login needed:** none | AC #s and which user (default: the seeded local user in `project/STACK.md`; never a user on a shared remote environment).
- **Build-time env:** none | variables that must be set when QA builds the app, and whether QA must rebuild.
- **Third-party console:** none | each console screen the human must use and its precondition, listed in the human steps.
- **By connector:** none | each setup action the TL will do through a connected MCP, connector or plugin, with the tool, the target and when (before dev, before QA, after the merge). Each one is still asked in chat right before it runs; approving the plan doesn't approve them (`harness/SKILLS_AND_MCPS.md` § Connector actions).
- **Human steps:** none | each step only a human can do (no connected tool can do it, it never goes through an agent, or a judgement call), with the expected result and why no connector did it. The TL copies them to the steps file at QA pass.

## Agent effort

Pick per feature; the human approves it with the plan. Levels and criteria: `harness/SETUP.md` § Effort per feature; subagent names: `project/HARNESS_AGENTS.md`.

- **Full-stack:** medium | high | xhigh (or a trial variant from `_harness/trials/`): one-line reason. A `medium` plan names the file it copies; `xhigh` is for sign-in, secrets and money only.
- **QA:** medium | high (high only when Full-stack is xhigh): one-line reason.
- **Code review before QA:** yes (the risk check named a risk path, or Full-stack xhigh) | yes, with the security review (it also touches sign-in, access rules, secrets, money, a public API, or deleting or sharing people's data) | no. See `harness/SETUP.md` § Code review before QA.
- **Security review before QA:** yes (Security feature: yes, whatever the line above says) | no. <!-- module:security -->

## Open questions

| # | Question | Suggested default |
|---|----------|-------------------|
| 1 | | |

## Approval

The **Status** line at the top records whether the plan is approved; this section records who approved it and when.

- **Approver:**
- **Date:**
- In a driver-started autonomous run (`MORPH_AUTO=1`), the Technical Lead approves: **Approver:** `Technical Lead (autonomous mode); product doc approved by <owner> on <date>` (`harness/modules/autonomous/README.md` § Run rules). <!-- module:autonomous -->

## Decisions

One line per decision the human makes in chat after approval, written the same turn, so a new thread can pick the feature up from the files.

| Date | Decision | Where decided |
|------|----------|---------------|
| | | |
