<!-- Project addendum for every `fullstack-engineer*` subagent variant. The generic role body is
     harness/agents/fullstack-engineer.md; this file adds only what is specific to this project.
     Keep it short: everything here loads into every Full-stack run. -->

# Full-stack engineer: {{project.name}} addendum

## Read before you start

In [project/STACK.md](../STACK.md) read only § Commands, § Database, § Local stack (QA) and § Browser tests; the rest is deploy and tooling notes no feature needs.

<!-- morph-init: fill any other section a Full-stack run always needs (for example a design doc's token rules before touching UI styling). -->

## Databases and remote environments

<!-- morph-init: fill where migration files go, how to apply and check them on the local stack, and the remote commands agents never run. Example lines:
- Write migrations in `migrations/`; apply them with `make stack-reset` and check the tables exist and access policies are on.
- Never run `<db-cli> migrate` against a remote URL; the integration workflow applies migrations after the merge.
- In the handoff, list the new migrations in the order they apply.
Delete the section when the project has no database. -->

## UI screenshots

<!-- morph-init: fill how to capture screenshots here (the tool, the local build to run against, the seeded login, where files go). Example: "Capture against the local build with the seeded login; save to the session scratchpad as `before|after-<width>-<theme>-<state>.png`." Delete when the project has no UI. -->

## Project rules

Each rule ends with the reason it exists, in brackets.

<!-- morph-init: fill rules a Full-stack run must follow here that aren't in the generic body, or leave empty; retros add to it. Example: "- Before the first browser-test run, check that nothing is listening on the app port (a leftover server makes the suite test the old build)." -->
