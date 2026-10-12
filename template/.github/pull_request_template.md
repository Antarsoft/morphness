<!-- Feature PRs target `{{branches.integration}}`. Only a release PR (`{{branches.integration}}` → `{{branches.production}}`) targets `{{branches.production}}`. Always open with an explicit base (for example `gh pr create --base {{branches.integration}}`). -->
<!--
Keep it short. Delete sections that don't apply rather than writing "N/A".
Never paste secrets, keys, connection strings or env file values here.
Agents fill these sections from the feature folder (plan.md, qa-result.md, the steps file).
-->

## Summary

<!-- What changes and why, in 2–4 sentences a reviewer can read without opening the diff. -->

## Harness

<!-- Full harness: link each feature folder. Light mode (docs, typos, config): say so and why. -->

- Feature: `_harness/features/<slug>/<version>/`: plan approved, QA **pass** (`QA/qa-result.md`), owner steps in `<steps file>` or none
- Mode: full | light (reason)

## Changes

<!-- Grouped by area; name the files or modules that matter. Call out renames, deletions and anything unrelated riding along. -->

-

## Database

<!-- Delete this section if there are no schema or access-control changes. Agents never apply these to a remote database: project/RELEASE.md § Production migrations says how they reach each environment and who runs it. -->

- Migrations, in apply order: `<path>`
- [ ] Applied and checked on the local stack (`qa-result.md`; with the `data-access` module, stage A passed)
- [ ] After the merge, the migrations reached the integration environment (the workflow ran, not skipped, and passed); with the `data-access` module, QA then runs stage B

## Verification

<!-- What was run and the result. Link the QA record rather than repeating it. -->

- [ ] Named checks before QA: typecheck · lint · unit · build (commands: project/CONTROLS.md)
- [ ] Full browser suite on the final commit (when pages, auth or the public API change)
- [ ] Recorded in `qa-result.md` on the final commit <!-- morph-init: fill "and CI passed on this PR" when harness.config.yml → ci_gate is true -->

## Needs the owner

<!-- Only what agents can't do: hosting or provider dashboard settings, env vars, running production workflows, judgement calls. Copy from the feature's steps file. Write "Nothing" if none. -->

-

## Risk and rollback

<!-- What could break in production, and how to undo it (is a revert enough? data or settings to restore?). -->

-

## Release

<!-- Release PRs only (`{{branches.integration}}` → `{{branches.production}}`, title `Release vX.Y.Z`; process: harness/RELEASE.md, project/RELEASE.md). Delete this section on a feature PR. Merge with a merge commit, not squash. -->

- Features (each with its `QA/qa-result.md`):
  - `<slug>`: `_harness/features/<slug>/<version>/QA/qa-result.md`
- Release QA: `_harness/releases/<version>/qa-result.md`, **pass** on the integration environment
- Migrations, in order (the owner applies them to production **before** merging; project/RELEASE.md § Production migrations):
  - `<path>`
  - [ ] Production migrations applied and nothing left pending (not needed when none were pending)
- Env var changes (the owner sets them in production **before** merging):
  - [ ] `NAME`: new | changed | removed
- Rollback: project/RELEASE.md § Rollback; database changes are fixed forward (migrations are additive)
