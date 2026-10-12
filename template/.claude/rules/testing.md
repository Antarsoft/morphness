# Testing

Add **useful** automated tests when implementing behavior, not ceremony. Skip tests that only restate the implementation (e.g. asserting a constant is returned).

## Where tests live

Test tools, file locations and run commands for this stack are in [project/TESTING.md](../../project/TESTING.md) (commands behind the `unit`, `e2e-targeted` and `e2e-full` checks: [project/CONTROLS.md](../../project/CONTROLS.md)). Browser end-to-end rules, when the `browser-e2e` module is enabled, are in [harness/modules/browser-e2e/README.md](../../harness/modules/browser-e2e/README.md).

Prefer testing **pure logic** (business rules, parsers, calculations, matching, schemas, payload parsing) in unit tests close to the code, or in a shared package when the project has one. Test request handlers and server actions with focused tests when setup cost is reasonable.

## When to add tests

- New or changed **business rules**, parsers, aggregations, or shared schemas → unit tests.
- **Bug fixes** → regression test when reproduction is stable and small. Prove it with a negative test: with the fix taken out (back up the file and restore it; never `git checkout`/`stash`), the new test fails. Record that run in `progress.md`.
- **Security boundaries** (webhook signature checks, API or ingest authentication, access policies) → tests for the verification and rejection paths where feasible without live keys.
- **New UI flows** (a new page, form or auth step): with the `browser-e2e` module, add or extend a browser end-to-end test, following the project's shared fixtures; without it, the plan names the manual or automated check that covers the flow.
- **New page or dialog reachable from the app** → add it to the project's accessibility scan when it has one (`project/TESTING.md`).
- **Stack-specific traps** (streamed pages, polling, tab return, pending states and similar): the rules are in `project/TESTING.md` and the `browser-e2e` module. Each one came from a test that passed locally and failed on a real deploy or device.
- **UI-only** tweaks to existing flows → manual QA is OK; keep the browser suite green when the project has one.

## Harness roles

- **Technical Lead:** acceptance criteria must be **testable** (automated and/or explicit manual steps).
- **Full-stack engineer:** implement tests as part of the feature; before handoff run the `before_qa` checks in [harness/CONTROLS.md](../../harness/CONTROLS.md) § Before Full-stack → QA handoff and record exit codes in `Development/progress.md` § **Validation (required before handoff)**.
- **QA engineer:** validate AC; run `harness/CONTROLS.md`; with the `data-access` module, for **data-access features** follow `harness/modules/data-access/README.md` (stage A on the local stack; stage B, read-only checks on the shared remote environment after the migrations reach it through the project's workflow) and record in `qa-result.md`; do not add product tests in app code unless the plan assigns it.

## Before handoff (Full-stack → QA)

The checks, and which are required, live only in [harness/CONTROLS.md](../../harness/CONTROLS.md) § Before Full-stack → QA handoff (named in `harness.config.yml` → `checks.before_qa`). QA re-runs the same suite, plus the `before_signoff` checks, when validating.
