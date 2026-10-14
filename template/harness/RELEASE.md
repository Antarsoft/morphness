# Release: integration branch → production branch

Project specifics (production database, hosting, smoke checklist, environment variables, how migrations reach production): `project/RELEASE.md`. Branch names: `branches.integration` and `branches.production` in `harness.config.yml`; the shared environments and the branch each one runs: `environments` there.

## Branches

| Branch | Holds | Deploys to |
|--------|-------|------------|
| feature branch | One feature's work. Starts from the integration branch on the remote | nothing (or a per-PR preview, if the host makes one) |
| integration branch | Every feature that passed QA and was merged by the human (or by the Technical Lead with `merge_by_agent: integration`) | The integration environment (the first entry in `environments`), if the project has one |
| production branch | What is live. Moves only through a release PR or a hotfix | Production |

Feature PRs target the integration branch, always opened with an explicit base, whatever the default branch is (§ Default branch). When a PR is opened as a draft and marked ready: `.claude/rules/technical-lead.md` § Commits and branches. Release and hotfix PRs follow the same states: a draft until their QA passes, then ready for the human. Release, promotion and hotfix PRs are merged by the human only: no agent merges into a branch after the integration branch, whatever `merge_by_agent` says or a message asks.

**Single-branch flow.** When `branches.integration` equals `branches.production`, there is no release PR: feature PRs merge straight to production, so the release steps below shrink to release QA on that branch before the human's go, the production prerequisites, the tag and the record. Feature PR titles don't name a version, so the tag workflow (if any) tags a release only when the human runs it by hand with the version. Hotfixes are ordinary feature branches.

## Default branch

`branches.default` in `harness.config.yml` is the code host's default branch. It is the integration branch unless the project chose otherwise:

- **Integration branch (the default).** New PRs, `gh pr create` without `--base`, Dependabot and Renovate PRs and fresh clones (cloud sessions included) all land where feature work belongs, and "Fixes #N" closes the issue when the feature merges, not at the next release. The cost: visitors see the integration branch's README and files, which may describe unreleased work; scheduled workflows and the "Run workflow" button default to it, so the human picks the production branch in that menu for a production deploy or a manual tag (the deploy and tag workflows refuse the wrong branch); CodeQL default setup and code search follow it.
- **Production branch.** For a public library or tool whose visitors should see what shipped. Feature PRs then rely on the explicit base, and dependency bots need `target-branch` set to the integration branch.
- **Single-branch flow:** that branch.

Only the human changes it on the host (GitHub: Settings → General → Default branch; GitLab: Settings → Repository → Branch defaults). `/morph-doctor` checks it matches.

## Environments

`harness.config.yml` → `environments` lists the shared environments in the order code moves through them. The default is two: `dev`, which runs the integration branch, and `production`, which runs the production branch. Each entry names its branch, how it deploys (`host`, `workflow`, `manual` or `none`) and whether it holds real people's data (`real_data`).

- **The integration environment** is the first entry. Feature migrations reach it after the feature PR merges (`HANDOFFS.md`), and data-access stage B checks it.
- **The release QA environment** is the entry just before production. Release QA (step 3) runs there. With a single entry (production only) or none, release QA runs on a local build of the integration branch's head.
- **The release branch** is the branch of the release QA environment. It is the integration branch unless a middle environment has its own branch.
- **A middle environment** (for example `staging` between `dev` and `production`) either runs the integration branch too, deployed when a release is prepared, or has its own branch. With its own branch, code reaches it through a **promotion PR** from the previous environment's branch, titled `Promote vX.Y.Z to <environment>`, opened by the Technical Lead and merged by the human with a merge commit. Several middle environments are promoted in order.
- **`real_data: true`** means every deploy and migration there waits for the human's approval (the host's protected environment, `project/RELEASE.md`). Production always has it.
- **Changing the list.** Add, rename or remove an entry in `harness.config.yml`, then run `/morph-doctor`. It reports what is out of step: the `project/RELEASE.md` table, the deploy and migrations workflow choices, the branches on the remote. The host's own environments and secrets are the human's to change.

No agent writes to any of them (`AGENTS.md` § Shared remote environments), whatever the list says.

## Apps

In a monorepo, `harness.config.yml` → `apps` lists the apps and packages that are built, tested or deployed on their own. It is optional: with `apps: []` the whole repo is one app and nothing below applies.

- **Each app deploys on its own.** Its `deploy` map says, per environment name, how it gets there (`host`, `workflow`, `manual` or `none`), so a web app on one host and an API on another share the same environments and branches. `project/RELEASE.md` § Where things deploy has a row per environment and app.
- **Plans name the apps they touch** (`plan.md` § QA scope → **Apps touched**). The browser specs, the steps file and the human's deploy steps follow that list.
- **The release ships every app together.** The release PR lists which apps changed since the last release, so the human knows which deploys to watch. How versions are numbered (one for the repo, or one per package) is § Versions.

## Branch protection

Every branch in `environments` (always the integration and production branches) changes only through a merged PR: no direct pushes, no force-pushes, no deletion. Two layers hold this:

- **On the host (the real guard),** with `harness.config.yml` → `branch_protection.enabled: true`. On GitHub the human imports [.github/rulesets/environment-branches.json](../.github/rulesets/environment-branches.json) (Settings → Rules → Rulesets → New ruleset → Import a ruleset); it requires a PR with `required_approvals` approvals and blocks force-pushes and deletion. With `ci_gate: true` it also requires the CI check. On GitLab the human sets each branch as protected, with "Allowed to push" set to no one and force-push off. Merge style is not restricted, because the release PR uses a merge commit (§ Merge style).
- **For agents,** `.claude/settings.json` denies `git push` to each of those branches and every force-push. A deny matches command text, so it only catches mistakes.

When `environments` changes, the human updates the ruleset's branch list in the same change (`/morph-doctor` reports a branch that isn't covered). Agents never create or edit rulesets or protection settings.

## When a release happens

Only when the human says **"release"**. Never automatic, never as a side effect of merging a feature into the integration branch.

## What ships

All of the integration branch at the commit the release PR is opened from. Work that is not ready stays on its feature branch and is not merged into the integration branch until it is.

## Roles

| Role | Does |
|------|------|
| Technical Lead | Lists what ships, opens the release PR, delegates release QA, tags and records the release afterwards |
| QA engineer | Runs release QA on the release QA environment and writes `_harness/releases/<version>/qa-result.md` |
| Human (owner) | Says "release", applies production migrations and environment variables, merges, checks the live product |

Agents never touch remote databases or hosting settings: production migrations and environment variables are human steps (a project may apply migrations with a CI workflow that only the human runs; step 4).

## Release steps

1. **List what ships.** The Technical Lead fetches both branches, runs `git log --oneline origin/<production>..origin/<integration>`, and lists the features in it (from the merged PRs and `_harness/features/*`).
2. **Open the release PR as a draft** from the release branch to the production branch, with the base passed explicitly. When the release branch isn't the integration branch, open the promotion PRs first (§ Environments) and open the release PR once the human has merged them. Title `Release vX.Y.Z`. The body (the **Release notes** and **Release** sections of the PR template) gives a few lines of release notes for people using the product, and lists the features, a link to each feature's `qa-result.md` and steps file (if any), every new migration in order, and every new or changed environment variable.
3. **Release QA on the release QA environment** (§ Environments). The QA engineer runs the full `before_signoff` suite ([CONTROLS.md](./CONTROLS.md)) on the release branch's head plus the smoke steps that apply (`project/RELEASE.md` § Smoke checklist), and writes the result to `_harness/releases/<version>/qa-result.md` from [templates/release-qa-result.md](./templates/release-qa-result.md). The human's "release" command is acted on (steps 4 to 7, anything that reaches production) only after that file says **pass**; until then the command only starts steps 1 to 3. On a fail, fixes go through feature branches into the integration branch, the release PR picks them up (through a new promotion PR when there is a middle branch), and release QA runs again. On a pass the Technical Lead marks the release PR ready.
4. **Production prerequisites (human).** The human applies the new migrations to production and sets the new or changed environment variables **before** merging, so the code never runs against a schema or config it doesn't expect. A project may have the human run a CI workflow that applies them instead; how this one does it: `project/RELEASE.md`.
5. **Merge (human).** The human merges the release PR; the host deploys production from the production branch.
6. **Live check (human).** The human checks the live product and says it is good.
7. **Tag and record (Technical Lead).** With `release_tags: false`, skip the tag. With the tag workflow (`ci_cd.tags`), the merge tags itself from the PR title: check the tag is there (`git ls-remote --tags origin vX.Y.Z`), and if it isn't (the run failed, or the title didn't match), ask the human to run the workflow by hand with the version. Without the workflow, tag the production branch: `git tag -a vX.Y.Z -m "Release vX.Y.Z" origin/<production>`, then push the tag. If agents can't push tags here (cloud sessions can't), the TL gives the human the exact command. Record the release in `_harness/LEARNINGS.md` and, with the roadmap module, in the roadmap's changelog; the roadmap module also folds the next version's per-feature steps files into its checklist in the same record commit and handles marking a version shipped ([modules/roadmap/](./modules/roadmap/README.md)). If the production branch has commits the integration branch lacks (`git log --oneline origin/<integration>..origin/<production>`; the release merge commit itself always shows up here, a hotfix too), bring the production branch back into the integration branch with a PR (and into each middle environment's branch, in order).

## Merge style

The release PR and any promotion PR use a **merge commit**, not squash or rebase, so both branches share history and the next release's `git log origin/<production>..origin/<integration>` lists only new work.

## Versions

`vX.Y.Z` tags on the production branch, when `harness.config.yml` → `release_tags` is `true` (the default). Tags mark exactly what shipped and are the reference for rollbacks and hotfixes; nothing in the harness reads them back, so a project that doesn't want them sets `release_tags: false` and keeps the release PR title and `_harness/releases/<version>/` as its record. With the `ci-cd` module's tag workflow, the merge itself creates the tag and its release; the version in the PR title (`Release vX.Y.Z`, `Hotfix vX.Y.Z`) is then what gets tagged, so get it right before the merge. Before launch: `v0.x.y`, bumping the minor version per release and the patch version per hotfix; `v1.0.0` at launch. A project may use another scheme; it says so in `project/RELEASE.md`.

## Rollback

- **Code:** promote the previous production deployment in the host (how: `project/RELEASE.md` § Rollback). Then fix forward through a feature branch or a hotfix.
- **Database:** there is no rollback; a bad migration needs a forward fix. Hence every migration must be **additive** and safe to run **before** the code that uses it ships (step 4 relies on this): add columns and tables, don't rename or drop in the same release that stops using them.

## Hotfix

For a production bug that can't wait for the next release:

1. Branch from the production branch on the remote.
2. Draft PR to the production branch (explicit base) at the first push, marked ready after QA **pass** on the hotfix; the human merges. Title `Hotfix vX.Y.Z`, with the next **patch** version (v0.6.0 → v0.6.1). The body uses the PR template's **Release notes** and **Hotfix** sections.
3. **Tag it** (with `release_tags: true`). Every merge to the production branch is tagged, a hotfix too, on the PR's merge commit. With the tag workflow, the merge does it; the Technical Lead checks the tag exists, as in release step 7. Without it, when agents can't push tags, the Technical Lead gives the human the exact command with the merge sha: `git tag -a vX.Y.Z -m "Hotfix vX.Y.Z" <merge sha> && git push origin vX.Y.Z`. The hotfix isn't finished until the tag is there.
4. Bring the production branch into the integration branch (a PR), and into each middle environment's branch when there are any, so the next release doesn't undo the fix.

## After release

- Both branches share the release merge commit; new feature branches keep starting from the integration branch.
- Release QA records stay in `_harness/releases/<version>/` as the history of what shipped and how it was checked.
