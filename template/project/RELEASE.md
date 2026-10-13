# Release: {{project.name}} specifics

The process is in [harness/RELEASE.md](../harness/RELEASE.md). This file holds what is specific to this repo. Every step here is **owner-only** unless it says otherwise: agents never change a production or shared environment (database, hosting, payment provider, DNS). The owner is {{human.name}}.

## Where things deploy

| Environment | Branch | Hosting | Database or backing services | Deploys by |
|-------------|--------|---------|------------------------------|------------|
<!-- morph-init: fill one row per entry in harness.config.yml → environments, in the same order, e.g. "| dev | `dev` | Dev deploy (automatic on push) | dev database | host |" and "| production | `main` | Production | production database | host, after the release PR merges |". With no shared environments, write one line saying nothing is deployed and release QA runs locally. -->

Release QA ([harness/RELEASE.md](../harness/RELEASE.md) step 3) runs on the release QA environment, the row just before production: <!-- morph-init: fill which one and its URL, e.g. "dev, https://dev.example.com", or "a local build" when production is the only row -->. QA stays read-only there, as everywhere.

<!-- morph-init: with a single-branch flow (integration equal to production), say so here and that a release is a tag on that branch. -->

## Manual steps

Everything a workflow does not do automatically is a step someone does. List each one; skip one and nothing warns you.

| When | What to do | Who |
|------|------------|-----|
<!-- morph-init: fill. On install, when the host's default branch isn't `branches.default` in harness.config.yml, add first: "| Once | set the repository's default branch to `<branches.default>` (harness/RELEASE.md § Default branch) | owner |". Examples: "| After merging a PR that adds a migration | run the migrations workflow on the integration branch and check it ran, not skipped | owner |", "| Release PR, before the merge | apply production migrations with the production workflow | owner |". When CI is not a gate (harness.config.yml → ci_gate: false), add: "| Before handoff to QA and again in QA | run every named check locally; `qa-result.md` is the gate | Full-stack, QA |". -->

## Production migrations

<!-- morph-init: fill only when the project has a database. Which workflow or command applies migrations to each environment, who runs it (never an agent), the order when there are several migration tracks, and how to check nothing is pending afterwards. Migrations must be additive: production runs the old code against the new schema between the apply and the merge. Delete the section when there is no database. -->

### Break-glass (owner only)

<!-- morph-init: fill the manual path when the workflow can't run (an outage, a hotfix that needs a migration), and the `.claude/settings.json` denies that keep agents off it. -->

## Production configuration

<!-- morph-init: fill where production env vars and secrets are set, and when a change takes effect (for example "only for deployments created afterwards, so set it before the merge"). -->

## Service checks before a release

<!-- morph-init: fill per external service the release may touch (payments, email, auth provider): what the owner checks in its dashboard before a release that changes it. Delete when there are none. -->

## Smoke checklist

Release QA (on the release QA environment) and the owner's live check (on production) use the steps that apply to the release:

<!-- morph-init: fill 3 to 6 checkbox steps covering the core journey. Example:
- [ ] Sign up with a real email, confirm it, log in.
- [ ] Create the core object and see it listed.
- [ ] Billing releases only: upgrade with a test card, then cancel.
-->

## Rollback

<!-- morph-init: fill how to put the previous production deploy back (for example "promote the previous deployment in the hosting dashboard"). The database is not rolled back; fix forward ([harness/RELEASE.md](../harness/RELEASE.md) § Rollback). -->
