---
id: 2026-10-19-guard-git-bypass
title: The guard follows branch changes inside a command and asks before tag pushes
kind: fix
release: 2026-10-19.2
applies_to: { modules: [] }
files:
  - scripts/guard.sh
removed: []
---

## What changed

`scripts/guard.sh` read `git push` against the branch checked out when the hook ran, so a chain could
move HEAD first and then push. It now follows `git checkout`, `git switch`, `git symbolic-ref HEAD`
and `git config remote.<name>.push` (also `-c remote.<name>.push=…` and a value already in the
repository config) through the command, and judges a plain `git push`, `git push origin HEAD` or
`git push origin` against where the chain leaves HEAD. It also:

- denies `git push --prune` (it can delete remote branches) next to `--all` and `--mirror`;
- reads Gerrit refs (`HEAD:refs/for/main`, `refs/drafts/…`) as pushes to the branch they name;
- reads `$(git branch --show-current)`, `$(git rev-parse --abbrev-ref HEAD)` and their backtick forms as `HEAD`;
- asks when a push target is built at run time and cannot be read (`"$BR"`, `$(echo main)`);
- asks before any tag push (`git push origin v1`, `refs/tags/…`, `tag v1`, `--tags`, `--follow-tags`),
  because a tag can start a release or deploy on the host; `guard.publishes: off` turns this ask off;
- denies `git branch -d`, `-D`, `-f`, `-m` and `-M` (and the long forms) on an environment branch.

## Why

`git checkout main && git merge feature/x && git push`, `git symbolic-ref HEAD refs/heads/main && git push`
and `git push origin $(git branch --show-current)` all passed, and a pushed tag can trigger whatever the
host deploys on tags.

## How to apply

Merge the `SIM` state, `follow_git`, `is_tag`, the extended `check_git` and `branch_of`, and the
`HEAD_SUBST` line at the top of `check_bash` into `scripts/guard.sh`. Add the 37 new cases to
`tests/guard-cases.jsonl` if you keep a copy.

## Skip if

Never; it is a fix.
