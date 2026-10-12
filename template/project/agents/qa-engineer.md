<!-- Project addendum for every `qa-engineer*` subagent variant. The generic role body is
     harness/agents/qa-engineer.md; this file adds only what is specific to this project.
     Keep it short: everything here loads into every QA run. -->

# QA engineer: {{project.name}} addendum

## Read before you start

[project/CONTROLS.md](../CONTROLS.md) (commands for the named checks) and, for ACs that need a live database, [project/STACK.md](../STACK.md) § Local stack (QA).

## Live app database

<!-- morph-init: fill the exact sequence for "Needs live app/services" ACs: start the stack, build and start the app against it, the seeded logins, reset and stop commands. Example:
1. `make stack` (record the exit code).
2. `make qa-build && make qa-start`; the app is at http://localhost:8080.
3. Log in as `qa@example.test` / `qa-password`; a second login `qa2@example.test` exists for isolation checks.
4. `make stack-stop` when done.
Delete when no AC ever needs a live database. -->

## Guard against remote writes

<!-- morph-init: fill how QA proves a script talks only to the local stack. Example: "Run every command through a wrapper that loads the local env file over the session env and exits unless the database URL points at localhost (a cloud session shell can carry remote values)." -->

## Remote read-only checks

<!-- morph-init: fill with the data-access module: the MCP or CLI for stage B, the tool prefix, the project or environment id to target, and that the owner approves each query. Delete otherwise. -->

## Project rules

Each rule ends with the reason it exists, in brackets.

<!-- morph-init: fill rules QA must follow here that aren't in the generic body, or leave empty; retros add to it. Example: "- Reset the local seed before the final full run when the branch changes anything the seed derives (an old seed hid a stale expectation)." -->
