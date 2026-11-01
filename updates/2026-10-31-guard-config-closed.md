---
id: 2026-10-31-guard-config-closed
title: A missing or odd harness.config.yml no longer unprotects the environment branches
kind: fix
release: v0.15.0
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - scripts/lib/config.sh
  - .gitattributes
  - AGENTS.md
removed: []
---

## What changed

- `scripts/guard.sh` blocks every `git push` when it can't read the environment branches: `harness.config.yml` missing, empty or unreadable, `branches.integration` or `branches.production` not found, or a value that isn't a branch name (an alias such as `*main`, `null`, or an environment's `branch:` written with its value on the next line). A flow map split over two lines shows up as a branch key not found. Other calls still run, except `git branch -d|-D|-m|-f`, which is denied too while the branches can't be read. Without `awk` it blocks every call, like without `python3`; `grep`, `sort` and `tr` are no longer needed.
- `scripts/lib/config.sh` reads a file saved with a byte order mark or Windows line endings (CRLF), quoted keys (`"branches":`), an anchor before a value (`production: &p main`), and a one-line `environments: [ { … }, { … } ]` list. A new `config_get_all` prints every value of a repeated key; the guard protects all of them, and a `refs/heads/` prefix on a branch is dropped.
- A new `.gitattributes` keeps `*.sh`, `harness.config.yml` and `.claude/settings.json` on LF line endings in a Windows checkout.
- `AGENTS.md` § Permissions for this project lists the push block and `awk`.

## Why

The guard took the protected branches from the config and never checked it found any. A config the reader didn't understand, or a missing `awk`, `grep`, `sort` or `tr`, left the list empty, and `git push origin main` then passed with no message. A file saved on Windows was enough.

## How to apply

1. Take the kit's `scripts/lib/config.sh` (it has no project values), and merge `scripts/guard.sh`: the `awk` check and the `GUARD_CONFIG_READABLE` / `GUARD_INTEGRATION` / `GUARD_PRODUCTION` / `GUARD_ENV_BRANCHES` lines that replace `GUARD_BRANCHES`, `config_branches()` in the Python part, and the `CONFIG_PROBLEMS` deny at the top of the push check in `check_git`.
2. Copy `.gitattributes`, or append its three `eol=lf` lines to the project's own. On a Windows clone, run `git add --renormalize .` once and commit the result.
3. Run the push test from `/morph-doctor` (a push to the integration branch exits 2), then `bash -c '. scripts/lib/config.sh; config_get branches.production'`: it must print the production branch. If it prints nothing, fix `harness.config.yml`, because until then every push is blocked.
4. Bring the **Denies** list of `AGENTS.md` § Permissions for this project in line with the template (the push item and the guard-cannot-run item).

## Skip if

Never: it closes a gap in the guard.
