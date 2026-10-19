# Changelog

Dated releases, newest first. Installed copies pick up kit changes (each with a note in
[updates/](updates/)) and new matching lessons through `/morph-update`; this file lists every change.
When releases are cut: [CONTRIBUTING.md](CONTRIBUTING.md) § Releases.

## Unreleased

- Three process rules: a retro item that adds a sentence says why a script or check can't do the job;
  a retro item tagged `cause: environment` goes to the owner, never a rule on the Technical Lead's own
  yes; a check the environment refused is recorded "not run", never an "equivalent".
- Small, bug and security wording lined up across the rules, plans and agent bodies (small plan QA scope
  and limit, security review on bug plans, full-mode-only sections marked, lighter agent reads and QA
  layout pass); `prune-counter.sh` shows a waiting prune proposal.
- The advised Claude Projects settings follow the Sonnet default: coordinator, feature threads and
  one-shot threads on sonnet (medium, high, medium), with opus at high advised for a review, research
  or architecture thread. `/morph-init` still advises opus in all three with the Opus preset.
- The prune proposal no longer waits for the owner: when `scripts/prune-counter.sh` prints
  `Prune is DUE`, the Technical Lead writes `_harness/prunes/<date>.md` before the hand-off, which
  says `Prune is DUE: proposal written at <path>`. The owner only decides its rows; nothing is
  applied without that, and the next feature doesn't wait. The Claude Projects coordinator posts once
  per proposal, and `/morph-doctor` names the proposal waiting for a decision.
- Updates without a clone: `/morph-update`, `/morph-doctor`, the prune's upstream check and
  `UPDATE.md` read the newest release, its update notes, lessons and template text straight from
  github.com/antarsoft/morphness with read-only requests (nothing fetched is executed, no account
  needed), and fall back to a local clone when GitHub can't be reached. New config key
  `updates.source: github | local` (default `github`). Reads use `gh api --method GET` when `gh` is
  signed in and scoped `curl -fsSL` otherwise; `/morph-init` allows exactly those reads so they don't
  prompt, and the guard hook asks before any `gh api` write to a Morphness repository. Only released
  updates are offered.
- Trials as files: `_harness/trials/<trial-slug>.md` (template `harness/templates/trial.md`) holds the
  hypothesis, the change, its length in features, the metric and the pass and revert conditions. A
  feature that runs one names it on its learnings file's **Trial** line, the prune counter prints
  `Trial <slug>: N/<length> features` in every hand-off, and the prune decides keep or revert from
  the numbers. Replaces the table in `_harness/LEARNINGS.md` § Trials.
- Prune trend line: `bash scripts/prune-counter.sh --prune` prints one summary of the window (average
  rework rounds, QA fails, total cost) for the prune proposal, plus each trial's numbers.
- Rule provenance with a date: a rule a retro adds ends with `(from <feature>, <date>)`, and
  `prune-counter.sh --prune` lists each tag with the features finished since, for the rule audit.
- Small mode, between light and full and the default for a clear request: a fully specified change
  in a few named files that alters no access, money, stored data's shape or deletion, secrets,
  dependency or flow gets a short plan (`harness/templates/small-plan.md`) instead of `feature.md`,
  the full plan and the checklist run; Full-stack and QA still run, at `medium`, and the learnings
  file replaces `retro.md`. `risk_areas` now means "changing how this behaves needs full mode".
- Closing an access gap closes every read path too (exports, search, stats), and with the owner
  away the plan closes it rather than leaving the leak open (plan checklist item 29).
- QA's layout pass: on a UI change, every page at the narrowest supported width, signed in and out.
- Sonnet in every role by default; `/morph-init` offers Opus for planning and building as a preset.
- Retro rules come from misses only, and `scripts/prune-counter.sh` gauges the plan checklists
  against the new `loop.checklist_budget_kb`.
- A bug found after a pass always gets a retro item (the rule, check or test that would have caught
  it, or why none would), and its fix closes the same gap on sibling paths.
- `scripts/prune-counter.sh` gauges `project/*.md` against the new `loop.project_docs_budget_kb`, and
  the prune can condense those docs; `PROJECT.md` keeps architecture, not full route lists.
- `/morph-init` suggests risk areas as behaviours (access, money, deletion, migrations, secrets),
  not whole layers like API routes.
- QA's layout pass fails any overflow when the request is about layout or screen size.
- README: what Morphness adds is process (plan, QA record, audit trail, rules from misses), not a
  smarter model.
- Security module (optional): features that change who can sign in or read or change data, move
  money, handle secrets or delete people's data (never small-mode changes) fill a short threat model in `plan.md` § Security, each mitigation tied to a tested acceptance criterion, and get
  the security review before QA whatever their effort. Two named checks run on every feature:
  `secrets` (secret scanning, always redacted) and `audit` (the stack's dependency audit, judged only on
  packages the branch added or upgraded). `/morph-init` asks for it (Q11b) and `/morph-doctor` checks
  the tools, the commands and accepted advisories past their review date.
- `/morph-module add|remove <name>`: adds or removes a module on an installed project. It asks the
  module's install questions, puts its marked text back from the kit (or deletes it), runs On install
  or On remove, keeps the project's own files unless the owner says otherwise, updates `modules` and
  runs `/morph-doctor`. The kit self-test now checks every module can be added back (On install and
  On remove sections, and a unique anchor line for each marked span).
- Guard hook: `scripts/guard.sh` runs before Bash, file and MCP tool calls and reads commands the way
  the shell does. It blocks pushes to environment branches in every form (a bare `git push` on one,
  `HEAD`, `--all`, inside `bash -c` or `$(…)`), force-pushes, `.env` files other than the example,
  code-host secrets and well-known remote database writes, and asks before `gh api` writes to rulesets
  and protection and before any MCP tool that isn't a read (`guard.mcp_writes`). The settings deny
  rules stay as a second layer. `/morph-init` checks it and `/morph-doctor` reports a missing guard.
- Rule size gauge: the prune counter prints `Rules: X/36 KB always loaded` for the hand-off, and a
  prune is due when the always-loaded rules pass `loop.rule_budget_kb`.
- Kit self-test: `scripts/kit-selftest.sh` (and the `selftest` CI check) renders the template for four
  sample projects and runs the install self-checks, a link check, the scripts and the guard cases.
- Bug mode, next to full, light and research: for something that worked and is broken. A short bug
  plan (`harness/templates/bug-plan.md`) replaces `feature.md` and the full plan; QA writes the
  failing regression test and the Technical Lead commits it before any fix; Full-stack writes the
  root cause in `progress.md` before the smallest fix, and stops at the plan's fix limit; QA
  re-runs with the test unchanged. The learnings file, with its **Escaped** line, replaces
  `retro.md`. A hotfix is bug mode on the production branch.

## 2026-10-16

- Script fixes: `prune-counter.sh` and `feature-cost.sh` read `harness.config.yml` in block or
  one-line style through one shared reader (`scripts/lib/config.sh`); `feature-cost.sh --since`
  without a zone means UTC, as documented; the prune counter no longer counts files a prune already
  folded; `session-start.sh` skips the dependency install when the lockfiles haven't changed.
- A plan checklist group that doesn't fit the project (UI for a CLI tool, Data for a plan that stores
  nothing) is marked n/a in one Greps line. The release QA template and the PR template take their
  check rows from `checks` instead of listing the default checks.
- ci-cd module: an automatic deploy on push runs CI on that commit first and deploys only when it
  passes. The back-merge after a release is its own step in `harness/RELEASE.md`, with a box in the
  PR template.
- Code review before QA never gets skipped: when the built-in `code-review` or `security-review`
  skill is missing, the Technical Lead runs a read-only subagent with the same brief and
  `Plan/review.md` says so. `/morph-init` and `/morph-doctor` check that both skills are present.
- Light mode has a Full-stack brief in `harness/HANDOFFS.md`, and `harness/MODES.md` says what
  record a light-mode change leaves: no QA agent, the checks it touches run scoped, and the PR (or
  commit message) lists them with their exit codes under a **Light mode** line.
- Module-only text in the kit is marked (`<!-- module:<name> -->`), so removing a module is one
  command (`harness/README.md` § Modules). `/morph-update` copies a module's marked text when you
  add it later, and `/morph-doctor` reports markers left for a module that isn't on.
- One owner per rule: rules written out in several files now live in one owner file, with links
  elsewhere (`harness/README.md` § Rule owners). `harness/CONTROLS.md` holds the only list of
  documentation paths, and changes to `.claude/settings.json`, hooks and skill scripts no longer
  count as documentation, so they get every check. Plans keep their state on the **Status** line.
- Wider deny rules in `.claude/settings.json`: more `.env.*` names can't be read or edited,
  `cat`/`head`/`tail`/`less`/`more` of any `.env*` path is denied, and pushes to an environment
  branch are caught on any remote, with trailing flags and as a `+` force refspec. A bare
  `git push` asks first.
- The researcher and legal writer get real tool limits: the researcher can't create files (it edits
  only the research file it's given, between its two `---` lines), and the legal writer only reads
  and writes its legal copy, with no shell, web or MCP tools.
- `/morph-doctor` checks `session-start.sh` with `bash -n` instead of running it.
- A check the project doesn't have (no lint yet, no browser tests) is left out of
  `project/CONTROLS.md`, `project/STACK.md` and `checks`, instead of marked "none".
- The ci-cd module asks before `gh api` calls on rulesets and branch protection instead of denying
  them, so `/morph-init` and `/morph-doctor` can apply protection once you allow the prompt.
- The Technical Lead rule is about 40% shorter (19 KB to 11 KB): every hard rule stays as one line,
  with the detail moved to the file that owns it (`harness/RELEASE.md` § Feature PRs,
  `harness/HANDOFFS.md` § Threads and § Background agents, `harness/SETUP.md`). The process is
  unchanged.

## 2026-10-15.2

- Retro action items have a soft limit: `loop.retro_max_items` is the usual number, not a cap. A
  retro has only the items its findings call for (none is normal) and may go over when each extra
  item answers a different finding, with a line saying why. Every item gets a **Why raised** column
  (the finding it answers and its evidence), and the prune uses it to check whether the problem came
  back after the item landed.
- Setup work through connectors: before handing you a console chore (create a hosting project, set a
  variable, add a domain or DNS record), the Technical Lead checks whether a connected official MCP,
  connector or plugin can do it, and if so offers to, running each action only after you approve it
  in chat. Nothing a connector writes runs automatically, and remote database changes, secret values,
  billing and people's access never go through an agent. What stays yours says why (no official MCP,
  one exists but isn't connected, or it has no tool for this). A new Service tools table records each
  service's official MCP, checked by the researcher; `/morph-init` suggests only official connectors
  and fills the table, and `/morph-doctor` keeps it current.
- Every feature now records an estimated dollar cost: `scripts/feature-cost.sh` reads Claude Code's
  own session transcripts and prices every API call at public API prices (table in
  `harness/MODEL_PRICES.md`, editable for your own rates), split by the Technical Lead and each
  subagent. The `Cost ≈ $…` line goes in the retro's run table, the learnings file and the end of
  every hand-off, light-mode tasks and research files included; the prune shows each feature's cost
  and the window's average next to the previous one. Useful on a Pro or Max plan too, as an estimate.
  `/morph-doctor` checks the script and that the price table covers your agents' models.
- Research files get a short look-back instead of a retro: when the Technical Lead records the
  decision it adds three lines (did its check confirm the findings, were the scope and researcher
  effort right, did the answer get used). The prune reads them and suggests tweaks, such as a
  default researcher effort for a kind of question. Research still never counts toward the prune.

## 2026-10-15

- Research mode: when you want an answer rather than a change (how something works, why a bug
  happens, which library fits), the Technical Lead writes the question in `_harness/research/`, a
  new read-only **researcher** subagent answers it with cited sources, and the Technical Lead checks
  it and records the decision. The researcher can also run before a plan for a wide search. Two
  variants: `researcher` (sonnet, medium) and `researcher-high` (opus, high). `/morph-init` offers it
  with the other agents.
- Projects that aren't online yet: `/morph-init` starts the git repository and the first commit when
  the folder has none, and creates the GitHub repository on the owner's yes (with plain website
  steps when it can't). Until a remote exists, agents use the local branches and merge on the
  owner's computer, and `/morph-doctor` offers to finish the code host setup once the project is
  online.
- `/morph-init` speaks plainly to owners who aren't developers: each technical term gets a few words
  of explanation the first time it comes up, and the code host and CI question is split into two
  questions in everyday words. It also warns early that GitHub's free plan can't protect branches on
  private repositories.
- When the branch protection can't be applied for the owner, they now get numbered steps for the
  GitHub website and for a terminal (including going into the project folder, or cloning it first)
  with the real names filled in, from the new `harness/RELEASE.md` § Applying it yourself.

## 2026-10-14.2

- `/morph-init` and `/morph-doctor` can apply the branch-protection ruleset with `gh api` on the
  owner's yes (and read it back), falling back to the file, import steps and command for the owner.
  New `branch_protection.delete_merged_branches` (on by default with protection) turns on automatic
  deletion of a PR's branch after it merges; `/morph-doctor` checks both.

## 2026-10-14

- `release_tags: per-package` for monorepos whose packages have their own versions (Changesets, Nx
  release, release-please): features add the tool's change files, releases are named by date, and
  the tool writes the `<package>@x.y.z` tags. `/morph-init` suggests it when it finds such a tool.
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
