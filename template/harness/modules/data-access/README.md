# Module: data-access (database and access-control validation)

Optional. Enable it in `harness.config.yml` → `modules` when the project has a database whose schema changes through migrations, or row-level access rules (policies, grants, tenancy filters) that a bug can break silently.

When a feature's `plan.md` marks **Data-access feature: yes**, QA validates the database in **two stages**. No agent changes a shared remote environment (`AGENTS.md`), so migrations reach the integration environment between the two stages without them: a workflow applies them after the feature PR merges into the integration branch (`branches.integration` in `harness.config.yml`), or, where there is no such workflow, the owner applies them. Which one, and the commands: [project/RELEASE.md](../../../project/RELEASE.md) § Production migrations.

| Stage | When | Where | Who | Tools |
|-------|------|-------|-----|-------|
| **A. Local validation** | Normal QA pass, before the merge | Local stack ([project/STACK.md](../../../project/STACK.md) § Local stack (QA)) | QA engineer | The database shell against the local stack, the app, tests |
| **Apply to integration** | After stage A passes and the owner merges the feature PR | Integration environment's database | The migrations workflow, or the owner (never an agent) | The workflow named in `project/RELEASE.md` |
| **B. Post-apply check** | After the apply has passed for the merge (or the owner says it is applied) | Integration environment's database, read-only | QA engineer | Read-only listing tools, migration history, security advisors, `SELECT`-only queries the owner approves each time |

The feature is **done** only when stage B passes.

## When this applies

Mark **yes** in `plan.md` § QA scope when the feature includes any of:

- New or changed schema (table definitions, generated migrations)
- New or changed migration files of any track (schema, policies, grants, functions)
- New or changed access-control rules (row-level policies, role grants, tenancy filters enforced in the database)
- Tenancy tables (accounts, users, organisations, projects) or account bootstrap behaviour

Mark **no** for UI-only, docs-only or harness-only changes with no database impact.

## Stage A: local validation (required for QA pass)

Start the local stack, or reset it for a clean rebuild ([project/STACK.md](../../../project/STACK.md) § Local stack (QA)), with explicitly local settings: pass the local settings module, env file or connection on the command line (for example `--settings=<project>.settings.local`, `RAILS_ENV=test`, `-x db=local`) rather than relying on the session's defaults, and record the target the command printed. That applies every migration in the branch on an empty database, as a fresh integration apply would. Record each row in `QA/qa-result.md` § **Data-access validation**.

| # | Check | How | Pass criteria |
|---|-------|-----|---------------|
| A1 | **Migrations apply cleanly** | Stack reset exit code and log | Every migration of every track applies in order on an empty database. |
| A2 | **Schema present** | Describe each in-scope table in the database shell | Tables, columns and foreign keys from the plan exist. |
| A3 | **Access control enabled** | The engine's catalogue query (example below) | Row-level security (or the project's equivalent) is on for every in-scope table. |
| A4 | **Policies exist** | The engine's policy catalogue (example below) | The policy names from the migration files exist on the in-scope tables. |
| A5 | **Isolation works** | As the plan specifies: two seeded accounts in the app, or switching role and identity claims in the database shell | An account can't read or change another account's rows. Local data is disposable, so write tests are fine here. |
| A6 | **App works on the new schema** | QA build and start of the app against the stack, the plan's flows | The ACs that touch the database pass. |

If the stack can't start, stage A rows are `deferred: local` with the command, exit code and error as the reason, and the verdict can't be **pass** for a Data-access feature until they run.

## Stage B: post-apply check on the integration environment (read-only)

Run it after the owner confirms the migrations listed in `progress.md` are applied, as a short follow-up QA pass. Record it in `qa-result.md` § **Data-access validation: post-apply**. Target only the integration environment's project or database id named in [project/SKILLS_AND_MCPS.md](../../../project/SKILLS_AND_MCPS.md).

| # | Check | Tool | Pass criteria |
|---|-------|------|---------------|
| B1 | **Schema matches local** | A read-only table listing | Same tables and columns as A2. |
| B2 | **Access control and policies match** | `SELECT`-only catalogue queries (the owner approves each call) | Same flags and policy names as A3 and A4. |
| B3 | **Migration history** | The migration history listing | The feature's migration versions are listed. Note any drift from the repo's file names. |
| B4 | **Security advisors** | The platform's security advisor, if it has one | No **new critical** issue on in-scope tables. Document existing warnings. |

If the read-only tool isn't available or can't authenticate, stage B is **not run**. Say so; the feature stays not done until it runs. Never substitute a code review for it.

### Read-only SQL (example: Postgres)

Row-level security flags:

```sql
SELECT c.relname AS table_name, c.relrowsecurity AS rls_enabled
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND c.relname IN ('accounts', 'projects')
ORDER BY c.relname;
```

Policies (adjust the table list):

```sql
SELECT schemaname, tablename, policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('accounts', 'projects')
ORDER BY tablename, policyname;
```

On any remote database: `SELECT` only. Tools that apply migrations are denied in `.claude/settings.json`; DDL or DML through a query tool is forbidden even if approved by mistake.

**Example (hosted Postgres platform such as Supabase):** stage A uses the platform's local CLI stack; stage B uses its MCP's `list_tables`, `list_migrations`, `get_advisors` (`type: "security"`) and `execute_sql` with `SELECT` only, always passing the integration project's ref because the connector is account-wide. `apply_migration`, `create_branch` and similar tools are `deny`.

## Never write remote

- No agent applies migrations, DDL or data changes to a remote database, and no agent dispatches the production migrations workflow.
- No test users, seed data or admin keys on a remote database. Any script QA runs checks its connection target first and exits unless it points at the local stack (a session shell can carry remote values that a local env file doesn't override).
- A mismatch in stage B means the remote apply differs from what was tested. Report it; don't fix the remote.

### When one command targets local and remote

Some stacks have a separate command for remote writes (a platform CLI's `db push`, a deploy command), and a `deny` rule on that command is enough. Many don't: Django's `manage.py migrate`, Rails' `bin/rails db:migrate`, Alembic's `alembic upgrade head`, Flyway, Liquibase and Prisma's `migrate deploy` run the same command against whatever database the settings, environment or URL point at. A deny rule matches command text, so it can't tell a local run from a remote one, and denying the command would also block stage A. For these stacks:

1. **Remote credentials and settings never reach agent sessions.** No remote database URL, password or production settings module in the repo's env files, the session's environment, the cloud environment's secrets or the agent's shell profile. The remote apply runs in the migrations workflow (or on the owner's machine), which is the only place that holds them. This is the real guard; the rules below only catch mistakes.
2. **`ask` rules for the command with remote settings.** Add `ask` (a pattern also catches harmless runs, such as a dry run or a migration listing, so the owner judges each) for each way the command can be pointed at a remote target in this project, for example:
   - `Bash(*manage.py migrate*--settings=*production*)`, `Bash(DJANGO_SETTINGS_MODULE=*production* *)`
   - `Bash(RAILS_ENV=production *)`, `Bash(*db:migrate*RAILS_ENV=production*)`
   - `Bash(DATABASE_URL=* *)` (an inline URL is never the local default)
   - `Bash(alembic*-x *prod*)`, `Bash(ALEMBIC_ENV=prod* *)` (whatever the project's `env.py` reads)
   Name the project's real settings modules, environment names and flags; the patterns above are examples, not a complete list.
3. **QA stage A uses explicitly local settings** (above), so the evidence shows which database a run touched. A run whose printed target is not the local stack is invalid; stop and report it.
4. **Scripts check the target first.** Any script QA or Full-stack runs against the database reads the connection it will use and exits unless it is the local stack (§ Never write remote).

## Verdict rules

- **QA pass (stage A):** A1 to A6 done with evidence, the named checks green, ACs mapped.
- **QA fail:** a migration fails on a fresh database; tables, access control or policies missing; isolation broken; or database-touching ACs fail.
- **Done (stage B):** B1 to B4 match stage A.

## Technical Lead

- Set **Data-access feature: yes | no** in every `plan.md` § QA scope.
- When **yes**: QA effort is `high` ([project/HARNESS_AGENTS.md](../../../project/HARNESS_AGENTS.md) § Effort per feature), and the QA prompt says "Follow `harness/modules/data-access/README.md` stage A; fill `qa-result.md` § Data-access validation."
- In the steps file, list the migrations from `progress.md` in order under an **Apply to integration** item (the workflow to run, or the owner's commands).
- Once they are applied, run a stage B QA pass and report the result.

## On install

- Fill [project/STACK.md](../../../project/STACK.md) § Database and § Local stack (QA), and [project/RELEASE.md](../../../project/RELEASE.md) § Production migrations and § Break-glass.
- Add to `.claude/settings.json`: `deny` every command that only writes a remote database (a platform CLI's push or remote migrate) and every MCP tool that applies migrations or creates, merges or resets remote branches; `ask` for MCP tools that run arbitrary SQL. When the same migrate command targets local or remote by settings (§ When one command targets local and remote), keep remote credentials out of agent sessions and add the `ask` rules for its remote settings instead of a `deny`. List them in `project/SKILLS_AND_MCPS.md` § Permission rules added for this project.
- Add the database paths (schema, migrations) to [project/CONTROLS.md](../../../project/CONTROLS.md) § Cross-cutting paths and to its § Risk paths database row, and "Database" to `harness.config.yml` → `risk_areas`.
- Keep the `qa-result.md` template's **Data-access feature (from plan)** line and its sections **Data-access validation** and **Data-access validation: post-apply**, and the plan template's **Data-access feature** line (the templates ship with them).
- Fill `project/agents/qa-engineer.md` § Remote read-only checks and § Guard against remote writes.

## On remove

When the project doesn't choose this module, morph-init deletes this folder and the items below. The rule that no agent writes a shared remote environment (`AGENTS.md`, the agent bodies), the local stack, **Needs live app/services**, and the steps file's migrations block are core and stay. Sentences that start "With the `data-access` module" (in `harness/agents/qa-engineer.md`, `harness/CONTROLS.md`, `.claude/rules/testing.md`, the PR template and the steps template) and the plan template's `n/a (data-access module off)` choice stay as they are.

**Delete these files:** none outside this folder.

**Delete the marked text:** every span and line marked `module:data-access`, with the command in [harness/README.md](../../README.md) § Modules → **Module markers**.

**Delete or reword these lines** (unmarked: always-loaded, config or code-block text):

- None: its clause in `.claude/rules/data.md` is marked and goes with **Delete the marked text**.

**Unlink:** every Markdown link left pointing into `harness/modules/data-access/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/data-access' --include='*.md' . | grep -v '^./harness/modules/'`.
