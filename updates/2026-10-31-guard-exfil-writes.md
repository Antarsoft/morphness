---
id: 2026-10-31-guard-exfil-writes
title: The guard blocks env piped to the network, and checks migration tools, gists, more MCP verbs and WebFetch
kind: fix
release: v0.15.0
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - .claude/settings.json
  - AGENTS.md
removed: []
---

## What changed

- A command that prints the whole environment is denied: `env` or `printenv` with nothing to run (also `env -0`, `env 2>&1`, `env > file`, and behind `sudo`, `command`, `nohup`, `timeout` or `xargs`), `export -p`, `declare -x`, `typeset -x`, a bare `set`, `compgen -v|-e`, `jq` reading `env` or `$ENV`, and `ps e…`. So `env | curl -X POST --data-binary @- …` or `curl -d "$(env)" …` are blocked. Before, the guard stopped at the `curl` prompt, and one yes sent every variable.
- While a Bash command is checked, an ask is held until the whole command has been read, so a deny anywhere in it wins: `curl -d x https://h; git push --force` is denied instead of asking once for both.
- Database migration tools: `atlas`, `sqitch`, `flyway`, `goose`, `dbmate` and `liquibase` subcommands that change the database (`migrate apply`, `deploy`, `migrate`, `up`, `update` and the like) are denied when the target is not local, and ask when the target isn't on the command line (a config file) or is a usual container service name (`db`, `postgres`); `guard.schema_pushes: off` turns those prompts off. The target is read from URLs (the host after the last `@`), `jdbc:` and sqitch `db:` URIs, `host=` and `tcp(host)` DSNs, `-h`/`--db-host`, and a `DATABASE_URL=…` prefix; sqlite, file and docker URLs and `--dev-url` count as local. Reads (`info`, `status`, `diff`, `update-sql`) and `atlas … --dry-run` still run; `goose up -h` and `sqitch deploy -h <host>` don't count as help.
- `gh gist create|new|edit|delete|rename` asks.
- MCP tools: `destroy`, `purge`, `terminate`, `scale`, `flush`, `overwrite`, `wipe`, `evict`, `clone`, `teardown`, `restart`, `reboot`, `provision`, `deprovision` and `detach` count as write verbs for connector tools, so `get_and_destroy_resource` asks (CLI calls are not affected).
- `WebFetch` goes through the guard (the hook matcher in `.claude/settings.json` gains `WebFetch`). On `api.github.com` and `raw.githubusercontent.com`, which `settings.json` allows without a prompt for the update checks, a URL outside the two Morphness paths asks, also when it is spelled with a backslash, a missing slash, a trailing dot or a user name. Other domains keep Claude Code's own prompt.
- `AGENTS.md` § Permissions for this project and the known limits list the new rules.

## Why

The audit's exfiltration and remote-write probes passed these: an `env` piped to `curl` was only an ask, the migration tools and `gh gist create` weren't known, a tool name pairing a read verb with `destroy` passed, and `WebFetch` never reached the guard.

## How to apply

1. Merge `scripts/guard.sh`: `HELD_ASK` and the held ask in `ask()` and in the Bash dispatch; the tool input object check; `ENV_LISTERS` and the environment checks in `expand()`; the early `BARE_ENV` deny in `check_bash` and the `CMD_ASSIGNED_URLS` line above it; `gist` in `GH_ASK`; `MCP_WRITE_EXTRA` and its use in the MCP branch; `local_socket`; `MIGRATE_WRITES`, `SERVICE_HOSTS`, `MIGRATE_LOCAL_SCHEMES`, `db_targets` and `check_migrate` with its call after `check_cli`; and the `WebFetch` branch in the dispatch.
2. In `.claude/settings.json` → `hooks.PreToolUse`, add `WebFetch` to the guard entry's `matcher`.
3. Update `AGENTS.md` § Permissions for this project; the items reworded shorter with no rule change are optional.

## Skip if

Never: it closes a gap in the guard.
