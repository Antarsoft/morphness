# Stack and commands

The commands behind each named check are in [CONTROLS.md](./CONTROLS.md); this file holds the stack, prerequisites, environment and every other command an agent may need.

## Stack

| Layer | Choice |
|-------|--------|
| Package manager | {{stack.package_manager}} |
<!-- morph-init: fill one row per layer with the pinned version and where it is pinned. Example rows: "| Runtime | Python 3.12 (pinned in `.python-version`) |", "| CI | GitHub Actions, `.github/workflows/ci.yml` (jobs and what they run) |", "| Hosting | <provider>: integration branch → staging, production branch → production |". -->

## Apps

<!-- morph-init: fill only when harness.config.yml → apps lists entries: one row per app with its folder, stack, the commands that differ from the repo root's (dev server, its own test or build script), and what it depends on in the repo ("| `api` | `apps/api` | Go 1.23 | `go test ./...` in `apps/api` | `packages/proto` |"). Delete the section when `apps` is empty. -->

## Prerequisites

<!-- morph-init: fill what a fresh machine or cloud session needs before the first install: toolchain, container runtime for a local stack, CLIs, accounts (sandbox accounts only for agents). Example: "- Docker, for the local database stack only". -->

- Toolchain setup: {{stack.toolchain_setup}}
- Install: `{{stack.install_cmd}}`

## Environment

<!-- morph-init: fill where env files live, which example file to copy, and where the env schema is validated. Agents never read real secret files (`.claude/settings.json` denies `.env*`). Example: "Copy `.env.example` to `.env.local`; `src/env.ts` validates it at start." -->

## Commands (repo root)

| Task | Command |
|------|---------|
| Install | `{{cmd.install}}` |
| Typecheck | `{{cmd.typecheck}}` |
| Lint | `{{cmd.lint}}` |
| Unit tests | `{{cmd.unit}}` |
| Build | `{{cmd.build}}` |
| Browser tests (targeted) | `{{cmd.e2e-targeted}}` |
| Browser tests (full) | `{{cmd.e2e-full}}` |
<!-- morph-init: fill extra rows: development server and its URL, local stack start/reset/stop, build-and-start against the local stack. -->

<!-- morph-init: fill the gotchas that cost a past run time (a generated file a typecheck needs, a lockfile to review after adding a dependency). Delete this comment when there are none yet. -->

## Database

<!-- morph-init: fill only when the project has a database. How the schema is defined, how a migration is generated, where migration files live, and which commands apply them (local only for agents; remote only through the workflows in [RELEASE.md](./RELEASE.md)). Delete the section when there is no database. -->

## Local stack (QA)

<!-- morph-init: fill only when QA needs the running app to reach a database or service. The command that starts it, resets it to the seed, and stops it; the seeded logins and fixtures; what a cloud session needs (container runtime, cached images). Example: "`make stack` starts Postgres in Docker, migrates and seeds; login `qa@example.test` / `qa-password`." -->

## Browser tests

<!-- morph-init: fill only with the browser-e2e module. Where the specs live, the config file, what the shared fixture fails on, where credentials come from, which browser binary a cloud session uses. Rules: [harness/modules/browser-e2e/README.md](../harness/modules/browser-e2e/README.md). -->

## Hosting and deploys

<!-- morph-init: fill which branch deploys where and who triggers a deploy. Agents never deploy on their own (`harness/SKILLS_AND_MCPS.md` § Connector actions). Example: "Integration branch → staging (automatic on push); production branch → production." -->
