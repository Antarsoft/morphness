---
id: 2026-10-19-guard-secret-files
title: The guard and the deny list cover real secret files, not only .env
kind: fix
release: 2026-10-19.2
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - .claude/settings.json
removed: []
---

## What changed

The guard denied `.env*` files and nothing else, so `cat ~/.aws/credentials`, `cat ~/.ssh/id_rsa`,
`cat server.pem` and `cat secrets.json` all ran. `scripts/guard.sh` now treats these as secret files
for every tool (Read, Edit, Write, MultiEdit, NotebookEdit, Grep and every word of a Bash command):

- `.envrc`, `.netrc`, `.pgpass`, `.git-credentials`, `.my.cnf`, `.htpasswd`;
- `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore`, `*.ppk`, `*.tfstate`;
- `id_rsa`, `id_dsa`, `id_ecdsa`, `id_ed25519` (not their `.pub`);
- `credentials.json|yml|toml|…`, `secrets.json|yml|env|…`, `client_secret*.json`, `*.secrets`,
  `service-account*.json`;
- anything under `.aws`, `.ssh` (except `*.pub`), `.gnupg`, `.azure`, `.kube`, `.config/gcloud`,
  `.config/gh`, and `.docker/config.json`;
- a glob that could match an env file (`.en?`, `.env?`).

`.npmrc` and `.pypirc` ask instead of deny: they hold registry tokens but are often plain config.
`.env.example`, `.env.sample` and `.env.template` (and any `*.example`, `*.sample`, `*.template`) stay
readable. `.claude/settings.json` gets matching `Read` and `Edit` deny rules for the same files, so the
settings layer holds when the hook does not run.

## Why

A hostile-audit probe read cloud credentials, SSH keys, a certificate key and a secrets file in plain
Bash calls; all passed, while the docs said the guard "blocks secrets".

## How to apply

Merge the "secret and credential files" block and its three callers in `scripts/guard.sh`, and add
the new `Read(...)` and `Edit(...)` rules to `permissions.deny` in `.claude/settings.json`. If the
project keeps a secret-looking file the agent must read (a `credentials.json` test fixture), rename
it `credentials.example.json` or keep it out of the guarded names.

## Skip if

Never; it is a fix.
