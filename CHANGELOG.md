# Changelog

Dated releases, newest first. Installed copies pick up kit changes (each with a note in
[updates/](updates/)) and new matching lessons through `/morph-update`; this file lists every change.
When releases are cut: [CONTRIBUTING.md](CONTRIBUTING.md) § Releases.

## Unreleased

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
