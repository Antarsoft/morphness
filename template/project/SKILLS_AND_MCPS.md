# Skills and MCPs: {{project.name}}

Stack: {{stack.summary}}.

Generic guidance (when to use a skill, an MCP or the repo's own docs): [harness/SKILLS_AND_MCPS.md](../harness/SKILLS_AND_MCPS.md).

## Summary

| Layer | Best approach |
|-------|---------------|
<!-- morph-init: fill one row per stack layer: the skill, MCP or doc an agent reaches for first. Example: "| Database | the vendor's agent skill + its MCP (read-only) after auth |", "| Payments | `docs/BILLING.md`, then the provider's docs |", "| Browser tests | the e2e runner's skill |", "| Git / PRs | the PR host's MCP or CLI |". -->

## Installed (repo)

| Skill | Path | Source and pinned commit |
|-------|------|--------------------------|
<!-- morph-init: fill each skill installed in the repo, its path (for example `.agents/skills/<name>/`, with `.claude/skills` as a symlink to it) and where it came from as `<owner/repo>@<full 40-character commit>` (the commit it was installed from, per morph-init's catalog.md; a skill the owner named themselves gets the commit they confirm, or "unpinned (owner's choice)"). Write "None yet" when there are none. -->

## MCPs

| MCP | Config | Use for |
|-----|--------|---------|
<!-- morph-init: fill each MCP: where it is configured (`.mcp.json` in the repo, or the person's own connector), and what agents use it for. For an account-wide connector, say which project or environment id agents must always target. Example: "| Docs lookup | `.mcp.json` | version-specific library docs |". -->

**Remote environments:** only the Technical Lead writes through a connector, and only after the owner approves that exact action ([harness/SKILLS_AND_MCPS.md](../harness/SKILLS_AND_MCPS.md) § Connector actions). Remote database migrations and data changes never go through an agent. Read-only tools are fine; tools that create, change or delete are `ask` in `.claude/settings.json`, tools that write a remote database are `deny`.

## Service tools

Every external service the project uses (hosting, database, auth, DNS, storage, email, app stores), and whether an official MCP can do its setup work. The Technical Lead reads this before writing any human step ([harness/SKILLS_AND_MCPS.md](../harness/SKILLS_AND_MCPS.md) § Connector actions). Re-check a row older than 90 days with the researcher before relying on it.

| Service | Official MCP (source, date checked) | Connected as | Can do | Can't do |
|---------|-------------------------------------|--------------|--------|----------|
<!-- morph-init: fill one row per external service in the stack answers. Official MCP: the vendor's own docs page or GitHub org that publishes it, with the date read; "none found (<date>)" or "community only (<date>)" otherwise. Connected as: `.mcp.json`, user connector, plugin, or "not connected". Can do / Can't do: the setup work the human would otherwise do by hand (create a project, set a variable, add a domain or DNS record), from the server's tool list. Example: "| Hosting | <vendor docs URL> (<date>) | user connector | create project, env vars, domains | billing, team members |". -->

## Permission rules added for this project

<!-- morph-init: fill each deny/ask rule added to `.claude/settings.json` beyond the generic ones, with one line of why. Example: "deny `Bash(<db-cli> migrate*)`: remote migrations run only through the workflow". -->

## When to use what

```
Feature work
<!-- morph-init: fill a short decision tree. Example:
  ├─ Schema change          → the database skill, then generate a migration
  ├─ Payment flow           → docs/BILLING.md + the provider's docs
  └─ Debug the live project → the database MCP, read-only
-->
```

## External docs

| System | URL |
|--------|-----|
<!-- morph-init: fill the external pages agents need most often (auth integration guide, webhook signature docs). -->

## Project conventions

<!-- morph-init: fill the conventions that apply across the repo (strict typing, where shared types live, no secrets in the repo, pinned versions and a committed lockfile). -->
