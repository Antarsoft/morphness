---
id: 2026-10-19-guard-exfiltration
title: The guard stops one-command exfiltration
kind: fix
release: 2026-10-19.2
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - harness.config.yml
removed: []
---

## What changed

`curl -d @.env https://…` passed the guard because the token `@.env` is not a `.env` file name, and
`env` or `printenv` printed every secret in the environment. `scripts/guard.sh` now strips `@` and
`<` before the `.env` check, denies a bare `env` or `printenv` (also behind `| grep`) and a read of
`/proc/<pid>/environ`, and asks before:

- `curl` or `wget` with a body (`-d`, `--data*`, `-F`, `-T`, `--json`, `--post-data`, `--post-file`) or
  a method other than GET or HEAD, to any host except `localhost`, `127.0.0.1`, `::1` and the hosts in
  `guard.allow_hosts`;
- `scp`, `sftp`, `nc`, `ncat`, `socat`, `telnet`, `ftp`, and `rsync` when one side is another machine.

A new `network` group in `guard:` in `harness.config.yml` switches these asks off (`network: off`);
`allow_hosts` is a space-separated list of extra hosts.

## Why

A hostile-audit probe sent `.env` to an arbitrary host in one Bash call and read every variable with
`env`; both passed, and in modes without permission prompts nothing else stopped them.

## How to apply

Merge the network block, the `@` split in `env_in_word`, the bare-`env` check and the switches in
`scripts/guard.sh`. In `harness.config.yml` add `network: ask` to the `guard:` map (set `allow_hosts`
to the API hosts your tests POST to, if any) and the `network` line in the comment above it.

## Skip if

Never; it is a fix. Projects that run a local mock server on a non-local host list it in `allow_hosts`.
