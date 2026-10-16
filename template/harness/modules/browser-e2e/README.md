# Module: browser-e2e (browser tests)

Optional. Enable it in `harness.config.yml` → `modules` when the project has pages a person uses in a browser. The rules are tool-neutral; the examples use **Playwright** with **axe-core** (the default example tools). The commands are the `e2e-targeted` and `e2e-full` checks in [project/CONTROLS.md](../../../project/CONTROLS.md); where the specs live is in [project/TESTING.md](../../../project/TESTING.md).

## Who runs what

- **Full-stack runs targeted specs** before handoff: the plan's **Targeted e2e specs**, plus the smoke spec, the accessibility spec and every spec the diff adds or edits. It records the specs run with the exit code. When the plan says `full`, or the diff touches a cross-cutting path ([project/CONTROLS.md](../../../project/CONTROLS.md) § Cross-cutting paths), it runs the full suite.
- **QA runs the full suite once** on the final commit, and on a failure re-runs it once to tell a flaky test from a real failure (a second failure is real). The full suite is the only full run before a merge, so a missing or stale result is a QA fail.
- A long full run goes in the background with a limit above its duration, writes `$?` to a file, and the agent waits for that file in the same turn. A log that ends in "passed" is not a recorded exit code (learned: a default background limit killed a run and QA reported a partial log).
- **Timing-sensitive tests** (a fake clock, hover or focus timing): run each new or changed one five times (`--repeat-each=5` in Playwright) and record the pass count (learned: a carousel test passed once at handoff and failed 8 of 11 repeats).
- Before the first run, check that nothing is listening on the app's port: a leftover server from a screenshot or QA build makes the suite test the old app.
- **Several apps** (`harness.config.yml` → `apps`): each app's `e2e` folder holds its specs. Targeted specs come from the apps the plan lists under **Apps touched**, and `e2e-full` runs every app's suite (one command, or one per app, in `project/CONTROLS.md`).
- Browser tests run only against a local build. The config refuses a remote base URL, so the suite never runs against a staging deploy or a shared database.

## Rules for specs

- **Shared fixture fails broken pages.** Every spec uses one shared `test` fixture that fails any test whose page logged a content-security-policy violation, an uncaught error or a console error. Known-benign console errors go in one allowlist, each with a reason. A new spec that imports the runner's own `test` instead is a review finding.
- **New UI flows** (a new page, form or auth step) get a new or extended spec.
- **Accessibility scan for each new page or dialog** reachable from the app: add it to the accessibility spec, scanned at desktop width (1280 px) in the light theme and at mobile width (375 px) in the dark theme, with zero violations. A known issue goes in a known-issues list only with a reason. A page or item inside an open menu or modal dialog: the modal layer hides the rest of the page from assistive tech, so scope the scan to that layer (with axe: `include: '[role="menu"]'` or the dialog's role).
- **Streamed pages** (a page that shows a loading state while its data streams in): scope test-id locators inside a role locator (a region or landmark), because under load an unscoped test-id locator can match the framework's hidden streaming copy (learned: flaky failures only under a loaded machine).
- **Loading state after a click:** when the framework prefetches a route in more than one request (route tree, then page data), wait for the page-data response before clicking; waiting for the first request alone races.
- **Polling** (a component that refreshes or fetches on a timer): also run the test with each response held past the interval (Playwright `page.route` with a delay). Locally a response is always fast, so an unguarded poll only stalls on a real deploy (learned: a billing page stalled on its first slow response in production).
- **Returning to a tab** (a page that refreshes when the person comes back from another tab): simulate the return with a `visibilitychange` event (override `document.visibilityState`), not only a `focus` event. Phones fire only the visibility change when a tab closes, and the test browser emulates focus, so a real tab switch fires neither under it (learned: a page refreshed on desktop and never on phones).
- **Pending state of a native form post** (a spinner between submit and the redirect): answer the POST with an empty success (`route.fulfill({ status: 204 })`) so the page stays on the pending state; holding the route open blocks the runner's in-page queries (counts, evaluate, the accessibility scan) in Chromium.
- **UI-only tweaks** to existing flows: manual QA is fine; keep the full suite green.

## Screenshots

Any change a user can see needs screenshots as proof, listed in `progress.md` § Screenshots: each changed or new screen and state at 1280 and 375 px, in light and dark, with a before shot next to each after shot for a changed screen. Wait for overlays to finish opening or closing (or emulate `prefers-reduced-motion: reduce`) before each capture, so no shot catches a fade. After a round that changes user-facing text, retake every after shot that shows a changed string, not only the ones named.

## On install

- Fill [project/STACK.md](../../../project/STACK.md) § Browser tests (spec folder, config, shared fixture, credentials source, browser binary for cloud sessions) and the `e2e-targeted` / `e2e-full` rows in [project/CONTROLS.md](../../../project/CONTROLS.md).
- Add the browser-test row to [project/TESTING.md](../../../project/TESTING.md) § Where tests live, add `e2e-full` to `harness.config.yml` → `checks.before_signoff`, and `e2e-targeted` and `e2e-repeat` to `checks.before_qa`.
- Add the test fixtures, test config and global setup to [project/CONTROLS.md](../../../project/CONTROLS.md) § Cross-cutting paths.
- When the project has no shared fail-on-page-errors fixture or accessibility spec yet, the first browser feature's plan adds them (morph-init writes no test code).
- Keep the § Browser tests section of [project/HARNESS_AGENTS.md](../../../project/HARNESS_AGENTS.md) and the screenshot sections of `project/agents/fullstack-engineer.md`.

## On remove

When the project doesn't choose this module, morph-init deletes this folder and the items below. Screenshots for a UI change stay: they are core (`harness/agents/fullstack-engineer.md` § UI screenshots, the Technical Lead's screenshot check, `project/agents/fullstack-engineer.md` § UI screenshots). Rows and sentences labelled "(browser-e2e module)", "with the `browser-e2e` module" or "when the project has one" (in `harness/CONTROLS.md`, the agent bodies, `.claude/rules/testing.md`, checklist item 19) and the plan template's `n/a (browser-e2e module off)` choice stay as they are; a named check with no command is recorded as **not run**.

**Delete these files:** none outside this folder.

**Delete the marked text:** every span and line marked `module:browser-e2e`, with the command in [harness/README.md](../../README.md) § Modules → **Module markers**.

**Delete or reword these lines** (unmarked: always-loaded, config or code-block text):

- `harness.config.yml` → `checks`: remove `e2e-full` (and `e2e-targeted` and `e2e-repeat`, if listed) from `before_qa` and `before_signoff`.
- `project/CONTROLS.md` § Cross-cutting paths and `project/TESTING.md` § Where tests live: the browser-test lines morph-init filled, if any.
- `.claude/rules/testing.md` § Where tests live: "commands behind the `unit`, `e2e-targeted` and `e2e-full` checks" becomes "commands behind the `unit` check"; drop the sentence "Browser end-to-end rules, when the `browser-e2e` module is enabled, are in …".

**Unlink:** every Markdown link left pointing into `harness/modules/browser-e2e/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/browser-e2e' --include='*.md' . | grep -v '^./harness/modules/'`.
