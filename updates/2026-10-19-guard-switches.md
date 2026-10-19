---
id: 2026-10-19-guard-switches
title: Guard asks cover platform secrets and workspace publishes, and can be switched off
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - harness.config.yml
  - CLAUDE.md
  - AGENTS.md
removed: []
---

## What changed

The deploy asks missed the commands that write platform secrets and some publish forms. The guard now
also asks before `vercel env add|rm|update` (vercel asks for everything except a list of read-only
subcommands, such as `vercel ls`, `vercel env ls` and `vercel domains ls`), `wrangler secret
put|delete|bulk`, `netlify env:set|unset|import`, `pnpm --filter x publish`, `npm --workspace x
publish`, `yarn … publish` and `changeset publish`. A command with `--dry-run` (or `--help`) passes.

`harness.config.yml` gets three switches next to `mcp_writes`: `guard: { mcp_writes: ask, deploys: ask,
publishes: ask, schema_pushes: ask }`. `off` skips that group's prompt. A hook ask beats an allow rule in
`.claude/settings.json`, so before this a local `prisma db push` or `drizzle-kit push` always
prompted, with no way around it. Secrets, force-pushes, `.env` files, environment-branch pushes and
remote database writes have no switch.

CLAUDE.md, AGENTS.md and the config comment now point at `scripts/guard.sh` for the full list instead
of repeating it.

## Why

A secret written to Vercel, Cloudflare or Netlify is as much a shared-environment change as a deploy,
and `gh secret set` was already blocked. An ask that can't be turned off for a local stack trains
owners to approve without reading.

## How to apply

Copy `scripts/guard.sh` from the kit, replace the `guard:` line and its comment in `harness.config.yml`
with the new block, and update the "Settings" line in `CLAUDE.md` and the "Permissions for this
project" sentence in `AGENTS.md`. If the project's local database tooling needs `prisma db push`, set
`schema_pushes: off`.

## Skip if

The project's agents never run these tools and you keep the guard hook as it is.
