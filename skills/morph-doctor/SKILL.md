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
`harness.config.yml` § checks has a command in `project/CONTROLS.md`, session-start exits 0). Also:

- Every module in `modules` has its folder; no folder under `harness/modules/` is missing from
  `modules` (stale rules agents would read).
- Every agent file under `.claude/agents/` points at a body under `harness/agents/` that exists.
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
  `types` and has a `merge_group` trigger, skips drafts exactly when `ci_cd.on_drafts` is false, and reads no
  `secrets.` other than `GITHUB_TOKEN`; deploy and migrations jobs name an `environment`, and their
  `options` list exactly the names in `environments`; a tag
  workflow exists only with `release_tags: true`.
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

## 2. Loop health

From `_harness/`:

- **Prune due:** run `bash scripts/prune-counter.sh` (when the copy lacks it, count the `*-v*.md` files
  in `_harness/learnings/`). When it prints `Prune is DUE`, say "Prune due" and point to
  `harness/SETUP.md` § Prune. A missing script is drift worth naming: `/morph-update` adds it.
- **Open action items:** retro items in `_harness/LEARNINGS.md` still `open` or `approved` but not
  `applied` for more than two features.
- **Trials:** trials in `_harness/LEARNINGS.md` § Trials with no decision past their end condition.
- **Stuck features:** feature folders whose `plan.md` Status is `approved` with no `progress.md`, or
  `progress.md` marked complete with no `qa-result.md`.

## 3. Drift

Compare the harness files to their template (`template/` in the Morphness source at the commit in
`harness.config.yml` § installed_from, the commit this copy last synced to) and summarise how the copy has morphed: rules added, removed or
changed, with their provenance where given. This is information, not a problem: the copy is meant to
diverge. Flag only contradictions (two rules that say opposite things) and links to removed files.

## 4. Upstream

Run the morph-update skill's listing (its § 1 and § 2, which change nothing): kit updates and
matching lessons added upstream since `installed_from.commit` that this project hasn't applied or
declined, plus adopted lessons now superseded. Report only the counts, with fixes named one by one
(`1 fix, 2 kit updates, 4 lessons available: run /morph-update`). Don't apply anything and don't
change `installed_from`; that is `/morph-update`'s job. With no network, say "upstream not checked".

## 5. Report

One short list, worst first: broken wiring, then a due prune and stuck items, then contradictions,
then the counts of pending upstream updates and lessons (pointing to `/morph-update`). End with the fixes you can make and ask which to apply.
