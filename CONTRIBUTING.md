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

Keep it factual; no taglines or badges. Listing is optional and you can ask to be removed
any time. Lessons you contribute stay anonymous whether or not you're listed.

## Releases

Releases are named by date. The release name, its tag and its `CHANGELOG.md` heading are the date
(`2026-10-14`); a later release the same day adds its number (`2026-10-14.2`, `2026-10-14.3`).
`.claude-plugin/plugin.json` → `version` is the date as one number, then the release number of the
day: `20261014.1.0`, then `20261014.2.0`. Claude Code compares that version as semver and only offers
a plugin update when it goes up, so every release bumps it; a suffix like `2026.10.14-2` would read as
a pre-release and sort *below* `2026.10.14`. (The first two releases, `2026-10-12` and `2026-10-13`,
used the dotted date, `2026.10.13`; the new form sorts above it.) Installs don't carry a version: they record the commit they last synced to, and
`/morph-update` works out what changed from there.

**When to cut one**

- When `changelog.d/` has at least one change to `template/` or `skills/`, batched about weekly.
- The same day for a `kind: fix` update note (a kit instruction that was wrong or unsafe), or a
  skill bug that breaks an install or update.
- Lessons, profiles, catalog entries and docs alone don't need one:
  `/morph-update` reads lessons from `main`; they go into the next release's notes.

**How**

1. A PR runs `scripts/release-changelog.sh <release>`, which builds `## <release>` in `CHANGELOG.md` from
   the `changelog.d/` fragments (and any text left under `## Unreleased`), deletes the fragments and sets
   each update note's `release` from `unreleased` to that name. The PR also bumps `plugin.json` →
   `version`. `scripts/check-updates.sh` checks that the three agree.
2. After it merges, a maintainer creates the GitHub release with tag `<release>` on the merge commit,
   using the changelog section as the release notes.

By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Security issues go through
[SECURITY.md](SECURITY.md), not public issues.
