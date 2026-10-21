# Contributing

Morphness gets better when people send back what worked. The easiest contribution is a lesson.

## Lessons

1. In your project, run `/morph-share` after a prune. It picks rules your audit shows **fired**,
   strips project details and drafts files in `lessons/` format ([lessons/README.md](lessons/README.md)).
   You can also write one by hand.
2. Open a PR with the lesson files. One topic per PR; several lessons are fine.
3. The `lessons` check runs on the PR: valid frontmatter, a unique id, an existing `kind`, a
   `target` path that exists in `template/`, and no secrets-looking strings.

What gets merged:

- A rule that caught a real problem, with evidence (`fired` of at least 1). Rules that never fired
  belong in your own harness, not the catalog, until they do.
- Portable wording: no project, company, person, repo, URL, hostname or id.
- One rule per file. Lessons are amended, never replaced: the same rule appends your report to the
  existing file, a better rule supersedes the old one (`superseded_by`), and rules that hold only in
  some versions get `applies_to`. The table in [lessons/README.md](lessons/README.md) § When a lesson
  already exists says which. `/morph-share` searches the catalog first and drafts an amendment when
  it finds a match.

## How PRs are reviewed

A maintainer runs the `morph-review` skill (`.claude/skills/morph-review/`, maintainers only) on
each PR. It classifies every lesson as new, an amendment, a supersede, conditional or a conflict;
fixes wording and tags for portability; and posts a review. When your PR allows maintainer edits, it
may push those fixes to your branch. A maintainer decides the merge. The same skill sweeps the
catalog now and then to merge duplicates and mark outdated lessons superseded.

## Profiles

Improvements amend the existing profile. A different opinionated setup for the same stack is a
sibling profile (`profiles/<stack>-<variant>/`), not a rewrite.

A profile (`profiles/<name>/`) bundles suggested answers for a stack: check commands, risk areas,
permission rules and the lesson ids that fit. Copy `profiles/web-saas-nextjs-supabase/` as a
starting point. Profiles suggest; morph-init still asks every question.

## The kit itself

Changes to `template/` change what every new install starts with, so they need a reason from more
than one project. Open an issue first describing the problem it solved for you. Keep the process
roles and lifecycle intact: Technical Lead plans and delegates, Full-stack implements, QA validates,
the researcher answers questions read-only, legal-writer drafts legal wording, and the retro and prune loop changes the harness.

Installed harnesses only hear about a kit change through an **update note**: add one to
[updates/](updates/README.md) in the same PR, listing every `template/` file you changed and how to
apply the change to a copy that has morphed. For any change to `template/` or `skills/`, also
add a fragment file `changelog.d/<slug>.md` with your changelog entry (see
[changelog.d/](changelog.d/README.md)); don't edit [CHANGELOG.md](CHANGELOG.md), which is what made
parallel PRs conflict. Check both with
`scripts/check-updates.sh --since origin/main`.

Run `scripts/kit-selftest.sh` before opening the PR (the `selftest` check runs it too). It renders
`template/` for the sample projects in `tests/fixtures/` the way `/morph-init` would, then runs
render.md's self-checks, a link check, the template scripts and the guard hook cases in
`tests/guard-cases.jsonl` (a case that reads the project's config, such as branches or environments,
needs `"every": true` to replay on each copy; the others run once; `GUARD_FULL=1` replays all). A new placeholder needs a line in render.md § 3; a new
guard rule needs a case.

## Catalog entries

Skills and connectors suggested by morph-init live in `skills/morph-init/references/catalog.md`.
Add one you've used, with when to suggest it and why.

## Showcase

Using Morphness? Add your project to the **Built with Morphness** table in [README.md](README.md):
one row with:

- **Project:** its name, linked to its site or repo if you have a public one (optional).
- **What it is:** one line.
- **Stack:** its main stack.
- **By:** your GitHub user, linked to your profile.

```markdown
| [**Acme**](https://acme.example) | Invoicing for freelancers | Django, Postgres | [@your-user](https://github.com/your-user) |
```

An optional evidence summary goes in `showcase/<project>.md` (or `showcase/<alias>.md` for an
anonymous one), made with `/morph-share` from `bash scripts/evidence.sh`: counts and rates only, with
its "Read with care" list kept. Maintainers don't edit the figures; a summary that hides that it is
agent-recorded or leaves out the caveats is sent back. The row then ends with `([evidence](showcase/<file>.md))`.

Keep it factual; no taglines or badges. Listing is optional and you can ask to be removed
any time. Lessons you contribute stay anonymous whether or not you're listed.

## Releases

Releases are named by semantic version while Morphness is pre-1.0: `v0.13.0`. The tag, the GitHub
release and the `CHANGELOG.md` heading (`## v0.13.0 (2026-10-21)`) carry that name. The first sixteen
releases (`2026-10-12` to `2026-10-20.5`) were named by date and keep those tags; the version map at
the bottom of `CHANGELOG.md` says which version each one is. Installs don't carry a version: they
record the commit they last synced to, and `/morph-update` works out what changed from there.

**Bump rules.** The public surface is what [STABILITY.md](STABILITY.md) § Stable lists: the
`harness.config.yml` keys, the `_harness/` record formats, the update-note format, the skill names, the
agent roles and the script entry points.

- Patch (`v0.13.1`): only fixes (`kind: fix` notes), wording and script fixes.
- Minor (`v0.14.0`): everything else that reaches installs: a new module, skill or config key, a changed
  rule. Before 1.0 a minor may also change the public surface, and we still write the migration note.
- Major: from 1.0 on, a change to the public surface that needs manual migration.

`scripts/release-changelog.sh --suggest` proposes the next version from the unreleased notes; the
maintainer decides.

**1.0.** 1.0 is a promise of stability, not a feature list: [STABILITY.md](STABILITY.md) says what it
covers. It ships when all six of these hold. This list is the tracker.

Work in the kit:

1. **Surface frozen.** STABILITY.md lists every stable key, record form and entry point, and
   `harness.config.yml` carries `harness_schema: 1`, which `/morph-doctor` checks.
2. **Update tested.** The self-test renders an install at v0.13.0, the oldest supported release,
   updates it to the current kit and runs the doctor's checks and the self-test on the result.
3. **Guard gaps accounted for.** Every finding of the guard audit is fixed or listed in
   `tests/known-gaps.md`, which the trust page shows.

Then a release candidate: a 0.x release named as the candidate in its notes. Fixes to it are
patches. The last three need time and other people, and run against it:

4. **Outside installs.** Three projects not run by the maintainers, on at least two stacks, have
   each done 20 or more features, a retro and a prune, and a `/morph-update` across two releases,
   with no data lost because of the kit. A `/morph-share` summary (named or anonymous) is the proof.
5. **Plugin directory.** The plugin is listed, or the review declined it and the reason is written
   down here.
6. **No open safety bug.** The candidate has been out for 30 days, and on release day no known bug
   in the guard, secret handling or destructive-command rules is open. A safety fix shipped in that
   window doesn't restart the clock unless it changes the stable surface.

After 1.0, v0.13.0 and later get safety fixes for 60 days; dated releases get none
(STABILITY.md § Supported releases). Everything not on this list is 0.x work.

**The plugin build number.** `.claude-plugin/plugin.json` → `version` is not the release version. Claude
Code offers a plugin update only when that number rises as semver, and `0.13.0` is below the dated
`20261020.5.0`, so it stays the date as one number plus the release number of the day
(`20261021.1.0`, then `20261021.2.0`). `scripts/release-changelog.sh` sets it; `check-updates.sh`
checks that it carries the release date and is above every earlier one. (The first two releases used the
dotted date, `2026.10.13`; the new form sorts above it.)

**When to cut one**

- When `changelog.d/` has at least one change to `template/` or `skills/`, batched about weekly.
- The same day for a `kind: fix` update note (a kit instruction that was wrong or unsafe), or a
  skill bug that breaks an install or update.
- Lessons, profiles, catalog entries and docs alone don't need one:
  `/morph-update` reads lessons from `main`; they go into the next release's notes.

**How**

1. A PR runs `scripts/release-changelog.sh <vX.Y.Z>`, which builds `## <vX.Y.Z> (<date>)` in `CHANGELOG.md`
   from the `changelog.d/` fragments (and any text left under `## Unreleased`), deletes the fragments,
   sets each update note's `release` from `unreleased` to that name and bumps `plugin.json` → `version`
   to the plugin build number. `scripts/check-updates.sh` checks that the three agree.
2. After it merges, a maintainer creates the GitHub release with tag `<vX.Y.Z>` on the merge commit,
   using the changelog section as the release notes.

By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Security issues go through
[SECURITY.md](SECURITY.md), not public issues.
