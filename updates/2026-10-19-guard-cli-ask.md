---
id: 2026-10-19-guard-cli-ask
title: The guard asks before any call to a deploy, cloud or database CLI unless it only reads
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - harness.config.yml
removed: []
---

## What changed

`scripts/guard.sh` used to ask only for the CLI commands on a list of known writes, so a write it did not list
(`aws s3 rb`, `kubectl delete`, `fly secrets set`, `gcloud run deploy`, `railway up`, `psql -c 'drop table ...'`)
went through. It now works the other way round: a call to a CLI in the deploy group (wrangler, netlify, fly,
railway, heroku, gcloud, gsutil, aws, az, doctl, kubectl, helm, pulumi, terraform, tofu, firebase, stripe,
render, sst, serverless, amplify) or the database group (psql, mysql, mongosh, redis-cli, sqlcmd, pscale, turso
...) asks, also behind `npx`, `bunx` and `pnpm exec`, unless:

- the only action is a read verb (`get`, `list`, `describe`, `status`, `logs`, `plan`, `whoami` ...);
- it is `--help`, `--version` or `--dry-run`;
- a database client targets a local host (or no host) or the statement only reads (`select`, `GET`, `ping`);
- a token prints a credential (`aws ... get-login-password`, `gh auth token`): that always asks.

Also new asks: `gh pr merge`, `gh release create|edit|delete|upload`, `gh workflow run|enable|disable`,
`gh repo delete|archive|rename|create|edit|transfer`, `gh auth token|login|logout`, `gh extension install`,
any `gh api` write and GraphQL mutations (secrets and variables still deny); `docker push`, `twine upload`,
`gem push`, `poetry publish`, `uv publish`, `mvn deploy`, `gradle publish` (publishes); `supabase` hosted
writes; `vercel env pull`; `prisma migrate reset`.

Not covered (listed in the audit as separate findings): commands hidden in a script file that is then run,
`npm install`, `git reset --hard`, `curl | sh`, `make deploy` / `npm run deploy`, `ssh`, a `timeout` wrapper.

## Why

A list of known writes is always one verb behind. Asking by default and passing only known reads fails safe.

## How to apply

Merge the `CLI_*` tables, `cli_asks`, `check_db`, `runner_words`, `check_cli`, the `GH_ASK` table and the new
`DEPLOY_ASK` entries in `scripts/guard.sh`, and the `check_cli` call in `check_bash`. Update the `guard:` comment
in `harness.config.yml`. Add the new cases to `tests/guard-cases.jsonl` if you keep a copy.

## Skip if

Never; it is a fix. `guard.deploys: off` and `guard.schema_pushes: off` turn the asks off.
