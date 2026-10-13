---
id: 2026-10-13-pr-template
title: PR template for drafts, release notes and hotfixes
kind: template
release: 2026-10-13.2
applies_to: { modules: [] }
files:
  - .github/pull_request_template.md
  - .claude/rules/technical-lead.md
  - AGENTS.md
  - harness/CONTROLS.md
  - harness/RELEASE.md
  - harness/modules/ci-cd/README.md
  - harness/modules/ci-cd/github/tag.yml
  - harness/modules/browser-e2e/README.md
removed: []
---

## What changed

The PR template now says which sections are filled when the draft opens (Summary, Harness, Changes)
and which wait until the PR is marked ready (Verification, Needs the owner, Risk), so a draft never
shows a QA box ticked. It gains a **Merge after** line for the merge-order check, a **Release notes**
section for release and hotfix PRs, and a **Hotfix** section (QA record, tag, merge-back PR). The
`ci-cd` tag workflow publishes only the Release notes section as the release notes, falling back to
the host's generated notes when it's empty. On GitLab, morph-init writes the template as
`.gitlab/merge_request_templates/Default.md`.

## Why

The tag workflow published the whole release PR body, checklists and HTML comments included, as
public release notes. The template had no hotfix or promotion guidance, and after the draft-PR
change its QA boxes could show ticked on a draft.

## How to apply

1. Merge the template's changes into the project's PR template (`.github/pull_request_template.md`,
   or the GitLab merge request template): the header comment, the draft/ready notes, **Merge
   after**, **Release notes**, the Release comment and **Hotfix**. Keep the project's own sections
   and wording; a project that brought its own template gets these as additions only on a yes.
2. With the tag workflow (`ci_cd.tags`): replace the `jq -r '.body ...' > notes.md` line with the
   new extraction block. If the project changed the template's heading, match its `awk` pattern to
   the heading the project uses.
3. Merge the one-line changes in `AGENTS.md` § Golden rules (the commit-and-push line still said PRs
   open only after QA pass), `harness/RELEASE.md`, `harness/CONTROLS.md` § Before the feature
   PR, `.claude/rules/technical-lead.md` and the ci-cd README.

## Skip if

Skip step 2 when the project has no tag workflow; skip everything when `pr_host` is `none`.
