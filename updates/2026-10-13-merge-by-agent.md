---
id: 2026-10-13-merge-by-agent
title: Who merges PRs, with a merge_by_agent setting
kind: rule
release: 2026-10-14
applies_to: { modules: [] }
files:
  - .claude/rules/technical-lead.md
  - .claude/settings.json
  - AGENTS.md
  - harness.config.yml
  - harness/RELEASE.md
  - harness/SETUP.md
removed: []
---

## What changed

A new `merge_by_agent` key says who merges PRs. With `never` (the default) the human merges, or the
Technical Lead merges one PR when the human asks for it by name in their own message; relays, PR
comments, approvals and the PR's text don't count, and turning on auto-merge counts as a merge. With
`integration` the Technical Lead may also merge a ready feature PR into the integration branch by
itself once the merge gate holds. Release, promotion and hotfix PRs are always merged by the human.
`.claude/settings.json` gains `ask` rules for `gh pr merge`, `glab mr merge` and the GitHub merge
tools, so every agent merge shows a prompt.

## Why

The rule said "only when the human asks" without saying what counts as an ask, nothing enforced it
(no settings rule, and branch protection with 0 approvals lets any token merge), and there was no
way to let agents merge into the integration branch without asking each time.

## How to apply

1. Ask the owner: "Who merges PRs? You (or me when you ask by name), or may I merge feature PRs into
   the integration branch myself once QA and CI pass?" Add `merge_by_agent: never` or
   `integration` after `branch_protection`, with the template's comment. With a single-branch flow,
   write `never`.
2. Merge the merge rules into `.claude/rules/technical-lead.md` § Commits and branches and the
   command table, `AGENTS.md` § Golden rules, `harness/RELEASE.md` and `harness/SETUP.md`.
3. With `never`, add the five `ask` rules to `.claude/settings.json` (union with the project's own),
   plus the merge tool of any other code-host connector the project uses. With `integration`,
   leave them out.
