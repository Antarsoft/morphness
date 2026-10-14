# Plan: <title>

**Status:** draft  <!-- draft | awaiting-approval | approved | passed | failed-escalated (harness/SETUP.md § Lifecycle status) -->  
**Steps file:** set at QA pass: the steps file path | none  <!-- harness/SETUP.md § After QA pass, step 4 -->  
**Feature slug:** `<feature-slug>`  
**Version:** `1`  
**Ships in:** `<version id>` (roadmap module only: the roadmap's next version at plan time)  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD

## Summary

One paragraph, human-readable.

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

## Implementation steps

### Phase 1 (optional)

1. Step: technical detail for the Full-stack engineer (exact files and functions, contracts, limits, error messages and UI wording).

## References

- **Greps:** the commands from the TL's pre-approval checklist (`harness/PLAN_CHECKLIST.md`, `project/PLAN_CHECKLIST.md`) with hit counts, or "n/a", one line per item (`K<n>` kit, `P<n>` project). A plan with no Greps record is not ready for approval.
- Each reference as `file § section` or `file:line`, never a whole file: agents read what the plan names and carry it in their context for the whole run.

## QA scope

- **UI change:** yes | no. If **yes**, Full-stack provides screenshots (`harness/agents/fullstack-engineer.md` § UI screenshots) and the plan lists the screens and states to capture.
- **Legal wording:** yes | no | n/a (legal module off). If **yes**, the legal sentences come from `<feature>/Legal/legal-copy.md`, written by the `legal-writer` subagent before approval (`harness/modules/legal/README.md`); link it here.
- **Data-access feature:** yes | no | n/a (data-access module off). If **yes**, QA runs `harness/modules/data-access/README.md` stage A and fills `qa-result.md` § Data-access validation; stage B follows after the migrations reach the integration environment.
- **Needs live app/services:** none | AC #s: ACs that only pass if the running app reaches its database or other services (login, data-backed screens, API calls, queues). QA runs them only where those are reachable; elsewhere it marks them `deferred: local` and they go into the steps file. Where QA can run: `harness/SETUP.md` § Where QA can run.
- **Apps touched:** n/a (no `apps` in `harness.config.yml`) | the app names whose folders the change touches, from `apps`; a change to a shared package lists every app that depends on it (`project/STACK.md` § Apps)
- **Checks:** scoped (default: Full-stack narrows `before_qa` by the diff, `harness/CONTROLS.md` § Scoping by what changed) | full (with the reason, for a change whose reach the diff doesn't show, such as a renamed export used by generated code or a config read at runtime)
- **Targeted e2e specs:** n/a (browser-e2e module off) | none (no screen, auth or public API change) | full (the change is cross-cutting: `harness/CONTROLS.md` § Cross-cutting paths) | spec paths (with `apps`, from each touched app's `e2e` folder). Full-stack also runs the always-run specs and every spec it adds or edits; QA runs the full suite.
- **Login needed:** none | AC #s and which user (default: the seeded local user in `project/STACK.md`; never a user on a shared remote environment).
- **Build-time env:** none | variables that must be set when QA builds the app, and whether QA must rebuild.
- **Third-party console:** none | each console screen the human must use and its precondition, listed in the human steps.
- **Human steps:** none | each step only a human can do (account no agent can reach, change to the integration or production environment, judgement call), with the expected result. The TL copies them to the steps file at QA pass.

## Agent effort

Pick per feature; the human approves it with the plan. Levels and criteria: `harness/SETUP.md` § Effort per feature; subagent names: `project/HARNESS_AGENTS.md`.

- **Full-stack:** medium | high | xhigh (or a trial variant from `_harness/LEARNINGS.md` § Trials): one-line reason. A pattern-copy plan is `medium` and names the file it copies, unless it touches a risk area (`risk_areas` in `harness.config.yml`). A large feature with an `xhigh` core and a sizeable ordinary part is split into two plans by risk.
- **QA:** medium | high: one-line reason (`high` for a data-access feature or a risk area).
- **Code review before QA:** yes (Full-stack xhigh) | no. See `harness/SETUP.md` § Code review before QA.

## Acceptance criteria

1. Given … when … then …

Writing testable ACs:

- An AC that a value must not reach the client says where it is checked ("not in the rendered page text and not in any attribute outside inline scripts"). Frameworks put route data in inline scripts, so a whole-page grep can fail for reasons the feature can't change. If the value must not reach the client at all, say so, and say which payload is checked.
- A number taken from a design review or earlier notes (a size, a count, a timing) gets an AC that measures it before anything is changed to fix it. Notes can be wrong.
- A control that is hidden or disabled in some state still has neighbouring help text and labels: the plan names what they say in that state.
- A flow that opens or reuses a window, tab or session gets an AC for its second use in a row (same tab, after a reload), not only the first.
- An AC that needs a UI element opened or rendered names the screen that renders it today; if none does, the AC is unit-level or moves to the phase that adds the element.
- An AC about overflow, wrapping or truncation names the element it measures, the worst-case input (the schema maximum, both unbroken and with spaces) and the viewport widths, and the plan's test data includes it; short seed data never reaches the bug. A layout with columns next to fixed chrome computes the width each column gets at every breakpoint it names, and "nothing is cut off" is asserted with box measurements, never with text content.
- A plan that names a design token or theme mechanism cites its definition with `file:line`; a token that does not exist yet is added in the plan's steps.
- An AC that scans "every new and changed file" lists the files it knowingly leaves out and the phase or feature that migrates them.
- An AC about motion, focus or scroll behaviour asserts the computed result in a browser, not class names.

Full-stack **must** pass the `before_qa` checks in `harness/CONTROLS.md` § Before Full-stack → QA handoff before QA; record them in `progress.md`.

## Open questions

| # | Question | Suggested default |
|---|----------|-------------------|
| 1 | | |

## Approval

- **State:** pending | approved
- **Approver:**
- **Date:**

## Decisions

One line per decision the human makes in chat after approval, written the same turn, so a new thread can pick the feature up from the files.

| Date | Decision | Where decided |
|------|----------|---------------|
| | | |
