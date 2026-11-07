---
id: 2026-11-07-guard-expo-eas
title: The guard asks before Expo EAS builds, store submits and updates, and classic expo publish
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/GUARD.md
  - scripts/guard.sh
removed: []
reviewed: "It adds asks to scripts/guard.sh under the existing deploys switch: every eas command that is not a read, and classic expo publish, build and upload. It loosens nothing and adds no setting, permission or network call."
---

## What changed

- **`scripts/guard.sh`** asks before an `eas` command unless it only reads. That covers `eas build`, `eas submit`, `eas update` (and `update:republish`, `update:rollback`), `eas deploy`, `eas env:create`, `eas credentials`, `eas init`, `eas workflow:run`, `eas login` and `eas logout`, also through `npx eas-cli`, `pnpm exec`, and a bare `yarn eas`, `pnpm eas` or `bun eas`. Reads pass: `eas whoami`, `diagnostics`, `config`, any `<noun>:list`, `:view`, `:get` or `:info`, `build:download`, `build:run` and `metadata:pull`. `--include-sensitive` asks even on a read, since it prints secret values. `--help` before `--` passes, and `--version` passes only as the first argument, as the eas CLI reads it.
- It also asks before the classic `expo publish` (`publish:set`, `publish:rollback`), `expo build:ios|android` and `expo upload:ios|android`. `expo start`, `install`, `prebuild`, `export` and `publish:history` still pass.
- **`harness/GUARD.md`** names `eas` and `expo publish` in the deploy and cloud CLI line.

## Why

`eas` builds and submits with the owner's Expo login and store credentials, and the guard had no rule for it, so an agent on a machine where the owner is logged in could ship a build to the stores or an over-the-air update to users.

## How to apply

1. Copy `scripts/guard.sh` from the kit. Agents can't write it, so the owner copies it by hand (`/morph-update` prints the `cp`).
2. In `harness/GUARD.md`, take the kit's sentence about `eas` and `expo publish` in the deploy and cloud CLI line.

## Skip if

The project doesn't use Expo, or `guard.deploys` is `off`.
