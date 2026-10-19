---
id: 2026-10-19-guard-deploys
title: Guard asks before deploys, publishes and schema pushes
kind: config
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - AGENTS.md
removed: []
---

## What changed

A red-team run found that deploy commands and schema pushes passed the guard hook untouched. It now
asks (the owner answers a permission prompt) before `vercel`, `wrangler deploy`, `fly deploy`,
`firebase deploy`, `netlify deploy`, `supabase functions deploy`, `prisma db push`,
`drizzle-kit push`, `terraform apply`, `kubectl apply`, `helm upgrade`, `npm publish` and
`cargo publish`, and before `gh api` writes to git refs and merges (`…/git/refs`, `…/merges`,
`…/pulls/N/merge`). Read-only commands such as `vercel ls`, `terraform plan` and `kubectl get` still
pass. AGENTS.md now says the guard stops accidents, not intent: it reads the command text, so a
script, an unlisted tool or a disguised call gets past it.

## Why

Agents are told never to change a shared environment by themselves, but nothing stopped a plain
`vercel --prod` or `gh api -X POST …/git/refs`. An ask keeps the owner in the loop at the moment it
matters.

## How to apply

Merge the `DEPLOY_ASK` and `PUBLISH_ASK` lists and the extra `GH_ASK_PATHS` entries into
`scripts/guard.sh`, and the "Permissions for this project" sentence in `AGENTS.md`. If the project
deploys through a CLI that isn't listed, add its own `ask` rule in `.claude/settings.json`.

## Skip if

The project's agents never run these tools and you keep the guard hook as it is.
