---
id: 2026-10-19-guard-bypass-asks
title: The guard asks or denies for script indirection, fetched code, deploy scripts, ssh and risky git and file writes
kind: fix
release: 2026-10-19.3
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - harness.config.yml
  - AGENTS.md
  - .claude/settings.json
removed: []
---

## What changed

A hostile list of bypass attempts showed commands that still ran freely after the earlier guard fixes. The guard now
covers these groups:

- **Commands it could not read** ask: a shell fed from a pipe, here-string or here-document (`echo … | sh`,
  `base64 -d | sh`, `sh <<< '…'`), a command name built at run time (`$g push`), an `alias`, `xargs` starting a shell, a
  Python, Node or Ruby one-liner that starts another process, and a file the same command wrote and then runs.
  `timeout`, `nice -n`, `stdbuf`, `ionice` and `sudo -u` no longer hide the command behind them, and `bash -lc '…'` is
  read like `bash -c`.
- **Fetched code** asks: `curl … | sh`, `wget … | bash` (also from an allowed host), `sh -c "$(curl …)"`, `source <(curl …)`.
  `npx`, `bunx`, `pnpm dlx` and `uvx` ask when the package is not installed in the project and not a common dev tool;
  `skills add` always asks. The new `guard.installs` switch turns the package-runner asks off.
- **Deploy-named scripts** ask: `make deploy`, `npm run deploy`, `pnpm deploy:prod`, `bash scripts/deploy.sh` (`deploys`
  switch; names with `publish` use `publishes`). `ssh` and `mosh` ask under `network`.
- **Git**: `git reset --hard` and `git clean -f` ask. A branch name in capitals (`git push origin Main`) is the same
  environment branch.
- **Secrets**: a variable set to a secret file name (`f=.env; cat $f`) is denied, and so is a recursive `grep -r` or
  `rg --hidden` over a folder that holds a secret file unless the command excludes it (`--exclude=.env*`).
- **File tools** ask when they write outside the project folder and `/tmp`, a CI definition (`.github/workflows/`,
  `.github/actions/`, `.gitlab-ci.yml`, `deploys` switch), `.git/hooks/` or `.git/config`.

`.claude/settings.json` adds `ask` rules for `git reset --hard`, `git clean -f` and a pipe into `sh` or `bash`, so the same
commands ask when the hook is not running. `AGENTS.md` § Permissions for this project is the single description and says
what the guard still does not see.

## Why

An ask or a deny on a pattern costs a prompt now and then; a command that runs freely costs a push to an environment
branch, a leaked secret or a deploy nobody approved.

## How to apply

Merge the changes in `scripts/guard.sh` (the `expand` function and its helpers, `check_pipes`, `check_fetched_package`,
`check_deploy_script`, `check_tree_search`, the `follow_git` additions and the Write/Edit branch of the dispatch), add
`installs: ask` to the `guard:` line in `harness.config.yml` and the comment lines above it, merge the `AGENTS.md`
§ Permissions text, and add the six `ask` entries to `.claude/settings.json`.

## Skip if

Never; it is a fix. `guard.installs: off`, `guard.deploys: off`, `guard.publishes: off` and `guard.network: off` turn the
related asks off.
