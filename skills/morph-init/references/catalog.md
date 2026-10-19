# Suggestion catalog

morph-init and morph-update suggest only from this file, the source's `lessons/` and `profiles/`,
or what the user names. Each entry says when to suggest it and why. Nothing installs without the
user's yes. Before suggesting a skill, check it isn't already in `.agents/skills/`, `.claude/skills/`
or `skills-lock.json`; before suggesting a connector, check `.mcp.json` and ask whether the user
already has it as a personal connector.

To grow this list, open a PR (see CONTRIBUTING.md). Keep entries to things you've used.

## How skills install

Agent skills install from the pinned commit in the table below, never from a repository's moving head:
clone the repository into an empty temporary folder, check out the pinned commit, and run
`npx skills@1.7.2 add <that folder> --skill <name>` (they land in `.agents/skills/` and are recorded in
`skills-lock.json`). If that can't be done, say so and install nothing without the owner's yes to an
unpinned install. In a project with the guard hook the command itself shows a permission prompt
(`guard.installs`); the owner has accepted the list already, so answer yes there. Record each installed skill's source and commit in `project/SKILLS_AND_MCPS.md` §
Installed (repo). Skill text enters the agents' context, so a moved pin is reviewed (read the diff
between the two commits) before this table changes. Claude Code reads `.claude/skills/`; render.md makes
`.claude/skills` a symlink to `.agents/skills` so one copy serves both. Plugins install with
`/plugin marketplace add <owner/repo>` then `/plugin install <name>`.

## Skills

| Suggest when | Skill (source) | Pinned commit | Why |
|--------------|----------------|---------------|-----|
| Always, as an option | `find-skills` (`vercel-labs/skills`) | `13e4063a1cf913f5606d57d42ab83a86f5001e04` | Lets agents discover more skills later instead of guessing. |
| React or Next.js | `vercel-react-best-practices` (`vercel-labs/agent-skills`) | `063bee94c3f4df8453406c830b0a7df0f2860278` | Current React and Next.js performance and correctness patterns the model may not know. |
| Next.js App Router | `nextjs-app-router-patterns` (`wshobson/agents`) | `0874a27b17a22e2b7c2e2bcd725768e0803cad06` | Server and client component boundaries, caching and routing patterns. |
| A UI the agents design | `web-design-guidelines` (`vercel-labs/agent-skills`) | `063bee94c3f4df8453406c830b0a7df0f2860278` | A consistent review list for layout, spacing, states and accessibility. |
| shadcn/ui in use or planned | `shadcn` (`shadcn-ui/ui`) | `ba1503c64472b82256d9de95e2e62c5901a38e8b` | Adds and composes components the way the library expects. |
| Supabase | `supabase`, `supabase-postgres-best-practices` (`supabase/agent-skills`) | `c9be0e931b7930f7d02126d04774d904c381e7d7` | Auth, RLS and Postgres guidance from the vendor; pairs with the data-access module. |
| Drizzle ORM | `drizzle-orm-patterns` (`giuseppe-trisciuoglio/developer-kit`) | `fe73fb33a09ee6562eeec7415a3f9a3bcf795177` | Schema and query patterns; there's no official Drizzle skill. |
| Browser e2e with Playwright | `playwright-cli` (`microsoft/playwright-cli`) | `b85c7a736bb473bf55b584e54a09ffa698d6d871` | Lets QA drive a real browser for checks and screenshots. |

### Built-in skills the process uses

Not installed by morph-init: Claude Code ships them. Check they are in this session's skill list and
say which are missing.

| Skill | Used by | Why | When it's missing |
|-------|---------|-----|-------------------|
| `code-review` | `harness/SETUP.md` § Code review before QA (`xhigh` Full-stack work) | Finds bugs outside the acceptance criteria before QA spends a round on them. | The TL runs the same read-only review as a subagent and marks it in `Plan/review.md` (SETUP § Code review before QA). Suggest updating Claude Code. |
| `security-review` | Same section, when the plan touches a `risk_areas` entry | A deeper pass on auth, ownership and input handling. | Same fallback, briefed with the security files to read in full. |

For any other stack, suggest `find-skills` and say there's no vetted entry yet; offer to search with
it after install rather than guessing a repo name.

## Connectors and MCP servers

| Suggest when | Connector | Scope | Why |
|--------------|-----------|-------|-----|
| Any library or framework | Context7 (`https://mcp.context7.com/mcp`, http) | project (`.mcp.json`) | Version-specific docs, so agents don't code against stale APIs. |
| `pr_host: github` | GitHub | user connector | PRs, CI status and review comments for the TL and QA. |
| Supabase | Supabase | user connector | Read-only checks on remote (list tables, advisors, logs) in data-access stage B. Account-wide: record the project ref to target in `project/STACK.md`. |
| Error tracking in use (Sentry, PostHog, etc.) | That vendor's connector | user connector | Lets the TL and QA read real errors when planning a fix. |
| Hosting, DNS, storage or app builds with an official MCP (Vercel, Cloudflare, Expo, etc.) | That vendor's connector | user connector | Read deploy status and logs, and let the Technical Lead do setup work (create a project, set a non-secret variable, add a domain) instead of handing it to you. Every write is asked in chat first, one approved action at a time. |
| Issue tracker (Linear, Jira, GitHub Issues) | That vendor's connector | user connector | Lets the TL pull the ask and acceptance notes straight into `feature.md`. |

A remote connector (such as Context7's hosted server) can't be pinned: its text comes from the vendor's
server at each call. Say so when suggesting it.

User connectors are added by the user (Claude Code: `/mcp` or `claude mcp add`; claude.ai:
Settings > Connectors). morph-init writes project-scoped ones to `.mcp.json` only on yes.

**Official only.** Suggest a connector for a service only when the vendor publishes it (its own docs
domain or GitHub organisation, or a connector directory listing that names the vendor as publisher).
For a service in the stack that isn't in this table, check that first: look it up on the vendor's own
docs (a doc MCP or web search, read-only) and suggest it only when you find the vendor's page; say
"no official MCP found" otherwise, and never suggest a community server as the vendor's. Every
service, with or without an MCP, gets a row in `project/SKILLS_AND_MCPS.md` § Service tools.

When a connector can write, render.md adds `ask` rules for its write tools in `.claude/settings.json`
(and `deny` for tools that write a remote database). Say so when suggesting it: nothing it writes runs
without the owner's yes in chat (`harness/SKILLS_AND_MCPS.md` § Connector actions).

## Profiles

| Profile | Suggest when |
|---------|--------------|
| `web-saas-nextjs-supabase` | Next.js app with Supabase (Postgres, Auth), especially a pnpm monorepo. |

A profile supplies suggested answers, check commands, risk areas, permission rules and lesson ids.
Every suggestion it makes is still asked, not applied.
