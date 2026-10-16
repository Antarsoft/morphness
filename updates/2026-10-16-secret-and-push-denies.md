---
id: 2026-10-16-secret-and-push-denies
title: Wider deny rules for env files and pushes to environment branches
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/settings.json
  - harness/RELEASE.md
  - project/STACK.md
removed: []
---

## What changed

`.claude/settings.json` now also denies Read, Edit and Write of `.env.production`, `.env.prod`,
`.env.development`, `.env.dev`, `.env.staging`, `.env.stage` and `.env.test`, and denies
`cat`, `head`, `tail`, `less` and `more` of any `.env*` path. The `git push` denies now match an
environment branch on any remote and with trailing flags, and a `+` refspec counts as a force-push.
A bare `git push` and `git -C <dir> push` ask first. `harness/RELEASE.md` § Branch protection says
what the denies catch and what they don't; `project/STACK.md`'s env comment lists the covered names.

## Why

Only `.env`, `.env.local` and `.env.*.local` were denied, so an agent could read
`.env.production` or `cat .env`. The push denies only matched `origin <branch>`, so `git push
upstream main`, `git push origin main -u` (a trailing flag) and `git -C . push origin
main` slipped through. A deny always beats an allow, so `Read(.env*)` plus an allow for
`.env.example` can't work; the names are listed instead and `.env.example` stays readable.

## How to apply

1. Merge the template's `deny` and `ask` lists into the project's `.claude/settings.json` (union;
   keep every project rule). Replace the old `Bash(git push*origin <branch>)` lines with the four
   `git push` lines per environment branch, filled with the real branch names, for every branch in
   `harness.config.yml` → `environments` (a middle branch gets the same four).
2. Ask the owner whether the project keeps secrets under other names (`.env.qa`, `secrets.json`,
   a credentials file); add Read, Edit and Write denies for each.
3. Check the file parses: `jq . .claude/settings.json`.
