# Community lessons

Rules that caught real problems in someone's project, written so another project can adopt them.
`/morph-init` and `/morph-update` offer the ones whose tags match your project; you pick which to
merge. `/morph-share` drafts new ones from your own prune audits.

## Layout

| Folder | For |
|--------|-----|
| `practice/` | Any stack: planning, contracts, QA, release, process. |
| `stack/<name>/` | A language, framework or tool (`nextjs`, `django`, `playwright`). |
| `service/<name>/` | A hosted service or vendor API (`supabase`, `stripe`, `paddle`). |

Pick the narrowest folder that holds every dependency of the rule. A rule about Supabase RLS
tested with Playwright goes under `service/supabase/` with `stack: [playwright]` in its tags.

## File format

One lesson per file, named `<id>.md`.

```markdown
---
id: same-turn-status            # kebab-case, unique across lessons/
title: Set the status the next agent reads in the same turn as the decision
kind: checklist-item            # checklist-item | rule | testing-rule | module-rule | agent-rule
target: harness/PLAN_CHECKLIST.md   # where it lands in an installed harness
in_template: true               # optional: seed lesson whose rule already ships in template/
tags: { stack: [], service: [], area: [process] }
evidence: { fired: 2, features: 40, source: "prune audits" }   # totals across reports
added: 2026-10-12
# optional:
reports:                        # one entry per project that reported it; amendments append here
  - { fired: 2, features: 40, source: "prune audits", added: 2026-10-12 }
applies_to: { nextjs: ">=15" }  # versions or conditions where the rule holds
status: active                  # active | superseded
superseded_by: <other-id>       # with status: superseded
reviewed: "<why it is safe>"    # when the lesson has a URL or host, a network command, a command that
                                # installs or runs text, an env dump, or names the guard, settings, the
                                # harness config, permissions or secrets (scripts/check-lessons.sh flags
                                # those for a maintainer; a changed lesson needs a new reason)
---

## Rule

The text to paste into the target file. Neutral nouns, no project names.

## Why

The failure it prevents, in one or two sentences.

## How to check

The grep or step that verifies it, if there is one.
```

`target` paths are relative to an installed harness: `harness/PLAN_CHECKLIST.md`,
`harness/TECHNICAL_LEAD.md`, `.claude/rules/testing.md`, `project/TESTING.md`,
`harness/modules/<name>/README.md`, `harness/agents/<role>.md`.

## Matching

A lesson is offered when every tag list it sets overlaps the project: its `stack` with the stack
summary and detected tools, its `service` with the services, and its `area` with the project's
risk areas or modules (`area` alone never excludes a `practice/` lesson). Lessons whose rule is
already present in substance are not offered.
Lessons with `in_template: true` are seed lessons already shipped in the kit: `/morph-init` and
`/morph-update` never offer them; they exist so other projects' reports can attach evidence to them.

## When a lesson already exists

Lessons are amended, never replaced.

| Situation | Do |
|-----------|----|
| A different rule for the same stack or service | New file in the same folder. |
| The same rule, in substance, as an existing lesson | Amend that file: append your entry to `reports`, update the `evidence` totals, sharpen the wording if yours is clearer. No new file. |
| A rule that holds only in some versions or setups | Add `applies_to` to each lesson so both can stay. |
| A rule that replaces an existing one | Keep the old file, set `status: superseded` and `superseded_by: <new-id>`. `/morph-update` tells projects that adopted the old one. |
| A contradiction with no clear winner | Open the PR anyway and say so; the maintainer decides on the evidence. |

Superseded lessons are never offered to new installs.

## Listing a lesson

`/morph-init` and `/morph-update` show each offered lesson with its evidence and its age, computed
from the file, not stored in it:

- **Reports:** the number of `reports` entries (1 when the field is absent). It counts projects
  that sent evidence, not installs or votes.
- **Age:** `added`, and the latest `reports` date when it differs, as `added 2026-10-12, last
  report 2026-10-20`.
- **Evidence:** `fired` of `features`, as in the file.

Example: `3 reports · added 2026-10-12, last report 2026-10-20 · caught a problem in 2 of 153 features`.

These are context for reading a rule, not a ranking. A new lesson with one report can be right and
an old one with many can be stale, so the listing never sorts or filters on them, and nothing in the
wording calls a lesson popular or recommended.

## Evidence

`fired` is how many features the rule caught a real problem on, from a prune's rule audit;
`features` is how many features ran while it existed. `fired: unknown` is allowed for seed lessons
whose audits didn't count. The catalog prefers rules with evidence; see CONTRIBUTING.md.
