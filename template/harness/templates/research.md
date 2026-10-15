# Research: <title>

**Slug:** `<research-slug>`  
**Date:**  
**Asked by:** <the human who asked>  
**Researcher effort:** medium | high (one line why)  
**Status:** open | answered | planned (`<feature-slug>`) | no action

Process: `harness/MODES.md` § Research mode. The Technical Lead writes the sections down to the line; the researcher writes the sections below it; the Technical Lead closes the file.

## Question

The one question this research answers, as a decision the project faces ("Which queue library fits the worker, given X?", "Why does the import double-count rows?"). Several related questions get a numbered list.

## Scope

- **Look in:** the repository paths, docs, services or web topics to cover.
- **Out of scope:** what not to spend time on.
- **Done when:** what the answer must contain (a recommendation, a comparison of named options, a cause with its `file:line`).

## Context

Why it's asked and what it feeds (a plan, a choice of library, a bug fix), plus anything already known or ruled out.

---

## Answer

Three to five lines: the answer to the question and the recommendation, in plain words.

## Findings

One row per claim the answer rests on.

| # | Finding | Evidence | Confidence |
|---|---------|----------|------------|
| 1 | | `path/file.ext:line` at `<commit>`, or URL (read <YYYY-MM-DD>) | verified · inferred |

## Options compared

Only when the question asks for a choice. One row per option, the same columns for each (fit, cost, risk, effort to adopt, what it rules out).

## Recommendation

What to do next, and what it would take: no action, a light-mode change, or a feature (with a one-line scope the Technical Lead can plan from).

## Open questions

Anything the researcher could not settle from the sources, each with a suggested default.

## Sources

Every file, doc and page read, with the commit or the date read. Pages that disagreed with each other are listed together.

---

## Check

The Technical Lead re-opened the sources behind the findings the recommendation depends on: which rows (by #), and whether each held.

## Decision

The Technical Lead's call, with the date: `planned` (link the feature folder), `no action` (one line why), or another research round (link it). A decision that changes product behaviour, adds a step for the human or costs money is the human's: record their answer here.
