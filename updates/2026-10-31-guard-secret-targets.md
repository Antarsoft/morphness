---
id: 2026-10-31-guard-secret-targets
title: The guard sees secrets through symlinks, in any letter case, and under more names
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - AGENTS.md
removed: []
---

## What changed

- A path that resolves to a secret file through a symlink is treated as that file: `notes.txt -> .env`, or a linked folder that points into `~/.ssh`, is denied to every tool, also through a glob (`cat note?.txt`) and after a `cd` or `pushd`. `ln` to a secret file or folder is denied, so a link made and read in one command is caught too.
- The guard's own files, `settings.local.json` and the CI definitions are matched without letter case, so `Scripts/guard.sh` or `.claude/Settings.local.json` (the same file on macOS and Windows) asks or is denied like the real name.
- New secret names: `*.tfvars` and `*.tfvars.json`, `.dev.vars` and `.dev.vars.<env>`, `kubeconfig` (and `*.kubeconfig`), `.dockercfg`, service-account keys with a prefix (`gcp-service-account-key.json`, `serviceAccountKey.json`; JSON only, so a Kubernetes `*-service-account.yaml` manifest passes), Firebase Admin keys (`*firebase-adminsdk*.json`), `.secrets`, `secrets.sops.yaml`, and everything under `supabase/.temp/` (it holds the linked database's address and password). `.example`, `.sample` and `.template` copies still pass.
- The Grep tool over a folder that holds a secret file asks, unless its `glob` (also a `!` negation) or a known `type` leaves that file out; Grep over a secret folder, or a link to one, is denied. A recursive `grep` was already denied there; with `-R` (and `rg -L`) the tree check now follows folder links as the search does. A tree too big to check (over 20,000 entries) asks instead of passing. A folder is judged by what is in it, so a `kubeconfig/` package folder is code, not a secret.
- `AGENTS.md` § Permissions for this project and the known limits name the new cases.

## Why

The guard matched secrets by the name as typed. A symlink, a different letter case on a case-insensitive disk, a credential file it had no name for, or a search with the Grep tool read files that `cat` was denied.

## How to apply

1. Merge `scripts/guard.sh`: the case-insensitive match in `protected_kind`, the new `SECRET_NAMES`, `SECRET_SUFFIX` and `SECRET_RE` entries, the `supabase/.temp` line in `file_secret_kind`, `link_kind` and the folder test and its call in `secret_kind`, `TOO_BIG` and the new `secret_in_tree` with the `follow` and `TOO_BIG` handling in `check_tree_search`, the `pushd` and `ln` checks at the top of `check_bash`, the `glob as globmod` import, and `GREP_TYPE_EXT`, `grep_glob_names` and `check_grep_tree` with their call in the Grep branch.
2. Update `AGENTS.md` § Permissions for this project (the secret-file deny item and the Grep item under **Asks**); other items there are worded shorter with no rule change, which is optional.

## Skip if

Never: it closes a gap in the guard.
