---
name: morph-doctor
description: Check an installed Morphness harness for broken wiring, drift and a due prune, and count the upstream kit updates and lessons waiting for it. Use when the user asks to check, diagnose or health-check the harness, or after editing harness.config.yml.
---

# morph-doctor

Read-only by default. Report findings, then offer fixes; change files only on the user's yes, on a
branch, never on the integration or production branch.

## 1. Wiring

Run render.md § Self-checks from the morph-init skill against the current repo (placeholders left,
fill comments left, JSON parses, relative links resolve, agent frontmatter, every named check in
`harness.config.yml` § checks has a command in `project/CONTROLS.md`, `scripts/session-start.sh` is
executable and parses with `bash -n`). Never run `scripts/session-start.sh` itself: it installs
dependencies, so it is not a read-only check. A row whose command is "none" or "not configured"
(written by an older install): offer to delete it, its `project/STACK.md` row and its name from
`checks`, as render.md § 3b now does. Also:

- **Schema:** `harness.config.yml` → `harness_schema` is `1`, the number this skill knows. Missing: a
  copy installed before the key existed; point to `/morph-update` (update note `2026-10-21-harness-schema`).
  Lower: the kit has moved to a new major version and this copy hasn't; point to `/morph-update`, whose
  migration note sets the new number. Higher: the copy is newer than this plugin; say so and suggest
  updating the plugin before trusting the rest of this report.
- Every module in `modules` has its folder; no folder under `harness/modules/` is missing from
  `modules` (stale rules agents would read). Offer the fix through `/morph-module add <name>` (a
  module listed but never installed) or `/morph-module remove <name>` (a folder left behind).
- Every agent file under `.claude/agents/` points at a body under `harness/agents/` that exists.
- **Required tools:** `git`, `python3`, `awk`, `perl`, `grep`, `sed`, `sort`, `tr` and `wc` are on PATH
  (`command -v`), `python3 -I -c 'import sys; print(sys.version_info >= (3, 7))'` prints `True` (a stub
  python3, such as macOS's before the Command Line Tools are installed or the Microsoft Store alias, passes
  `command -v` but not this), and `bash` is the shell the hooks run in (native Windows without Git Bash is
  not supported). Report each gap with what stops working: no `python3` makes `scripts/guard.sh` block
  every tool call (it fails closed; `guard.fail_open: true` lets them through) and stops the cost, evidence
  and learned-rules scripts (the prune counter runs without its trial and rule-tag counts); a stub or a
  Python older than 3.7 leaves the guard unable to check calls (a stub that fails blocks every call, one
  that exits 0 lets every call through unchecked, an older Python misses some; `guard.fail_open` doesn't
  apply); no `awk` makes every `harness.config.yml` setting read as
  empty, so the guard protects no branch and the other scripts run on their defaults or stop with a
  not-measured line; no `perl` stops `/morph-module remove`; no `grep`, `sed`, `sort`, `tr` or `wc` stops
  the prune counter (and without `grep`, `sort` or `tr` the guard protects no branch); no `git` stops the process. Neither `timeout` nor `gtimeout` (stock macOS): say that
  `scripts/session-start.sh` uses perl for its time limit, and runs without one when perl is missing too.
- **Session commands:** `.git/morphness-session-commands` exists and matches the two commands in
  `scripts/session-start.sh`. A mismatch means the commands changed since this clone last ran them and
  session start is holding them: show the owner both versions and, on a yes, run
  `bash scripts/session-start.sh --accept`. A copy whose script lacks the pin: point to `/morph-update`.
- **Guard hook:** `.claude/settings.json` → `hooks.PreToolUse` runs `scripts/guard.sh`, the script
  exists, `python3` is installed (without it the guard blocks every call, unless `guard.fail_open: true`), and the push test in
  render.md § 7 item 9 exits 2. A copy without the hook: point to `/morph-update` (update note
  `2026-10-17-guard-hook`). `guard.mcp_writes: off`: mention once that connector writes then rely on
  the named `ask` rules alone; `guard.deploys`, `guard.publishes`, `guard.schema_pushes`, `guard.network` or `guard.installs: off` the
  same for that group (nothing asks before it runs).
- **Permission prompts:** `.claude/settings.json` has `permissions.defaultMode` and the check allow rules
  (`/morph-init` Q14). Missing in an installed copy: say that file edits and every check command prompt in
  Claude Code's default mode, and offer to add them from the template's `.claude/settings.json` and
  `project/CONTROLS.md` (update note `2026-10-20-fewer-permission-prompts`). A project that answered no
  keeps its prompts; don't offer again. A `Bash(<interpreter>:*)` allow rule (`bash`, `sh`, `npx`, `node`,
  `python`) lets any code through without a prompt: report it.
- Module markers (`harness/README.md` § Modules → **Module markers**): no `module:<name>` marker
  for a module missing from `modules` (text left from a removal: offer the removal command), and every
  `<!-- module:<name> -->` opening line has its closing line.
- **No remote yet** (`git remote` prints nothing): skip every check here that reads the remote or the
  code host, and say so once. With `pr_host` other than `none`, say the project isn't online yet and
  offer to create it (morph-init render.md § 1, "No remote yet").
- **Online since the install** (a remote exists but `pr_host: none`, or the install ran with no
  remote): say it plainly ("Your project is online now. Want to finish the setup for that? I'll ask
  the questions that were skipped at install.") and on a yes: push the integration and production
  branches if the remote lacks them, set `pr_host` from the remote's host, ask morph-init's skipped
  questions (questions.md Q7 from "Whether the automatic checks must pass", the merge question, Q9b),
  copy back from the Morphness source what the install removed for `pr_host: none` (the PR template,
  `.github/rulesets/environment-branches.json` and the `harness/RELEASE.md` sections that point to it),
  render the matching parts of render.md § 3b and § 4, then offer § 7b.
- The branches in `harness.config.yml` exist on the remote (`git ls-remote --heads origin <name>`).
- `environments` (when the key exists): names are unique; the first entry runs `branches.integration`
  and the last runs `branches.production`; every entry's branch exists on the remote; `deploy` is one
  of `host`, `workflow`, `manual`, `none`, and `workflow` only when `ci_cd.deploy` is a path; the last
  entry has `real_data: true`; `project/RELEASE.md` § Where things deploy has one row per entry, in
  order. After the owner edits the list, report each file still out of step (that table, the deploy
  and migrations workflow choices and branch guards) and offer to bring them in line. The host's own
  environments, reviewers and secrets can't be read from here: remind the owner to create or rename
  them to match, with required reviewers on every `real_data: true` entry. A copy without the key
  (installed before it existed): point to `/morph-update`.
- `apps` (when non-empty): every `path` exists; names are unique; every `deploy` key is a name in
  `environments` and every value is `host`, `workflow`, `manual` or `none`; `project/STACK.md` § Apps
  has a row per app; with the ci-cd module, the deploy workflow has a job for each app that has
  `workflow` for some environment. A workspace package with its own deploy config that isn't in
  `apps`: mention it once. A copy without the key behaves as `apps: []`; point to `/morph-update`
  only if the owner wants per-app tracking.
- `branches.default` matches the host's default branch (`git remote show origin | sed -n 's/.*HEAD branch: //p'`, or `gh repo view --json defaultBranchRef`). A mismatch is the owner's step (harness/RELEASE.md § Default branch). A copy without the key: point to `/morph-update`.
- `branch_protection.enabled: true`: every environment branch is in the ruleset file's `include` list
  and has `git push` denies in `.claude/settings.json`. When `gh` can read it, check each branch's
  live rules (`gh api repos/<owner>/<repo>/rules/branches/<branch>`) for `pull_request`,
  `non_fast_forward` and `deletion`, and with `ci_gate: true` the CI check. Report each missing rule
  as a fix you can apply: on the owner's yes, run morph-init's render.md § 7b (it hands the owner
  the file and command when it can't apply). If the rules can't be read, ask the owner.
- `branch_protection.delete_merged_branches` matches the host (`gh repo view --json
  deleteBranchOnMerge`); offer render.md § 7b step 2 when it doesn't. Flag
  `delete_merged_branches: true` with `enabled: false`: an unprotected environment branch would be
  deleted when a release PR from it merges.
- With the ci-cd module: every path in `ci_cd` exists; the CI workflow has one step per `before_qa`
  check whose command matches `project/CONTROLS.md` (report each missing or differing step); no runner
  image ends in `-latest`; the CI workflow uses `pull_request`, not `pull_request_target`, lists `ready_for_review` in its
  `types` and has a `merge_group` trigger, skips drafts exactly when `ci_cd.on_drafts` is false (and the value in the `if:` line is the literal `true` or `false`, not a placeholder or other text), every `uses:` pins a full 40-character commit SHA (a version tag or branch is reported; the fix is to pin the SHA the tag points to), and reads no
  `secrets.` other than `GITHUB_TOKEN`; deploy and migrations jobs name an `environment`, and their
  `options` list exactly the names in `environments`; a tag
  workflow exists only with `release_tags: true`. `Bash(gh api*rulesets*)` and `Bash(gh api*protection*)`
  are `ask` rules in `.claude/settings.json`, not `deny`: a deny blocks render.md § 7b. Offer to move
  them (update note `2026-10-16-ci-cd-ruleset-ask`).
- With the security module: `secrets` and `audit` are in `checks.before_qa` and
  `checks.before_signoff` with commands in `project/CONTROLS.md`; each tool the commands start is
  installed (its version command; a missing one is the owner's install, reported once); the secrets
  command redacts (gitleaks: `--redact`); `project/CONTROLS.md` § Security paths is filled; and each
  row in § Security exceptions has a reason, an approval and a review date that hasn't passed (report
  each one past it).
- `release_tags: per-package`: the versioning tool named in `project/RELEASE.md` § Versions has its
  config in the repo (`.changeset/config.json`, `nx.json` → `release`, `release-please-config.json`,
  `lerna.json`), and no Morphness tag workflow is in `ci_cd.tags`. Any other value than `true`,
  `false` or `per-package` is reported.
- `merge_by_agent`: `never` has the merge `ask` rules in `.claude/settings.json` (`gh pr merge`,
  the code host's merge tools); `integration` with `branches.integration` equal to
  `branches.production` is reported, because it acts as `never` there.
- `ci_gate: true`: CI exists, and when `gh` can read it, the integration branch requires the CI
  check (`gh api repos/<owner>/<repo>/rules/branches/<integration>`). If it can't be read, ask the
  owner instead of reporting a failure. `ci_gate: false` with a CI that has passed on the integration
  branch: mention that the owner can make it required and set `ci_gate: true`.

- **Installed skills match their pin:** each row in `project/SKILLS_AND_MCPS.md` § Installed (repo)
  names `<owner/repo>@<40-character commit>`; report a row without one as unpinned (the owner may
  accept that). With `git` and network, for each pinned row clone the source into an empty temporary
  folder, check out the commit and diff the skill's folder against the installed path (`diff -r`,
  read-only, nothing installed or run); report each skill whose files differ (changed since install, or
  edited locally) and list the changed files, because skill text enters the agents' context. A source
  that can't be fetched is "not checked", not a pass. Also report a pin that differs from the one in
  the upstream `catalog.md` as available to review through `/morph-update`, not as a fault.
- **Built-in skills:** `code-review` and `security-review` are in this session's skill list. Report
  each missing one with its fallback (morph-init `references/catalog.md` § Built-in skills).
- **Service tools:** `project/SKILLS_AND_MCPS.md` § Service tools has a row for every external service
  named in `project/STACK.md` and `project/RELEASE.md`. Compare each row's "Connected as" with the MCP
  tools this session has, and report rows older than 90 days (offer a research-mode re-check, which
  may find an official MCP that didn't exist before). Every connected write tool has an `ask` (or, for
  a remote database, `deny`) rule in `.claude/settings.json`; report each one without. A copy without
  the section: point to `/morph-update`.

## 2. Loop health

From `_harness/`:

- **Prune due:** run `bash scripts/prune-counter.sh` (when the copy lacks it, count the `*-v*.md` files
  in `_harness/learnings/`). When it prints `Prune is DUE` or `Prune proposal waiting`, say "Prune due" and point to
  `harness/SETUP.md` § Prune, naming the `proposed` file in `_harness/prunes/` waiting for the owner, or
  "no proposal yet" (the TL writes it as its next task). Report its `Rules:`, `Checklists:` and `Project docs:` gauge lines as they are, and name the largest files when one is above 90% of its budget (`loop.rule_budget_kb`, `loop.checklist_budget_kb`, `loop.project_docs_budget_kb`). A copy whose script prints no `Rules:` line:
  point to `/morph-update` (update note `2026-10-17-rule-budget`). A missing script is drift worth naming: `/morph-update` adds it.
- **Feature cost:** with `cost.track` on (or no `cost:` key), `bash scripts/feature-cost.sh` runs and
  prints a `Cost` line (in a fresh session it may say `not measured`, which is fine; a Python error
  is not). Every model in `agents:` (`model`, `medium_model`, `high_model`), mapped to its current
  `claude-…` id, has a row in the price table (`cost.prices`, default `harness/MODEL_PRICES.md`).
  Report a missing row and a `Prices as of` date more than six months old. A missing script or table
  is drift: `/morph-update` adds them.
  Also `loop.feature_budget_usd` (the soft cap): report its value (`0` or missing means off), flag a
  value that isn't a number of at least 0, and say the cap does nothing while `cost.track` is false.
- **Open action items:** retro items in `_harness/LEARNINGS.md` still `open` or `approved` but not
  `applied` for more than two features.
- **Trials:** active trials in `_harness/trials/` (the `Trial` lines `scripts/prune-counter.sh` prints) that have run their length with no decision. A copy that still keeps trials as rows in `_harness/LEARNINGS.md` § Trials: check those, and point to `/morph-update` (update note `2026-10-17-trial-files`).
- **Stuck features:** feature folders whose `plan.md` Status is `approved` with no `progress.md`, or
  `progress.md` marked complete with no `qa-result.md`.

## 3. Learned rules

Run `bash scripts/learned-rules.sh` (read-only; a copy without it: `/morph-update`, update note
`2026-10-21-learned-rules-list`). It lists every rule with provenance: where it is, the finding it came from,
when it landed, the last day a learnings entry said it fired (blank if never recorded) and its text;
untagged rules are counted per file (`--all` lists them with blank columns). Report the counts and
show the table on request. Tagged rules never recorded as fired are what the next prune audits, not a
problem by themselves.

## 4. Drift

Compare the harness files to their template (`template/` in the Morphness source at the commit in
`harness.config.yml` § installed_from, the commit this copy last synced to) and summarise how the copy has morphed: rules added, removed or
changed, with their provenance where given. This is information, not a problem: the copy is meant to
diverge. Flag only contradictions (two rules that say opposite things) and links to removed files.

## 5. Upstream

List what is newer upstream, read-only, by following § 1 and § 2 of `/morph-update` (they write nothing): kit updates and
matching lessons added upstream since `installed_from.commit` that this project hasn't applied or
declined, plus adopted lessons now superseded. Report only the counts, with fixes named one by one
(`1 fix, 2 kit updates, 4 lessons available: run /morph-update`). Don't apply anything and don't
change `installed_from`; that is `/morph-update`'s job. The listing reads release notes and template
text from github.com/antarsoft/morphness (read-only, executes nothing, no clone needed) unless
`updates.source` is `local`, and falls back to a local copy; with neither, say "upstream not checked".

## 6. Report

One short list, worst first: broken wiring, then a due prune and stuck items, then contradictions,
then the counts of pending upstream updates and lessons (pointing to `/morph-update`). End with the fixes you can make and ask which to apply.
