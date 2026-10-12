# Testing: project specifics

The general test rules (useful tests, not ceremony; regression tests for bug fixes; who adds what) are in [.claude/rules/testing.md](../.claude/rules/testing.md). With the `browser-e2e` module, the browser-test rules are in [harness/modules/browser-e2e/README.md](../harness/modules/browser-e2e/README.md). This file holds what is specific to this project.

## Where tests live

| Area | Tool | Location |
|------|------|----------|
<!-- morph-init: fill one row per package or area. Example rows: "| Shared logic | <unit runner> | `lib/**/*.test.ts` |", "| API handlers | <unit runner> | colocated `*.test.ts` |", "| Browser | <e2e runner> | `e2e/*.spec.ts`, run with the `e2e-targeted` / `e2e-full` checks |". -->

Prefer testing **pure logic** (calculations, parsers, matching rules, schemas, webhook payload parsing) in unit tests close to the code. Test request handlers with focused tests when the setup cost is reasonable.

## Project-specific test rules

Each rule ends with the reason it exists, in brackets.

<!-- morph-init: fill the rules this stack needs, or leave the list empty; retros add rules here when a test gap lets a bug through. Examples:
- **Webhooks:** test signature verification and every rejection path without live keys (a forged event must be refused).
- **Tenancy:** every new query gets a test with a second account that must see nothing (learned: a missing account filter on a route no AC named).
-->

## Test data

<!-- morph-init: fill the seed or fixture data tests may rely on and how to reset it. Example: "The local stack seeds two accounts (`qa@example.test`, `qa2@example.test`) for isolation tests; `make stack-reset` restores them." -->
