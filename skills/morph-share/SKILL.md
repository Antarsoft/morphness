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
terms from this project, and no URL or host, network command, command that installs or runs text,
env dump or mention of the guard, settings, harness config, permissions or secrets). Pass this
project's own names as `DENY`, a `|`-separated list of plain names (each matched as a whole word): the project name, the owner's name and GitHub login, the
repo name, every branch, environment and app name in `harness.config.yml` that isn't a generic word
(`main`, `dev`, `staging`, `production`, `web`, `api`), and every variable name in `.env.example` or
`project/STACK.md`. Then search the drafts for hostnames and email addresses:
`grep -nEo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|([A-Za-z0-9-]+\.)+(com|net|org|io|dev|app|co|ai|cloud|me|xyz|tech|site|shop|run|example|local|lan|corp|internal|test|uk|de|fr|eu|ca|us)\b|\b[0-9]{1,3}(\.[0-9]{1,3}){3}\b' <drafts>`.
Every hit must go, apart from a generic example such as `example.com` and code or file names it
catches (`config.test.ts`). When the check flags a Rule that really needs a command or a
mention of the guard, keep it only with `reviewed: <why it is safe>` in the frontmatter, and say so
to the user: the maintainers read those first.

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

(Evidence summaries are § 7; ask about both together so the owner answers once.)

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

## 7. Offer an evidence summary (optional)

Separately from lessons, ask once whether the user wants to share how the harness has worked here.
Needs `scripts/evidence.sh` in the project (`/morph-update` adds it); without it say so and stop.

1. **Ask the name first**, before any file or branch exists: publish under the project's name
   (linked from the showcase row), or anonymously. Name the branch, the file and the PR from that
   answer only. Named: `showcase/<project>` and `showcase/<project>.md`. Anonymous: a neutral random
   slug such as `showcase/anon-4f2k` for both; never invent a descriptive alias (a phrase like
   "ab-testing-saas" points back at the project), and keep the PR title and body free of what the
   project is or does.
2. Run `bash scripts/evidence.sh --out`. It reads only the project's run records and prints counts
   and rates (features finished, first-time QA pass rate, rework by prune window, escapes, estimated
   cost, retro items, rule audit results, trials, lessons adopted) with a "Read with care" list.
   When it stops with "Records read … the rest do not match a known entry format", do not pass
   `--force` to get past it: tell the user their entry format needs fixing first.
3. Show the user the **whole** file. Add nothing to it and take nothing out, except to remove a line
   the user doesn't want public. Say what it can't show: it's agent-recorded, escapes are
   under-counted, and there is no control run.
4. Grep it for the project's name, the owner's name, repo name, domain and any id from
   `project/STACK.md`; for an anonymous share there must be none.
5. Only on the user's yes, open it as its own PR, never in the lessons PR. With a showcase row
   (§ 6), the row's "What it is" cell ends with `([evidence](showcase/<file>.md))`. The `gh`-less
   fallback in § 5 applies. Fill the PR template's "Generated by" and "Shared as" lines and keep
   the evidence table empty; the body says nothing else about the project.

Nothing is sent without that yes; the file in `_harness/evidence/` stays local otherwise.
