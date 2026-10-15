---
id: 2026-10-15-plain-protection-steps
title: Step-by-step ways to switch branch protection on yourself
kind: rule
release: 2026-10-15
applies_to: { modules: [] }
files:
  - harness/RELEASE.md
removed: []
---

## What changed

`harness/RELEASE.md` § Branch protection has a new § Applying it yourself: numbered steps for
switching the protection on from the GitHub website (download the rules file, import it under
Settings → Rules → Rulesets) or from a terminal (open the project folder, or clone it first, switch
to the branch with the file, run the command). It starts by saying that private repositories on
GitHub's free plan can't use these rules at all. `/morph-init` and `/morph-doctor` now hand the owner
these steps with the real names filled in, instead of a bare `gh api` command.

## Why

When the apply failed, the owner got a single `gh api ... --input .github/rulesets/...` command. It
only works from inside the project folder on the right branch, which nothing said, so an owner who
isn't a developer got lost. The failure in that case was a private repo on a free plan, where no
command would have worked.

## How to apply

1. Merge § Applying it yourself into this copy's `harness/RELEASE.md` § Branch protection, and the
   two sentences that now point to it (the "On the host" bullet and "Who changes these settings").
2. On GitLab, or with `branch_protection.enabled: false`, skip the section (GitLab: write the
   protected-branch steps there instead).
3. If `project/RELEASE.md` § Manual steps has a bare ruleset command from the install, replace it
   with a row pointing to § Applying it yourself.

## Skip if

The ruleset is already applied (`/morph-doctor` reads it back) and the project isn't on GitLab.
