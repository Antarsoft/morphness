# Controls: this project's commands

The handoff rules (who runs which checks, when, and how the output is logged) are in [harness/CONTROLS.md](../harness/CONTROLS.md). This file maps each **named check** in `harness.config.yml` → `checks` to the command that runs it here, and lists the paths that need the full browser suite. Kit docs name the checks; only this file names the commands.

## Named checks

| Check | Command | Required |
|-------|---------|----------|
| `install` | `{{cmd.install}}` | yes, when dependencies changed |
| `typecheck` | `{{cmd.typecheck}}` | yes |
| `lint` | `{{cmd.lint}}` | yes |
| `unit` | `{{cmd.unit}}` | yes |
| `build` | `{{cmd.build}}` | yes |
| `e2e-targeted` | `{{cmd.e2e-targeted}}` followed by the specs: the plan's **Targeted e2e specs**, plus the smoke and accessibility specs and every spec the diff adds or edits | yes, for features touching pages, auth or the public API |
| `e2e-full` | `{{cmd.e2e-full}}` | QA, once on the final commit; Full-stack when the plan says `full` or the diff touches a cross-cutting path |
| `e2e-repeat` | `{{cmd.e2e-repeat}}` | yes, when a new or changed browser test uses a fake clock, hover or focus timing: five runs, record the pass count |
<!-- morph-init: fill extra named checks the project adds (also add the name to harness.config.yml → checks). Example: "| `integration` | `make test-integration` | yes, for database features |". A check with no command in this project: write "not configured" in the Command column; agents then record it as **not run**. -->

## Check scope

How Full-stack narrows each `before_qa` check to what the branch changed ([harness/CONTROLS.md](../harness/CONTROLS.md) § Scoping by what changed). QA's sign-off run always uses the full commands above. A check with no row runs in full.

| Check | Scope | Scoped command, or the paths that trigger it |
|-------|-------|----------------------------------------------|
<!-- morph-init: fill one row per check that can be narrowed, from the stack's own tooling. Scope is `full`, `affected` (a scoped command) or `paths` (globs; the check runs in full only when the diff touches one). Examples: "| `unit` | `affected` | `pnpm --filter '...[origin/dev]' test` |", "| `unit` | `affected` | `npx vitest run --changed origin/dev` |", "| `unit` | `affected` | `npx jest --changedSince=origin/dev` |", "| `typecheck` | `affected` | `npx turbo run typecheck --filter=...[origin/dev]` |", "| `integration` | `paths` | `src/api/`, `db/` |". Keep `typecheck` and `build` at `full` unless the tool computes affected packages itself (a file's change can break its importers). With no tool that scopes, write "None: every check runs in full." -->

## Command output

Log location for every check (the discipline itself is in [harness/CONTROLS.md](../harness/CONTROLS.md) § Command output):

```bash
mkdir -p "$SCRATCH/logs"            # the session scratchpad; never the repo root
rm -f "$SCRATCH/logs/<check>.exit"
<command> > "$SCRATCH/logs/<check>.log" 2>&1; echo "exit $?" | tee "$SCRATCH/logs/<check>.exit"
tail -n 30 "$SCRATCH/logs/<check>.log"
```

<!-- morph-init: fill the grep that finds failures in this project's test output. Example: "grep -nE 'FAIL|Error|failed' \"$SCRATCH/logs/e2e.log\" | head -n 40". -->

## Cross-cutting paths

A change to any of these paths can break pages or flows it doesn't name, so it gets `e2e-full` from Full-stack and a full (not scoped) QA round 2.

<!-- morph-init: fill the list. Typical entries: shared packages, the database schema and migrations, the auth and session code, request middleware, the root layout, framework config, the browser-test fixtures and config, the root manifest and lockfile. Example: "`src/db/`, `migrations/`, `src/auth/`, `src/middleware.ts`, `package.json`, the lockfile". -->

## Shared resources

Local resources that only one agent may use at a time (a local service stack, a fixed port, a browser
test server). Every delegation prompt says to wrap each command that starts or uses them in this lock
and to stop any server before releasing it ([harness/HANDOFFS.md](../harness/HANDOFFS.md)).

<!-- morph-init: fill the resources and the lock command, "No lock command: the TL serializes agents that use them", or "None: agents can run checks in parallel." Example: "Local database stack and port 3000: `flock /tmp/<project>-stack.lock <command>`". -->

## Manual smoke

Steps QA runs by hand when the UI changed, picking the ones that apply.

<!-- morph-init: fill a short list. Example: "1. Sign up, sign in, sign out. 2. Open each page the diff touches at desktop and phone width. 3. Switch theme on those pages." Leave "Not set yet: add steps after the first UI feature" for a new project. -->

## Documentation paths

A diff that touches only these paths lets QA reuse an earlier full-suite result ([harness/CONTROLS.md](../harness/CONTROLS.md)):

`_harness/`, `docs/`, `harness/`, `project/`, `.claude/`, `*.md` outside `.github/`.

<!-- morph-init: fill extra documentation-only paths, or remove one the project builds from (for example a docs site whose markdown is compiled into pages). -->

## CI

| Item | Location |
|------|----------|
<!-- morph-init: fill the pipeline file, its triggers, what each job runs, and whether it is a required gate (harness.config.yml → ci_gate). Example: "| Pipeline | `.github/workflows/ci.yml`: on pull requests to the integration branch; jobs `checks` (typecheck, lint, unit, build) and `e2e` |". With `ci_gate: false`, say that QA's local run is the gate. With the `ci-cd` module, also list the deploy and migrations workflows and who starts them. With no pipeline at all, write "None: QA's local run is the gate". -->

## Before the feature PR (Technical Lead)

| Check | Command | Required |
|-------|---------|----------|
<!-- morph-init: fill with the roadmap module: "| One next version | `grep -c '| **NEXT** |' docs/ROADMAP.md` prints `1`, and that version's checklist exists | yes |" and "| Human steps copied | `plan.md` **Steps file** names `docs/versions/<id>/steps/<slug>.md` with this feature's block, or says `none` | yes |". Without the module, delete this section. -->
