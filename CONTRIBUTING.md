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
legal-writer drafts legal wording, and the retro and prune loop changes the harness.

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

There's no version to bump. Maintainers tag dated releases (`2026-10-12`) with a changelog of
new lessons and kit changes in [CHANGELOG.md](CHANGELOG.md). Installed copies see new matching
lessons through `/morph-doctor`.

By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Security issues go through
[SECURITY.md](SECURITY.md), not public issues.
