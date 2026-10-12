# Release: integration branch → production branch

Project specifics (production database, hosting, smoke checklist, environment variables, how migrations reach production): `project/RELEASE.md`. Branch names: `branches.integration` and `branches.production` in `harness.config.yml`.

## Branches

| Branch | Holds | Deploys to |
|--------|-------|------------|
| feature branch | One feature's work. Starts from the integration branch on the remote | nothing (or a per-PR preview, if the host makes one) |
| integration branch | Every feature that passed QA and was merged by the human | The integration environment (a preview or staging deploy), if the project has one |
| production branch | What is live. Moves only through a release PR or a hotfix | Production |

Feature PRs target the integration branch, always opened with an explicit base: the repository's default branch may be the production branch. The commit policy (when a PR may be opened at all) lives in `.claude/rules/technical-lead.md`.

**Single-branch flow.** When `branches.integration` equals `branches.production`, there is no release PR: feature PRs merge straight to production, so the release steps below shrink to release QA on that branch before the human's go, the production prerequisites, the tag and the record. Hotfixes are ordinary feature branches.

## When a release happens

Only when the human says **"release"**. Never automatic, never as a side effect of merging a feature into the integration branch.

## What ships

All of the integration branch at the commit the release PR is opened from. Work that is not ready stays on its feature branch and is not merged into the integration branch until it is.

## Roles

| Role | Does |
|------|------|
| Technical Lead | Lists what ships, opens the release PR, delegates release QA, tags and records the release afterwards |
| QA engineer | Runs release QA on the integration environment and writes `_harness/releases/<version>/qa-result.md` |
| Human (owner) | Says "release", applies production migrations and environment variables, merges, checks the live product |

Agents never touch remote databases or hosting settings: production migrations and environment variables are human steps (a project may apply migrations with a CI workflow that only the human runs; step 4).

## Release steps

1. **List what ships.** The Technical Lead fetches both branches, runs `git log --oneline origin/<production>..origin/<integration>`, and lists the features in it (from the merged PRs and `_harness/features/*`).
2. **Open the release PR** from the integration branch to the production branch, with the base passed explicitly. Title `Release vX.Y.Z`. The body (the **Release** section of the PR template) lists the features, a link to each feature's `qa-result.md` and steps file (if any), every new migration in order, and every new or changed environment variable.
3. **Release QA on the integration environment.** The QA engineer runs the full `before_signoff` suite ([CONTROLS.md](./CONTROLS.md)) on the integration branch's head plus the smoke steps that apply (`project/RELEASE.md` § Smoke checklist), and writes the result to `_harness/releases/<version>/qa-result.md` from [templates/release-qa-result.md](./templates/release-qa-result.md). The human's "release" command is acted on (steps 4 to 7, anything that reaches production) only after that file says **pass**; until then the command only starts steps 1 to 3. On a fail, fixes go through feature branches into the integration branch, the release PR picks them up, and release QA runs again.
4. **Production prerequisites (human).** The human applies the new migrations to production and sets the new or changed environment variables **before** merging, so the code never runs against a schema or config it doesn't expect. A project may have the human run a CI workflow that applies them instead; how this one does it: `project/RELEASE.md`.
5. **Merge (human).** The human merges the release PR; the host deploys production from the production branch.
6. **Live check (human).** The human checks the live product and says it is good.
7. **Tag and record (Technical Lead).** Tag the production branch: `git tag -a vX.Y.Z -m "Release vX.Y.Z" origin/<production>`, then push the tag. If agents can't push tags here, the TL gives the human the exact command. Record the release in `_harness/LEARNINGS.md` and, with the roadmap module, in the roadmap's changelog; the roadmap module also folds the next version's per-feature steps files into its checklist in the same record commit and handles marking a version shipped ([modules/roadmap/](./modules/roadmap/README.md)). If the production branch has commits the integration branch lacks (`git log --oneline origin/<integration>..origin/<production>`; the release merge commit itself always shows up here, a hotfix too), bring the production branch back into the integration branch with a PR.

## Merge style

The release PR uses a **merge commit**, not squash or rebase, so both branches share history and the next release's `git log origin/<production>..origin/<integration>` lists only new work.

## Versions

`vX.Y.Z` tags on the production branch. Before launch: `v0.x.y`, bumping the minor version per release and the patch version per hotfix; `v1.0.0` at launch. A project may use another scheme; it says so in `project/RELEASE.md`.

## Rollback

- **Code:** promote the previous production deployment in the host (how: `project/RELEASE.md` § Rollback). Then fix forward through a feature branch or a hotfix.
- **Database:** there is no rollback; a bad migration needs a forward fix. Hence every migration must be **additive** and safe to run **before** the code that uses it ships (step 4 relies on this): add columns and tables, don't rename or drop in the same release that stops using them.

## Hotfix

For a production bug that can't wait for the next release:

1. Branch from the production branch on the remote.
2. PR to the production branch (explicit base), only after QA **pass** on the hotfix and when the human asks.
3. **Tag it.** Every merge to the production branch is tagged, a hotfix too. After the hotfix PR merges, the next **patch** version (v0.6.0 → v0.6.1) goes on the PR's merge commit. If agents can't push tags, the Technical Lead gives the human the exact command with the merge sha: `git tag -a vX.Y.Z -m "Hotfix vX.Y.Z" <merge sha> && git push origin vX.Y.Z`. The hotfix isn't finished until the tag is pushed.
4. Bring the production branch into the integration branch (a PR), so the next release doesn't undo the fix.

## After release

- Both branches share the release merge commit; new feature branches keep starting from the integration branch.
- Release QA records stay in `_harness/releases/<version>/` as the history of what shipped and how it was checked.
