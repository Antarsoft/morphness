<!-- Feature PRs target `{{branches.integration}}`. Only a release PR (from the release branch, `{{branches.integration}}` unless a middle environment has its own branch) targets `{{branches.production}}`. Always open with an explicit base, as a draft (for example `gh pr create --draft --base {{branches.integration}}`). -->
<!--
Keep it short. Delete sections that don't apply rather than writing "N/A".
Never paste secrets, keys, connection strings or env file values here.
Agents fill these sections from the feature folder (plan.md, qa-result.md, the steps file).
When: Summary, Harness and Changes when the draft opens (kept current as the feature goes);
Verification, Needs the owner and Risk when the PR is marked ready, after QA pass. A draft never
shows a QA box ticked. (.claude/rules/technical-lead.md § Commits and branches)
-->

## Summary

<!-- What changes and why, in 2–4 sentences a reviewer can read without opening the diff. At draft. -->

Merge after: none <!-- or #N, when the merge-order check found an open PR that shares a non-documentation file and should go first (harness/CONTROLS.md § Merge order) -->

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

<!-- At ready. What was run and the result. Link the QA record rather than repeating it. For a UI change, screenshots are linked from the thread reply and progress.md § Screenshots; add links here only if the reviewer won't see the thread. -->

- [ ] Named checks before QA: typecheck · lint · unit · build (commands: project/CONTROLS.md)
- [ ] Full browser suite on the final commit (when pages, auth or the public API change)
- [ ] Recorded in `qa-result.md` on the final commit <!-- morph-init: fill "and CI passed on this PR" when harness.config.yml → ci_gate is true -->

## Needs the owner

<!-- At ready. Only what agents can't do: hosting or provider dashboard settings, env vars, running production workflows, judgement calls. Copy from the feature's steps file. Write "Nothing" if none. -->

-

## Risk and rollback

<!-- At ready. What could break in production, and how to undo it (is a revert enough? data or settings to restore?). -->

-

## Release notes

<!-- Release and hotfix PRs only; delete on a feature or promotion PR. With the ci-cd tag workflow this section, and only this section, becomes the release notes (everything up to the next `## ` heading). Write for people using the product: one line per feature or fix, no checklists or links to harness files. Leave it empty to get the host's generated notes. -->

- 

## Release

<!-- Release PRs only (release branch → `{{branches.production}}`, title `Release vX.Y.Z`; process: harness/RELEASE.md, project/RELEASE.md). Delete this section on a feature or hotfix PR. A promotion PR (`Promote vX.Y.Z to <environment>`, harness/RELEASE.md § Environments) keeps the Features list and drops the release QA, migration and env var lines. Merge with a merge commit, not squash. -->

- Package versions (only with `release_tags: per-package`; from the versioning tool's dry run): `<package>`: `x.y.z` → `x.y.z`
- Features (each with its `QA/qa-result.md`):
  - `<slug>`: `_harness/features/<slug>/<version>/QA/qa-result.md`
- Release QA: `_harness/releases/<version>/qa-result.md`, **pass** on the release QA environment
- Migrations, in order (the owner applies them to production **before** merging; project/RELEASE.md § Production migrations):
  - `<path>`
  - [ ] Production migrations applied and nothing left pending (not needed when none were pending)
- Env var changes (the owner sets them in production **before** merging):
  - [ ] `NAME`: new | changed | removed
- Rollback: project/RELEASE.md § Rollback; database changes are fixed forward (migrations are additive)

## Hotfix

<!-- Hotfix PRs only (branch from `{{branches.production}}` → `{{branches.production}}`, title `Hotfix vX.Y.Z`, the next patch version; harness/RELEASE.md § Hotfix). Delete this section otherwise. -->

- Bug and its QA record: `_harness/features/<slug>/<version>/QA/qa-result.md`, **pass**
- [ ] Tag `vX.Y.Z` on the merge commit (the tag workflow, or the command the Technical Lead hands the owner; skip with `release_tags: false`; with `per-package`, the versioning tool's tags for the patched packages)
- [ ] Merge-back PR from `{{branches.production}}` into `{{branches.integration}}` (and each middle environment's branch): #N
