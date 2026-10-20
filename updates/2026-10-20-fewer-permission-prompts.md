---
id: 2026-10-20-fewer-permission-prompts
title: Fewer permission prompts for routine work
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - harness.config.yml
  - .claude/settings.json
  - AGENTS.md
  - harness/CONTROLS.md
  - project/CONTROLS.md
removed: []
---

## What changed

- `scripts/guard.sh` knows which command a package starts: `npx firebase-tools@15.32.1 emulators:exec …` is a known dev tool and no longer asks "downloads a package that isn't installed" (the same for `netlify-cli`, `eas-cli`, `@angular/cli` and a few more), and `npx firebase-tools deploy` is still judged as `firebase deploy`.
- New `guard.pr_writes` switch (default `allow`): the GitHub connector's pull request tools (open, update, comment) skip the prompt when the call names this project's own repository. Merge, auto-merge, file writes and every other connector write still ask.
- `.claude/settings.json` sets `permissions.defaultMode: acceptEdits` (file edits inside the project don't prompt) and allows the git, `gh pr` and log commands agents run all day. The guard's asks and the deny rules still win.
- The log recipe in `harness/CONTROLS.md` and `project/CONTROLS.md` resets the `.exit` file with `echo running` instead of `rm -f`.
- `/morph-init` asks once (Q14) whether to auto-approve edits and the named check commands, and adds those commands to `allow`.

## Why

An owner approved the same prompts all day (a pinned `npx` tool, plan files, check runs) and stopped reading them, which hides the prompts that matter. Most came from Claude Code's default mode, one from the guard's package list.

## How to apply

1. Merge `scripts/guard.sh` and add `pr_writes: allow` to the `guard:` line of `harness.config.yml` (with its comment).
2. Ask the owner: "Auto-approve file edits inside the project, and the check commands?" On yes, merge the template's `permissions.defaultMode` and `allow` entries into `.claude/settings.json`, and add `Bash(<command>:*)` for each command in `project/CONTROLS.md` § Named checks (never a deploy, publish, remote database or push command, never `bash`, `sh` or `npx` alone). On no, change nothing there.
3. Update `AGENTS.md` § Permissions for this project and the two `CONTROLS.md` log recipes from the template.

## Skip if

The owner wants Claude Code's plain prompts for edits and commands (step 2 only).
