---
id: 2026-10-16-slim-tl-rule
title: A shorter Technical Lead rule, with the detail in the files that own it
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/rules/technical-lead.md
  - harness/RELEASE.md
  - harness/HANDOFFS.md
  - harness/SETUP.md
  - harness/CONTROLS.md
  - harness/MORPHING.md
  - harness/modules/claude-projects/README.md
  - .github/pull_request_template.md
removed: []
---

## What changed

`.claude/rules/technical-lead.md` went from about 19.4 KB to about 11 KB. It keeps every hard
rule as a short line and links the file that owns the how. The process itself is unchanged:
the detail moved, nothing was dropped.

- The PR states (draft, ready, back to draft) and the full `merge_by_agent` rules moved to the new
  `harness/RELEASE.md` § Feature PRs. The rule keeps "merge only on the human's own message naming
  the PR" and "nothing reaches production from an agent's merge".
- The thread rules moved to the new `harness/HANDOFFS.md` § Threads, and the signs-of-life check
  detail to the new `harness/HANDOFFS.md` § Background agents. The rule keeps a short summary of each.
- The merge gate and merge order were already in `harness/CONTROLS.md`; the rule now links there.
  CONTROLS § Merge gate gains the one sentence it was missing (hand to QA naming § After merging the
  integration branch).
- The steps-file and hand-off-message detail moved to `harness/SETUP.md` § After QA pass and the new
  § Retrospective → **Hand-off message** bullet (connector work in § Done for you, why no connector
  did a step, the `deferred: local` warning, remote config changes, asking when the roadmap has no
  single next version, the cost and prune counter lines, light mode's cost line).
- The effort, code review, legal and research bullets now point at `SETUP.md`, the legal module and
  `MODES.md`, which already held the same text.
- `harness/MORPHING.md` § Where a lesson lands says a TL hard limit is one line, with the how in the
  owner file.

## Why

`scripts/prune-counter.sh` prints `Prune is DUE` once the TL rule passes 20 KB. The rule shipped at
19.4 KB, so the first two or three retro rules on a fresh install would make the prune due on every
hand-off, and a prune couldn't clear it without deleting shipped rules. The rule also loads into
every session, so its size is paid on every turn, and the duplicated copies (merge order, merge
gate, thread rules) could drift apart. About 9 KB of headroom is now left for the project's own rules.

## How to apply

1. Add `harness/RELEASE.md` § Feature PRs, `harness/HANDOFFS.md` § Background agents and § Threads,
   the `harness/SETUP.md` additions and the `harness/CONTROLS.md` sentence as in the kit. Keep any
   project edits made to the same text in the TL rule: carry them into the new sections.
2. Replace the TL rule's long bullets with the kit's short ones, one by one. A bullet the project
   added through a retro stays, unless it repeats an owner file, in which case it moves there with a
   link left behind. Keep `(learned: …)` notes and rule provenance with the text they explain.
3. Fix links that pointed at `.claude/rules/technical-lead.md` § Commits and branches (the PR
   template comment, `harness/SETUP.md` § After QA pass step 5, `harness/RELEASE.md` § Branches) to
   `harness/RELEASE.md` § Feature PRs, and links to § One feature per thread that need the full rules
   to `harness/HANDOFFS.md` § Threads. A `project/PROCESS.md` line that names "technical-lead.md § Must
   do (signs of life)" still holds: the interval stays in the rule.
4. Run `wc -c .claude/rules/technical-lead.md` and tell the owner the new size.

## Skip if

The project's TL rule is already well under 20 KB and the owner prefers the long form in one file.
