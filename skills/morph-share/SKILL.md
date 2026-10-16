---
name: morph-share
description: Turn rules that proved useful in this project's Morphness harness into community lessons and draft a pull request to the Morphness lessons catalog. Use when the user asks to share, contribute or upstream lessons, or after a prune when the audit shows rules that fired.
---

# morph-share

Contributing is optional and always the user's call. You draft; the user approves every lesson and
the PR.

## 0. Find the source

You need a clone of the Morphness repo (`SRC`) to compare against and to check the drafts: the
same one `/morph-update` uses (its § 1 step 2: a folder the user names, else `~/.cache/morphness`).
Never download it yourself; when there's none, give the user the clone command from that step and
wait. Ask before `git -C "$SRC" pull --ff-only`, so the duplicate check below sees the current catalog.

## 1. Find candidates

Read the latest prune records in `_harness/prunes/` and their rule audits. A candidate is a rule that:

- **fired** at least once (it caught a real problem in a feature), and
- is not already in the Morphness catalog in substance: check `SRC/lessons/` (including lessons
  with `in_template: true`, whose rule the kit already ships, and `status: superseded` ones, whose
  replacement may cover it) and the kit itself (`SRC/template/`, starting with
  `harness/PLAN_CHECKLIST.md` and the file the rule would land in), and
- would help a project that shares a stack, a service or a practice with this one.

Also offer rules the user names. Skip rules marked "too new" or "never fired" unless the user insists,
and say why: the catalog takes rules with evidence.

## 2. Amend or add

For each candidate, search the source's `lessons/` for the same rule in substance (same failure, same
fix). When one exists, draft an amendment to that file per `lessons/README.md` § When a lesson
already exists: append a `reports` entry, update the `evidence` totals, and propose wording only if
yours is clearer. When yours replaces an existing lesson, add a new file and set the old one to
`status: superseded` with `superseded_by`. Otherwise draft a new file.

## 3. Make each one portable

For each candidate, draft a lesson file in the format of `lessons/README.md` in the Morphness source:

- Rewrite the rule without this project's names, people, paths, URLs, hostnames, project ids,
  customer data or secrets. Use generic nouns ("the integration branch", "the payments webhook").
- Keep the failure it prevents in `## Why`, in one or two sentences.
- Pick the folder: `practice/` when it applies to any stack, `stack/<name>/` or `service/<name>/`
  otherwise. Tags list every stack, service and area it depends on.
- Evidence: how many features it fired on and over how many features in total, from the audits.

Show the user each draft in full with a short "what I removed" note. Drop any they reject.

## 4. Check

Run the source's `scripts/check-lessons.sh` on the drafts (frontmatter, unique id, no denylisted
terms from this project). Grep the drafts for this project's name, the owner's name, repo name,
domain and any id from `project/STACK.md`; there must be none.

## 5. Open the PR

Only on the user's yes:

1. Fork or clone the Morphness repo to a temp folder outside this repo (not the shared `SRC` clone).
2. Create a branch `lessons/<project-agnostic-topic>`, add the files, commit with a message listing
   the lesson ids.
3. Push to the user's fork and open a PR to Morphness `main` using its PR template, with the evidence
   table in the body.

Then tell the user the PR link and that maintainers may edit wording or tags before merging.

**Without `gh`** (not installed, or `gh auth status` fails) or when the push is refused: don't try
another route. Write the PR body and each lesson file to a folder in the session scratchpad, and give
the user a pre-filled issue link instead:
`https://github.com/antarsoft/morphness/issues/new?title=<url-encoded title>&body=<url-encoded body>`,
with the lesson files pasted in the body as fenced blocks (keep it under about 6,000 characters; past
that, link the folder and say to attach the files). Tell the user it opens a lesson proposal a
maintainer turns into a PR.

## 6. Offer a showcase listing (optional)

Lessons stay anonymous. Separately, ask once whether the user wants their project in the README's
**Built with Morphness** table. On a yes, prefill the row and show it for approval:

| Field | Source | Ask? |
|-------|--------|------|
| Project | `harness.config.yml` → `project.name` | Confirm |
| Link | none | Ask: a public site or repo URL, or none (optional) |
| What it is | `project.description`, cut to one line | Confirm or edit |
| Stack | `project/STACK.md`, the main two or three | Confirm or edit |
| By | none | Ask: the GitHub handle or name to show |

Open it as its own PR (branch `showcase/<project>`), never in the lessons PR, so the lessons can't be
traced back to the project. Row format and rules: `CONTRIBUTING.md` § Showcase.
