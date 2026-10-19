# Agent instructions

Read this file first. The **harness is generic** (the kit in `harness/`, which this repo owns and may morph); **this repo's product and stack** live under `project/` and `docs/` when present. Structural settings (branches, modules, checks, effort defaults) are in [harness.config.yml](harness.config.yml).

**Project:** {{project.name}}. {{project.description}}

## Golden rules

- **Prefer files over memory.** If it is not documented, say so.
- **Match project conventions** in `project/PROJECT.md` and existing code before inventing patterns.
- **Harness for non-trivial work.** See [harness/MODES.md](harness/MODES.md).
- **Commit and push:** feature branches start from `origin/{{branches.integration}}`; WIP commits to the feature branch are allowed between handoffs; PRs into `{{branches.integration}}` (explicit base) open as drafts at the first push and are marked ready after QA pass; merges only when the human asks for that PR, unless `merge_by_agent` allows the integration branch; agents never merge into `{{branches.production}}` ([TECHNICAL_LEAD.md](harness/TECHNICAL_LEAD.md)). `{{branches.production}}` moves only through a release (`{{branches.integration}}` → `{{branches.production}}`) when the human says "release" ([harness/RELEASE.md](harness/RELEASE.md)). Direct pushes to `{{branches.production}}` or `{{branches.integration}}` and force-pushes are blocked by the guard hook (§ Permissions for this project) and denied in `.claude/settings.json`.
- **No remote yet** (`git remote` prints nothing): read every `origin/<branch>` in the harness as the local `<branch>`, skip fetches and pushes, and work without PRs (the Technical Lead merges on this computer on the human's ask, as with `pr_host: none`). Once the project is online, `/morph-doctor` finishes the code host setup.
- **Shared remote environments: no agent writes on its own.** No agent changes a shared remote environment or an external service by itself: no migrations, DDL or data changes on a remote database, no deploys, no edits to production or staging config, secrets or project settings. Agents write the change as files (migrations, config, infrastructure code) and test it on a local stack. Remote environments change through the project's own workflows, by the owner ({{human.name}}) by hand, or by the Technical Lead through a connected MCP, connector or plugin after the owner approves that exact action ([harness/SKILLS_AND_MCPS.md](harness/SKILLS_AND_MCPS.md) § Connector actions: every write asks first, nothing runs automatically; remote database migrations and data changes, secret values and billing never go through an agent); [project/RELEASE.md](project/RELEASE.md) says which. Read-only checks on remote (listing, advisors, read-only queries the human approves) are fine. Details, when the `data-access` module is enabled: [harness/modules/data-access/README.md](harness/modules/data-access/README.md). Enforced where possible by the guard hook (§ Permissions for this project) and `.claude/settings.json`; neither sees a script, so the host is the real guard.
- **Technical Lead never implements or QA's.** See [harness/TECHNICAL_LEAD.md](harness/TECHNICAL_LEAD.md). User words like "execute", "implement", or "develop" mean **delegate Full-stack**; after dev completes, **mandatory QA** before sign-off (outside light mode, which has none).

## Harness (how we work)

| Document | Purpose |
|----------|---------|
| [harness/README.md](harness/README.md) | Kit overview and adoption |
| [harness/SETUP.md](harness/SETUP.md) | Runbook and lifecycle |
| [harness/STRATEGY.md](harness/STRATEGY.md) | Roles and folder layout |
| [harness/HANDOFFS.md](harness/HANDOFFS.md) | Templates and ownership |
| [harness/CONTROLS.md](harness/CONTROLS.md) | Checks before handover (commands: [project/CONTROLS.md](project/CONTROLS.md)) |
| [harness/MODES.md](harness/MODES.md) | Full, small, light, bug and research modes |
| [harness/RELEASE.md](harness/RELEASE.md) | Release integration → production (project specifics: [project/RELEASE.md](project/RELEASE.md)) |
| [harness/MORPHING.md](harness/MORPHING.md) | How the harness changes itself (retros, prunes, where a lesson lands) |
| `harness/modules/` | Optional modules enabled in `harness.config.yml` → `modules` |

**Runtime feature folders:** `_harness/features/<slug>/<version>/`

Per feature, what the human has to do after QA pass is in the steps file (with the `roadmap` module: **`docs/versions/<id>/steps/<slug>.md`**; none when nothing needs them); **`QA/qa-result.md`** is the formal QA record.

**You are usually:** Technical Lead in the main chat. **Plan and delegate only**; never edit application code or `qa-result.md`. Delegate implementation, QA and research with the Agent tool per [harness/HANDOFFS.md](harness/HANDOFFS.md). Subagents, models and per-feature effort: [project/HARNESS_AGENTS.md](project/HARNESS_AGENTS.md). Hard rules: [harness/TECHNICAL_LEAD.md](harness/TECHNICAL_LEAD.md).

## Project (what we build)

| Document | Purpose |
|----------|---------|
| [project/PROJECT.md](project/PROJECT.md) | Architecture and layout |
| [project/STACK.md](project/STACK.md) | Commands and stack |
| [project/CONTROLS.md](project/CONTROLS.md) | Commands behind the named checks |
| [project/TESTING.md](project/TESTING.md) | Where tests live and stack-specific test rules |
| [project/SKILLS_AND_MCPS.md](project/SKILLS_AND_MCPS.md) | Repo-specific skills and MCPs |
| [project/PROCESS.md](project/PROCESS.md) | This project's process specifics: values, dates and the features behind kit rules |

Stack: {{stack.summary}}. Run [harness/CONTROLS.md](harness/CONTROLS.md) before handoffs.

## Tool setup (Claude Code)

| What | Where |
|------|-------|
| Entry point | [CLAUDE.md](CLAUDE.md) (imports this file) |
| Rules (always loaded) | `.claude/rules/*.md`: harness, testing. The Technical Lead's hard limits (`harness/TECHNICAL_LEAD.md`) are imported by `CLAUDE.md`, so only the main chat loads them; subagents set `omitClaudeMd: true` |
| Subagents | `.claude/agents/` (one file per effort level) → generic bodies in `harness/agents/`, project addenda in `project/agents/` |
| Settings | `.claude/settings.json` (startup hook, guard hook, permissions) |
| MCP | `.mcp.json` when the project has one; other MCPs come from your own connectors ([project/SKILLS_AND_MCPS.md](project/SKILLS_AND_MCPS.md)) |

### Permissions for this project

**The guard hook (`scripts/guard.sh`) is described here and nowhere else; other files link to this section.** It runs before every Bash call, file read and write, Grep, and MCP tool call, reads a Bash command the way the shell does (each command in a chain, inside `$(…)`, `bash -c`, `eval`, after `env`, `sudo` or `git -C <dir>`), and either lets the call through, shows the owner a permission prompt (**ask**) or stops it (**deny**, with the reason sent back to the agent). It has no switch for a deny.

**Denies:**
- a `git push` that would update an environment branch (`branches.*` and every `environments` entry): a named refspec, `HEAD` or a bare push while on one, `--all`, `--mirror`, `--prune`, a delete; also `git branch -d|-D|-m|-f` on one;
- a force-push on any branch;
- reading or writing a secret or credential file with any tool: `.env` and `.env.*` (`.env.example`, `.sample` and `.template` are fine), `.envrc`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore`, `*.ppk`, `*.tfstate`, `id_rsa` and its kin, `.netrc`, `.pgpass`, `.git-credentials`, `.my.cnf`, `.htpasswd`, `credentials.*`, `secrets.*` and similar names, and anything under `.aws`, `.ssh` (public keys excepted), `.gnupg`, `.azure`, `.kube`, `.config/gcloud`, `.config/gh`, `.config/doctl`; this is a catalogue of names, so a secret in a file with another name is not seen;
- a bare `env` or `printenv` and reading `/proc/<pid>/environ`;
- writing `.claude/settings.local.json` (the owner's file);
- `gh secret|variable set|delete`, and `gh api` writes to secrets or variables;
- remote database writes from these commands only: `supabase db push`, `supabase db reset` or `migration up|repair` with `--linked` or `--db-url`, `prisma migrate deploy|resolve`, `wrangler d1 … --remote`, `turso db shell`, and `pg:push`, `pg:reset` or `postgres connect` on heroku and fly;
- every call, when the guard cannot run: no `python3`, no `scripts/lib/config.sh`, input it cannot parse or a crash (it fails closed; `guard.fail_open: true` lets calls through when only `python3` is missing).

**Asks:**
- changing a file the guard rests on (`scripts/guard.sh`, `scripts/session-start.sh`, `scripts/lib/`, `.claude/settings.json`, `harness.config.yml`), shell startup files and schedules (`~/.bashrc`, `~/.profile`, `crontab`, systemd user units and the like), anything under `~/.claude`, and `.npmrc` or `.pypirc`;
- `rm -r` outside the repo, and a `git push` to a target built at run time or of a tag;
- a call to a deploy, cloud or database CLI: wrangler, netlify, fly, railway, heroku, gcloud, gsutil, aws, az, doctl, kubectl, helm, pulumi, terraform, tofu, firebase, stripe, render, sst, serverless and amplify (also behind `npx` and `pnpm exec`) unless a listed read verb (`get`, `list`, `describe`, `status`, `logs`, `plan` …) is the only action, or the call has `--dry-run` or `--help`; `vercel` unless it only reads (`ls`, `inspect`, `logs`, `env ls` …); `supabase` writes to the hosted project (`functions deploy|delete`, `secrets set|unset`, `projects`, `branches`, `config push`, `domains`, `storage cp|mv|rm`), not its local commands; any `psql`, `mysql`, `mongosh`, `redis-cli` and similar client aimed at a host that is not local, unless the statement only reads; `prisma db push`, `prisma migrate reset`, `drizzle-kit push`; a command that prints a credential (`gh auth token`, `aws … get-login-password`);
- publishes: `npm|pnpm|yarn|bun … publish`, `changeset publish`, `cargo publish`, `docker push`, `twine upload`, `gem push` and similar;
- the code host: `gh pr merge`, `gh release`, `gh workflow run`, `gh repo` changes, `gh auth`, `gh extension install`, and any `gh api` write or GraphQL mutation;
- `curl` or `wget` that sends a body or a non-GET request to a host outside `localhost` and `guard.allow_hosts`, and `scp`, `sftp`, `rsync`, `nc`, `socat`, `telnet` and `ftp` to another machine; a `curl` naming a Morphness address that is more than a plain read;
- any MCP tool whose name is not a read (`get`, `list`, `search`, `read` and the like).

**Switches** in `harness.config.yml` → `guard:` turn a group of asks off: `deploys` (cloud CLIs and the code-host commands), `publishes` (also tag pushes), `schema_pushes` (database clients, prisma and drizzle pushes), `network`, `mcp_writes`. Asks on the guard's own files, startup files and `~/.claude` have no switch.

**What it does not see:** commands inside a script that is then run (a `make deploy`, `npm run deploy` or shell script), code run by an interpreter (`python -c`, `node -e`), `curl … | sh`, `ssh`, `npm install`, `git reset --hard`, a CLI that is not listed, a `timeout` wrapper, a secret in a file whose name is not in the list, and any tool call other than Bash, file tools, Grep and MCP (WebFetch and Glob among them). It stops accidents, not intent. `.claude/settings.json` repeats the generic denies as a second layer, and the real guard is the host: branch protection and environment secrets that only the owner holds.

Add the project's own rules in `.claude/settings.json`: `deny` every tool or command that writes a remote database (database migrate/push commands, MCP tools that apply migrations or create, merge or reset database branches), and `ask` for every other connector tool that creates, changes or deletes anything (create a project, set a variable, deploy, edit a DNS record) and for remote tools that can both read and write (for example an MCP tool that runs SQL). List what you added in [project/SKILLS_AND_MCPS.md](project/SKILLS_AND_MCPS.md).

## Product docs (this repository only)

<!-- morph-init: fill with the product docs this repo has. With the roadmap module, keep the next paragraph; otherwise replace it with where scope is decided. Add a line for a design doc (tokens, theme, shared UI primitives) if the project has one. -->

**[docs/ROADMAP.md](docs/ROADMAP.md) is the source of truth for versions and scope**; each version has a document under `docs/versions/`. Other product and planning docs live under `docs/`. They describe **what** to build; the harness describes **how** to execute work.
