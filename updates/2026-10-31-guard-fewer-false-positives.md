---
id: 2026-10-31-guard-fewer-false-positives
title: Fewer false alarms from the guard on local databases and project-wide searches
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - AGENTS.md
removed: []
---

## What changed

- A database client whose host is a folder (`psql -h /tmp/pgsock`, `--host=/var/run/postgresql`, a URL with `%2Ftmp%2Fpgsock` as its host) talks to a Unix socket on this machine, so it counts as local and runs without a prompt. Every entry of a host list counts (`-h /tmp,db.example.com` still asks), and so does a `host=` or `hostaddr=` in a URL query.
- A recursive `grep -r` or `rg --hidden` over a folder that holds a secret file now reads its filters the way each tool does: `--include`, `--exclude` and `--exclude-dir` for grep (on the base name; the last match wins; with none matching, a file is searched unless the first filter is `--include`), rg's `-g`, `--iglob` and `--glob-case-insensitive` (with `!` for a leave-out; the last match wins; a glob with `/` matches the path rg prints). Matching is case-sensitive, as in both tools, braces are expanded for rg only, and words after `--` are not filters. It is denied only when a secret file is still searched, and the message names the filters to add after the others (`--exclude=".env*" --exclude="id_rsa"`, `--exclude-dir=".aws"`, rg `-g "!.env*"`). Before, any exclude naming `env` let the search through even when the folder also held a key file, and `--include='*.ts'` was denied. More than 200 secret files in the tree asks, as a tree too big to check does.
- An option value given as the next word (`rg -g '*' KEY`, `grep -rn -A 2 KEY`, `-e KEY`, `rg --color never KEY`) is no longer read as the search pattern, which used to hide the folder searched by default; when no path on the command line exists, the guard also checks `.`.
- `scripts/guard.sh` hands its Python checks to `python3` by having it read them from the end of the file (a `GUARD_PY` block), not as one `-c` argument: with these checks the text passed Linux's 128 KB limit for one argument, and every call would have been blocked.
- `AGENTS.md` § Permissions for this project says the filters count.

## Why

Agents lost turns on these: a QA check against a throwaway Postgres on a socket folder was taken for a remote host, and a project-wide search was blocked with a hint that didn't fit the file it found.

## How to apply

1. Merge `scripts/guard.sh`: `local_socket`, `db_url_hosts` and their use in `hosts_in` and `db_targets`; `secrets_in_tree` (which replaces `secret_in_tree`), `search_filters`, `glob_regex`, `search_reads`, `glob_escape`, `exclude_hint`, `SEARCH_VALUE_OPTS` and the new `check_tree_search`; then the loader: the `GUARD_SELF` line after `GUARD_LIB_DIR`, the short `python3 -I -c` line that reads the `GUARD_PY` block, and the move of the Python text into that block after `exit` (a project that edited the guard keeps its edits inside the block).
2. Update the secret-file item in the **Denies** list of `AGENTS.md` § Permissions for this project.

## Skip if

Never: it fixes the guard's own checks.
