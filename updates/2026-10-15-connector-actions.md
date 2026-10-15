---
id: 2026-10-15-connector-actions
title: Setup work through connectors, each action approved first
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - AGENTS.md
  - harness/SKILLS_AND_MCPS.md
  - harness/HANDOFFS.md
  - harness/PLAN_CHECKLIST.md
  - harness/RELEASE.md
  - harness/templates/plan.md
  - harness/templates/steps.md
  - project/SKILLS_AND_MCPS.md
  - project/RELEASE.md
  - project/STACK.md
  - .claude/rules/technical-lead.md
removed: []
---

## What changed

Before handing setup work to the human (create a hosting project, set a variable, add a domain or a
DNS record), the Technical Lead now checks whether a connected official MCP, connector or plugin can
do it. If one can, the TL offers to do it and runs each action only after the human approves that
exact action in chat; nothing a connector writes runs automatically. Whatever stays with the human
says why: no official MCP (with the date checked), an official one that isn't connected (with its
link), or no tool for it in the connected one. A new **Service tools** table in
`project/SKILLS_AND_MCPS.md` records each service's official MCP, filled by the researcher when a row
is missing or older than 90 days. The plan gets a **By connector** line and the steps file a
**Done for you** section. Remote database changes, secret values, billing and people's access never
go through an agent.

## Why

Feature hand-offs ended with lists of console chores (Vercel, Supabase, Cloudflare, Expo, DNS) even
when the project had the vendor's connector set up, because the kit banned every agent write to a
remote service and never asked whether a connected tool could do the step. The owner also had no way
to tell whether an official MCP existed for a service at all.

## How to apply

1. Add § Connector actions to `harness/SKILLS_AND_MCPS.md` and the Service tools line to its
   § Per-project file list.
2. Add § Service tools to `project/SKILLS_AND_MCPS.md` and fill one row per external service the
   project uses. For each service, run research mode with the question "Does <service> publish an
   official MCP, and what setup work can it do?" (or fill the rows from the vendor's own docs), and
   mark the MCPs this session has as connected. Rewrite its **Remote environments** line.
3. For each connected connector that can write, add `ask` rules in `.claude/settings.json` for its
   create, change and delete tools by name, keep `deny` on tools that write a remote database, and
   list them in `project/SKILLS_AND_MCPS.md` § Permission rules added for this project. Replace any
   existing `deny` on non-database write tools (create project, set variable, DNS) with `ask` only if
   the owner wants the Technical Lead to offer that work.
4. Merge the wording changes: the shared-environments golden rule and the permissions paragraph in
   `AGENTS.md`; the steps-file list and QA scope line in `harness/HANDOFFS.md`; item 38 in
   `harness/PLAN_CHECKLIST.md`; the two sentences in `harness/RELEASE.md`; the header in
   `project/RELEASE.md`; the deploy fill comment in `project/STACK.md`; the **By connector** and
   **Human steps** lines in `harness/templates/plan.md`; the **Done for you** and **Needs you** blocks
   in `harness/templates/steps.md`; the two bullets in `.claude/rules/technical-lead.md`.
5. Run `/morph-doctor`: it checks the Service tools rows against the connected tools and the `ask`
   rules.

## Skip if

The owner wants every external setup step done by hand, even when a connector could do it. Keep the
Service tools table anyway: it says which services have an official MCP.
