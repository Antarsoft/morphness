# Changelog

Dated releases, newest first. Installed copies pick up kit changes (each with a note in
[updates/](updates/)) and new matching lessons through `/morph-update`; this file lists every change.
When releases are cut: [CONTRIBUTING.md](CONTRIBUTING.md) § Releases.

## Unreleased

- Monorepos can list their apps in `harness.config.yml` → `apps` (folder, stack, browser spec
  folder, and how each app deploys to each environment). Plans name the apps they touch, targeted
  browser specs follow them, and the ci-cd deploy workflow gets a job per app. `/morph-init` asks when
  it finds more than one app; with `apps: []` nothing changes.
- Full-stack can narrow its pre-QA checks to what the branch changed: a docs-only diff skips them,
  and each check can run its tool's affected mode (`pnpm --filter '...[origin/dev]'`,
  `vitest --changed`, `jest --changedSince`) or only when listed paths change
  (`project/CONTROLS.md` § Check scope). Cross-cutting paths and dependency changes still run
  everything, and QA's sign-off run and CI always run the full commands. `/morph-init` suggests
  the scopes from the stack.
- The prune counter is now a script: `scripts/prune-counter.sh` prints the `Prune counter: N/<prune_every>`
  line (and `Prune is DUE`) that ends every feature hand-off, counting the integration branch's
  learnings files too. With the `claude-projects` module the thread's closing reply carries it and the
  coordinator posts once in the project chat when a prune is due. `/morph-doctor` uses the script.
- The code host's default branch is now a choice: `branches.default` in `harness.config.yml`,
  recommended to be the integration branch when it is separate (so new PRs, dependency bots and
  clones land there, and issues close when a feature merges), or production for a public library.
  `/morph-init` asks, `harness/RELEASE.md` § Default branch lists the trade-offs, and `/morph-doctor`
  checks the host matches.
- Who merges PRs is now a setting: `merge_by_agent` (`never` by default, or `integration` to let the
  Technical Lead merge ready feature PRs into the integration branch once the merge gate holds).
  The rule spells out what counts as the human asking, production merges stay the human's, and
  `.claude/settings.json` prompts on every merge command. `/morph-init` asks; `/morph-doctor` checks.
## 2026-10-13.2

- Releases can now go out more than once a day: a later one adds its number to the date
  (`2026-10-14.2`), and the plugin version becomes `YYYYMMDD.N.0` so Claude Code sees every release as
  newer. `/morph-update` orders release tags by date, then number. Rules: CONTRIBUTING.md § Releases.
- The PR template says what to fill when a draft opens and what waits for ready, and gains a
  **Merge after** line, a **Release notes** section and a **Hotfix** section. The ci-cd tag workflow
  publishes only the Release notes section instead of the whole PR body. On GitLab, `/morph-init`
  writes the template as the default merge request template.
- Feature PRs now open as a draft at the feature branch's first push and are marked ready once QA
  passes (back to draft if QA fails later); release and hotfix PRs do the same. With the
  `ci-cd` module, CI skips drafts unless `ci_cd.on_drafts` is `true`, runs when a PR is marked
  ready, and runs in a merge queue. `/morph-init` asks about CI on drafts; `/morph-doctor` checks it.
- Shared environments are now a list in `harness.config.yml` (`environments`), defaulting to two:
  `dev` on the integration branch and `production` on the production branch. `/morph-init` asks
  whether you want more (a `staging` or `uat` in between, on the integration branch or its own
  branch with promotion PRs) or fewer (production only, or none). Release QA runs on the
  environment just before production, the ci-cd deploy and migrations workflows offer exactly the
  listed environments, and `/morph-doctor` reports what is out of step after you change the list.
- Branch protection on the host: `branch_protection` in `harness.config.yml` (on by default) and a
  GitHub ruleset to import that makes every environment branch PR-only, with no force-push or
  deletion. `/morph-init` asks for it and the number of approvals; `/morph-doctor` checks it.
- Release tags are now optional (`release_tags` in `harness.config.yml`, default on), and the
  `ci-cd` module can add a tag workflow that tags each merge to the production branch from the PR
  title (`Release vX.Y.Z`, `Hotfix vX.Y.Z`) and creates its release, so nobody pushes tags by hand.
  `/morph-init` asks about both.

## 2026-10-13

- Plugin icon for the Claude plugin directory listing.
- `/morph-init` no longer downloads the Morphness source itself: it uses its own plugin folder or a
  clone the user names. `/morph-share` asks for the showcase handle instead of reading it with `gh`.
- New `/morph-update` skill, and [UPDATE.md](UPDATE.md) for agents without the plugin. It lists the
  kit updates and community lessons added upstream since a copy last synced, explains why each fits,
  and applies only what the owner accepts, merging with local edits instead of overwriting them.
  Declined updates are never offered again; deferred ones come back next time.
- Kit changes now ship with an update note in `updates/`, checked by `scripts/check-updates.sh`.
- Every prune checks upstream read-only and lists pending updates in the proposal (`SETUP.md` § Prune,
  `templates/prune.md` § 3c). `harness.config.yml` → `installed_from` gains `release` and `updates`.
- `/morph-doctor` now only counts pending upstream items and points to `/morph-update`.
- `/morph-update` works from a Morphness clone the user or their agent makes (UPDATE.md step 2) and
  never downloads the source itself, like `/morph-init`.
- New optional `ci-cd` module. `/morph-init` can now set up pipelines (CI that runs the named checks
  on pull requests, an owner-run deploy workflow, and the migrations workflow the data-access module
  refers to), each one offered separately and written only when you say yes. Agents write pipeline
  files but never run deploys or migrations. `/morph-doctor` reports CI that has drifted from
  `project/CONTROLS.md`.

## 2026-10-12

First public release.

- Kit: Technical Lead, Full-stack, QA and legal-writer roles; plan checklist; retro and prune loop;
  modules for Claude Projects, data access, browser e2e, legal wording and roadmap.
- Skills: `/morph-init` (new and existing repos, including migrating an earlier harness),
  `/morph-doctor`, `/morph-share` (now offers a showcase listing as its own PR).
- Catalog: 112 lessons from Twinpage (68 practice, 24 stack, 20 service); profile
  `web-saas-nextjs-supabase`.
- Repo: README, contributing guide, code of conduct, security policy and issue templates.
