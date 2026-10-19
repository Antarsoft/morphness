---
id: 2026-10-19-updates-without-clone
title: Upstream checks read GitHub directly, no clone needed
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
  - .claude/settings.json
  - harness/MORPHING.md
  - harness/SETUP.md
removed: []
---

## What changed

`/morph-update`, `/morph-doctor` and the prune's upstream check now read the newest release, its
update notes, lessons and template text from github.com/antarsoft/morphness with plain read-only
requests, instead of asking for a clone first. Nothing fetched is executed or saved as code, and no
account is needed. When GitHub can't be reached they fall back to the local clone as before. A new
key `updates.source` (`github` by default, or `local`) picks the source, and two `WebFetch` and two
`curl` allow rules in `.claude/settings.json` let those reads run without a permission prompt.

## Why

Every update check started with "clone Morphness to `~/.cache/morphness` first", so most copies
were never checked at all, and a prune with the owner away could only list against a stale clone.

## How to apply

Add the `updates: { source: github }` block with its comment above `installed_from` in
`harness.config.yml` (`local` if this project should keep using a clone, for example on a machine
without internet). Add the four allow rules to `.claude/settings.json` → `permissions.allow`; if
`installed_from.repo` names a fork, use the fork's `<owner>/<repo>` in the two `curl` rules. Merge
the "Where from" line in `harness/MORPHING.md` § Health check and upstream updates and the
"not checked" wording in `harness/SETUP.md` § Prune.

## Skip if

The project has no internet access and keeps a clone: set `updates.source: local` and skip the allow
rules.
