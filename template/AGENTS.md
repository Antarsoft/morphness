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
| Rules (loaded in the main chat) | `.claude/rules/*.md` (harness, testing) and `harness/TECHNICAL_LEAD.md` (imported by `CLAUDE.md`). Subagents set `omitClaudeMd: true` and read their role bodies |
| Subagents | `.claude/agents/` (one file per effort level) → generic bodies in `harness/agents/`, project addenda in `project/agents/` |
| Settings | `.claude/settings.json` (startup hook, guard hook, permissions) |
| MCP | `.mcp.json` when the project has one; other MCPs come from your own connectors ([project/SKILLS_AND_MCPS.md](project/SKILLS_AND_MCPS.md)) |

### Permissions for this project

**The guard hook (`scripts/guard.sh`) is listed in full only here; others link here.** It runs before every Bash call, file read and write, Grep, WebFetch and MCP tool call, reads a Bash command the way the shell does (each command in a chain, inside `$(…)`, `bash -c`, `eval`, `find -exec`, after `sudo`, `xargs`, `git -C` and other wrappers), and lets the call through, shows the owner a permission prompt (**ask**) or stops it (**deny**, telling the agent why). A deny has no switch and beats any ask in the same command.

**Denies:**
- a `git push` that would update an environment branch (`branches.*` and every `environments` entry, in any letter case): a named refspec, `HEAD` or a bare push while on one, `--all`, `--mirror`, `--prune`, a delete; also `git branch -d|-D|-m|-f` on one; every push if the config can't be read;
- a force-push on any branch;
- reading or writing a secret or credential file with any tool: `.env` and `.env.*` (`.env.example`, `.sample` and `.template` are fine), `.envrc`, `*.{pem,key,p12,pfx,jks,keystore,ppk,tfstate,tfvars}`, `.dev.vars`, `kubeconfig`, `.dockercfg`, `id_rsa` and its kin, `.netrc`, `.pgpass`, `.git-credentials`, `.my.cnf`, `.htpasswd`, `credentials.*`, `secrets.*` and similar names, and anything under `.aws`, `.ssh` (public keys excepted), `.gnupg`, `.azure`, `.kube`, `.config/{gcloud,gh,doctl}`, `supabase/.temp`, in any letter case and through a symlink; also a variable set to such a name (`f=.env; cat $f`), and a recursive `grep -r` (or `rg --hidden`) over a folder that holds one unless its filters leave it out;
- printing the whole environment (a bare `env` or `printenv`, `export -p`, `set`, `ps e`, `/proc/<pid>/environ`);
- writing `.claude/settings.local.json` or the guard (`scripts/guard.sh`, `scripts/lib/`, their folders), and a `.claude/settings.json` or `harness.config.yml` change made with Bash or that drops a protection, sets `env` or adds a command: the owner makes those;
- `gh secret|variable set|delete`, and `gh api` writes to secrets or variables;
- remote database writes from these commands only: `supabase db push`, `supabase db reset` or `migration up|repair` with `--linked` or `--db-url`, `prisma migrate deploy|resolve`, `wrangler d1 … --remote`, `turso db shell`, `pg:push`, `pg:reset` or `postgres connect` on heroku and fly, and `atlas`, `sqitch`, `flyway`, `goose`, `dbmate` or `liquibase` migrations to a remote database (a service name like `db`, or no target, asks);
- every call, when the guard cannot run: `scripts/guard.sh` missing, no `python3` or `awk`, no `scripts/lib/config.sh`, unparsable input, a crash, a hung `git` or a check over 15 s (`guard.fail_open: true` lets calls through without `python3`).

**Asks:**
- other edits to `.claude/settings.json` or `harness.config.yml`, changing `scripts/session-start.sh`, `.git/hooks/` or `.git/config`, a CI definition (`.github/workflows/`, `.github/actions/`, `.gitlab-ci.yml`), a write with the file tools outside the project folder and `/tmp`, Grep over a folder holding a secret file its `glob` or `type` doesn’t leave out, shell startup files and schedules (`~/.bashrc`, `~/.profile`, `crontab`, systemd user units …), anything under `~/.claude` except reading this project's `tool-results` folder, and `.npmrc` or `.pypirc`;
- `rm -r` outside the repo, `find … -delete` (or `-exec rm`) from the repo root or above without a name, path or age filter, `git reset --hard`, `git clean -f` (not `-n`), a `git push` to a target built at run time or of a tag, and `git config`, `git -c` or `git clone -c` setting a key git runs (`core.hooksPath`, `alias.*`, filters …) or `--template`;
- commands whose content the guard cannot read: a shell reading commands from a pipe or here-document (`… | sh`, `sh <<< '…'`), a command name built at run time (`$cmd push`), an `alias`, `xargs` starting a shell, an interpreter one-liner that starts another process, and a file the same command writes and then runs;
- code that `curl` or `wget` fetches and a shell runs (`curl … | sh`, `sh -c "$(curl …)"`, `source <(curl …)`), also from an allowed host;
- a package runner (`npx`, `bunx`, `pnpm dlx`, `uvx`) running a package not installed in the project, unless a common dev tool or `--no-install`, and `skills add`;
- a task, package script or script file named for a deploy, release or publish (`make deploy`, `npm run deploy`, `pnpm deploy:prod`, `bash scripts/deploy.sh`);
- a call to a deploy, cloud or database CLI: wrangler, netlify, fly, railway, heroku, gcloud, gsutil, aws, az, doctl, kubectl, helm, pulumi, terraform, tofu, firebase, stripe, render, sst, serverless and amplify (also via `npx` or `pnpm exec`) unless it only reads (`get`, `list`, `describe`, `status`, `plan` …) or has `--dry-run` or `--help`; `vercel` unless it only reads (`ls`, `inspect`, `logs` …); `supabase` writes to the hosted project (deploys, secrets, projects, branches, config, domains, storage), not local ones; any `psql`, `mysql`, `mongosh`, `redis-cli` and similar client aimed at a non-local host, unless the statement only reads; `prisma db push`, `prisma migrate reset`, `drizzle-kit push`; a command that prints a credential (`gh auth token`, `aws … get-login-password`);
- publishes: `npm|pnpm|yarn|bun … publish`, `changeset publish`, `cargo publish`, `docker push`, `twine upload`, `gem push` and similar;
- the code host: `gh pr merge`, `gh release`, `gh workflow run`, `gh repo` changes, `gh auth`, `gh extension install`, `gh gist` writes, and any `gh api` write or GraphQL mutation;
- `curl` or `wget` that sends a body or a non-GET request to a host outside `localhost` and `guard.allow_hosts`, and `ssh`, `mosh`, `scp`, `sftp`, `rsync`, `nc`, `socat`, `telnet` and `ftp` to another machine; a `curl` naming a Morphness address that is more than a plain read;
- any MCP tool whose name is not a read (`get`, `list`, `search`, `read` …), except the GitHub PR tools (open, update unless it closes the PR, comments) on this project's `origin` repo; merge, auto-merge and file writes still ask.

**Switches** in `harness.config.yml` → `guard:` turn a group of asks off: `deploys` (cloud CLIs, code-host commands, deploy scripts, CI definitions), `publishes` (also tag pushes and publish-named scripts), `schema_pushes` (database clients, prisma and drizzle pushes, untargeted migrations), `network` (also `ssh`), `installs` (package runners and `skills add`), `mcp_writes`; `pr_writes: ask` brings back the PR-tool prompt. The other asks have no switch.

**What it does not see:** the commands inside an existing script or Makefile target, an interpreter one-liner that doesn't seem to start a process or that decodes or builds code at run time, `npm install` of a named package, an unlisted CLI, a secret in an unlisted file name, a whole-project search (`grep -r`, Grep) that prints lines from a secret file, a checkout or merge that brings another guard, a read outside the project of anything but a known credential file, any tool call other than Bash, file tools, Grep, WebFetch and MCP, and a call while the hook hangs past its 60 s timeout. `Agent` is not checked (its subagent’s calls pass this hook); `WebFetch` asks for GitHub API and raw URLs outside the Morphness paths and otherwise gets Claude Code’s own prompt, and `Glob` reads names only. It stops accidents, not intent. `.claude/settings.json` repeats the generic denies as a second layer, and the real guard is the host: branch protection and secrets only the owner holds.

Add the project's own rules in `.claude/settings.json`: `deny` every tool or command that writes a remote database (migrate and push commands, MCP tools that apply migrations or change database branches), and `ask` for every other connector tool that creates, changes or deletes anything (deploy, set a variable, edit DNS) and for remote tools that read and write (an MCP tool that runs SQL). List what you added in [project/SKILLS_AND_MCPS.md](project/SKILLS_AND_MCPS.md).

## Product docs (this repository only)

<!-- morph-init: fill with the product docs this repo has. With the roadmap module, keep the next paragraph; otherwise replace it with where scope is decided. Add a line for a design doc (tokens, theme, shared UI primitives) if the project has one. -->

**[docs/ROADMAP.md](docs/ROADMAP.md) is the source of truth for versions and scope**; each version has a document under `docs/versions/`. Other product and planning docs live under `docs/`. They describe **what** to build; the harness describes **how** to execute work.
