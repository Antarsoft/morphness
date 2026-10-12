# Suggestion catalog

morph-init and morph-doctor suggest only from this file, the source's `lessons/` and `profiles/`,
or what the user names. Each entry says when to suggest it and why. Nothing installs without the
user's yes. Before suggesting a skill, check it isn't already in `.agents/skills/`, `.claude/skills/`
or `skills-lock.json`; before suggesting a connector, check `.mcp.json` and ask whether the user
already has it as a personal connector.

To grow this list, open a PR (see CONTRIBUTING.md). Keep entries to things you've used.

## How skills install

Agent skills install with `npx skills add <owner/repo> --skill <name>` (they land in `.agents/skills/`
and are recorded in `skills-lock.json`). Claude Code reads `.claude/skills/`; render.md makes
`.claude/skills` a symlink to `.agents/skills` so one copy serves both. Plugins install with
`/plugin marketplace add <owner/repo>` then `/plugin install <name>`.

## Skills

| Suggest when | Skill (source) | Why |
|--------------|----------------|-----|
| Always, as an option | `find-skills` (`vercel-labs/skills`) | Lets agents discover more skills later instead of guessing. |
| React or Next.js | `vercel-react-best-practices` (`vercel-labs/agent-skills`) | Current React and Next.js performance and correctness patterns the model may not know. |
| Next.js App Router | `nextjs-app-router-patterns` (`wshobson/agents`) | Server and client component boundaries, caching and routing patterns. |
| A UI the agents design | `web-design-guidelines` (`vercel-labs/agent-skills`) | A consistent review list for layout, spacing, states and accessibility. |
| shadcn/ui in use or planned | `shadcn` (`shadcn-ui/ui`) | Adds and composes components the way the library expects. |
| Supabase | `supabase`, `supabase-postgres-best-practices` (`supabase/agent-skills`) | Auth, RLS and Postgres guidance from the vendor; pairs with the data-access module. |
| Drizzle ORM | `drizzle-orm-patterns` (`giuseppe-trisciuoglio/developer-kit`) | Schema and query patterns; there's no official Drizzle skill. |
| Browser e2e with Playwright | `playwright-cli` (`microsoft/playwright-cli`) | Lets QA drive a real browser for checks and screenshots. |

For any other stack, suggest `find-skills` and say there's no vetted entry yet; offer to search with
it after install rather than guessing a repo name.

## Connectors and MCP servers

| Suggest when | Connector | Scope | Why |
|--------------|-----------|-------|-----|
| Any library or framework | Context7 (`https://mcp.context7.com/mcp`, http) | project (`.mcp.json`) | Version-specific docs, so agents don't code against stale APIs. |
| `pr_host: github` | GitHub | user connector | PRs, CI status and review comments for the TL and QA. |
| Supabase | Supabase | user connector | Read-only checks on remote (list tables, advisors, logs) in data-access stage B. Account-wide: record the project ref to target in `project/STACK.md`. |
| Error tracking in use (Sentry, PostHog, etc.) | That vendor's connector | user connector | Lets the TL and QA read real errors when planning a fix. |
| Hosting with an MCP (Vercel, Cloudflare, etc.) | That vendor's connector | user connector | Read deploy status and logs. Agents still never deploy or change production settings. |
| Issue tracker (Linear, Jira, GitHub Issues) | That vendor's connector | user connector | Lets the TL pull the ask and acceptance notes straight into `feature.md`. |

User connectors are added by the user (Claude Code: `/mcp` or `claude mcp add`; claude.ai:
Settings > Connectors). morph-init writes project-scoped ones to `.mcp.json` only on yes.

When a connector can write to a shared environment, render.md adds `ask` or `deny` permission rules
for its write tools in `.claude/settings.json` (data-access module). Say so when suggesting it.

## Profiles

| Profile | Suggest when |
|---------|--------------|
| `web-saas-nextjs-supabase` | Next.js app with Supabase (Postgres, Auth), especially a pnpm monorepo. |

A profile supplies suggested answers, check commands, risk areas, permission rules and lesson ids.
Every suggestion it makes is still asked, not applied.
