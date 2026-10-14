# Profile: web SaaS on Next.js + Supabase

An example overlay for `/morph-init`: the answers, check commands, permission rules, skills and lessons that worked for a pnpm monorepo with a Next.js (App Router) app, Supabase Postgres and Auth, Drizzle ORM and Playwright end-to-end tests. It is derived from **Twinpage**, the A/B testing SaaS where Morphness was built and run for about 150 features, so every lesson it bundles caught a real problem there.

A profile is a set of **suggestions**. It never overrides what the project already has: morph-init detects the stack, offers this profile when it matches, shows every suggested value, and writes only what the user confirms. Nothing here is copied into `template/`; the kit stays stack-agnostic.

Machine-readable values: [profile.yml](./profile.yml). This file explains them.

## When morph-init offers it

`profile.yml` → `detect`: a `package.json` (the root's or any workspace package's) that depends on `next`, plus any of `pnpm-workspace.yaml`, `supabase/config.toml`, a `@supabase/` package, `drizzle-orm` or `@playwright/test`. A project with only some of these still gets the profile offered; morph-init drops the parts that don't apply (no Drizzle lessons without Drizzle, no Paddle lessons without Paddle).

## What it fills

| Target in the installed repo | From this profile |
|------------------------------|-------------------|
| `harness.config.yml` → `modules` | `roadmap`, `data-access` (local Supabase stack, then read-only checks of DEV), `browser-e2e`, `legal` |
| `harness.config.yml` → `checks` | `before_qa`: install, typecheck, lint, unit, build, e2e-targeted. `before_signoff`: adds `integration` and `e2e-full` |
| `harness.config.yml` → `risk_areas` | auth, billing, migrations, RLS and tenancy, the public API, code that runs on customer sites |
| `harness.config.yml` → `ci_gate` | `false` (QA's recorded local run is the gate). Set `true` when CI runs on every PR |
| `project/STACK.md` | `stack.summary`, `stack.package_manager`, `stack.toolchain_setup`, `stack.install_cmd` |
| `project/CONTROLS.md` | the commands below and the cross-cutting paths |
| `.claude/settings.json` | the allow, deny and ask rules below |
| `project/SKILLS_AND_MCPS.md` | the skills and MCPs below, with reasons |
| `project/PLAN_CHECKLIST.md`, `project/TESTING.md`, module READMEs | the stack and service lessons listed in `profile.yml` → `lessons` (each lesson file names its own `target`) |

## Named checks

The kit names checks; `project/CONTROLS.md` maps them to commands. For a monorepo whose root `package.json` has Twinpage-style scripts:

| Check | Command | Notes |
|-------|---------|-------|
| `install` | `pnpm install` | when dependencies changed |
| `typecheck` | `pnpm typecheck` | `next typegen && tsc --noEmit` in the app, so a fresh clone typechecks without a build |
| `lint` | `pnpm lint` | |
| `unit` | `pnpm test` | Vitest in each package |
| `build` | `pnpm build` | builds workspace packages before the app |
| `e2e-targeted` | `pnpm qa:stack && pnpm qa:build && pnpm test:e2e <specs>` | the plan's targeted specs plus smoke, a11y and every spec the diff touches |
| `e2e-full` | `pnpm e2e` | the whole suite; QA runs it once on the final commit (about 16 minutes on Twinpage, so run it in the background with a one-hour limit) |
| `integration` (extra) | `pnpm test:integration` | API role grants, RLS on every public table, billing; against the local stack |
| `e2e-repeat` (extra) | `pnpm test:e2e <spec> -g "<test>" --repeat-each=5` | each new fake-clock, hover or focus-timing test |

Before QA, Full-stack narrows `unit` and `lint` to the changed packages and their dependents with `pnpm --filter '...[origin/dev]' <script>`; `typecheck` and `build` stay full. A cross-cutting path runs everything in full, and QA's sign-off run is always full (`profile.yml` → `check_scope`).

The `qa:*` scripts start a disposable local Supabase stack in Docker (Postgres, Auth, REST, Mailpit), apply Drizzle migrations then the Supabase RLS migrations, seed fixed QA data, and build the app against it. If your repo has no such scripts, morph-init writes "not configured" for the e2e checks and adds a backlog item to create them; the `data-access` module explains the stage A (local) and stage B (remote, read-only) split they support.

## Cross-cutting paths

A change to any of these gets the full e2e suite from Full-stack and a full QA round: shared `packages/`, the schema and migrations (`db/`, `drizzle/`, `supabase/`), the request proxy or middleware, `next.config.ts`, the root layout, the auth route groups and callbacks, `app/api/`, `lib/` files about auth, session or env, the Playwright fixtures, support folder and config, the root and app `package.json`, and `pnpm-lock.yaml`. `profile.yml` lists them with Twinpage's `apps/web/` prefix; morph-init rewrites the prefix to your app folder.

## Risk areas

These never run at `medium` effort and get the pre-QA code review when the plan picks `xhigh`:

- **Auth:** sessions, OAuth callbacks, admin checks, anything that trusts an email (Confirm email must be on).
- **Billing:** webhooks (signature verification), charges to stored payment details, customer matching.
- **Migrations and RLS:** default privileges, grants per relation kind, tenant isolation tested with a second account.
- **Public API:** key auth, wrappers' error paths and headers, rate limits.
- **Code on customer sites:** bundle size budgets, cross-origin message trust, CSP and Trusted Types.

## Permission rules for remote Supabase

Agents never write to a shared Supabase project (DEV or production). Migrations reach DEV through a workflow after a merge to the integration branch and production through a workflow only the owner runs. The profile merges these into `.claude/settings.json`:

- **deny** (both MCP prefixes, `mcp__Supabase__` and `mcp__supabase__`, since the connector's name varies): `apply_migration`, `create_branch`, `delete_branch`, `merge_branch`, `rebase_branch`, `reset_branch`, `create_project`, `pause_project`, `restore_project`, `deploy_edge_function`.
- **deny** (Bash): `pnpm db:migrate*`, `pnpm db:push*`, `*supabase db push*`, `*supabase link*`, `*drizzle-kit push*`. These match command text, so a `grep` containing the phrase is refused too; agents search with the Grep tool.
- **ask:** `execute_sql` (read-only SQL the human approves).
- **allow:** the fast checks (`pnpm typecheck`, `test`, `lint`, `build`, `install`).

The Supabase connector is account-wide: `project/SKILLS_AND_MCPS.md` records the DEV project ref and every call passes it. morph-init asks for the ref; it never guesses one.

## Skills and MCPs

| Skill or MCP | Why |
|--------------|-----|
| `supabase` skill (`supabase/agent-skills`) | auth, RLS, migrations, CLI and debugging; read before any Supabase change |
| `supabase-postgres-best-practices` skill | schema design, RLS policies and their tests, indexes, slow queries |
| `nextjs-app-router-patterns` skill | App Router, streaming, server components and actions |
| `vercel-react-best-practices` skill | React and Next.js performance rules |
| `drizzle-orm-patterns` skill | schema and query patterns (there is no official Drizzle skill) |
| `shadcn` skill | when the dashboard uses shadcn/ui |
| `playwright-cli` skill | drive the browser, write and debug specs |
| `web-design-guidelines` skill | UI reviews |
| `find-skills` skill | discover more skills later |
| Context7 MCP (project `.mcp.json`) | version-specific docs: `/vercel/next.js`, `/drizzle-team/drizzle-orm`, `/supabase/supabase-js`, `/supabase/ssr`; also the fallback when a vendor site is blocked by the session proxy |
| Supabase MCP (user connector) | read-only DEV checks for QA stage B: `list_tables`, `list_migrations`, `get_advisors`, approved read-only SQL |
| GitHub MCP (user connector) | PRs, issues, CI status |

Skip: Clerk, NestJS, Prisma or Cloudflare skills on this stack; payment-provider skills (Paddle's `.md` docs and SDK types were enough).

## Lessons it bundles

`profile.yml` → `lessons` lists 52 lesson ids from [`lessons/`](../../lessons/), grouped by folder, on top of the 40 seed checklist items every install gets:

- `stack/nextjs` (12): loading boundaries fixing the status code, route claims from the build table, rethrow in try/catch, stale dev types, state cleared during render in a suspended navigation, server actions without `Origin`, the `metadataBase` trailing slash, route-group moves, the two-request prefetch, streamed pages' hidden copy, Zod under a strict CSP, every header source.
- `stack/playwright` (8) and `stack/chromium` (1): substring name locators, scoping axe to an open modal layer, 204 for pending form posts, `unrouteAll` wait, headless-shell glyph widths, a shared overlay handler, pinned time zones, a fixture that fails on CSP violations; the range-input focus quirk.
- `stack/pnpm` (2), `stack/drizzle` (1): lockfile re-resolve after an upgrade, opt-in build scripts, schema-drift check.
- `service/supabase` (11): remote-write denies, the account-wide connector, the local-target guard, explicit API grants, Confirm email, session IPs in privacy copy, the stack's DB wait, auth responses checked locally, keeping the authoritative session check, the production migration role, the proxy CA for local auth.
- `service/vercel` (2), `service/github-actions` (2), `service/claude-code-web` (2, only for cloud sessions), `service/paddle` (3, only when billing through Paddle).
- `practice` (8): generic lessons outside the seed checklist that this stack hits often (slow-server polling tests, tab return by visibility change, local-only QA scripts, stack reset before the final run, one stack per agent, repeated timing tests, the background full suite, the pre-QA review).

Each lesson's `evidence` says how often it fired in Twinpage's prune audits (`unknown` where the audits recorded it only as insurance).

## Origin notes

Twinpage specifics that did not become suggestions: its snippet bundle budget (6400 B gzipped), its seed users and API keys, its DEV project ref, and its release dates. A project with a customer-site script can copy the budget idea from checklist item 27 (budgets and baselines).
