# Skills and MCPs: {{project.name}}

Stack: {{stack.summary}}.

Generic guidance (when to use a skill, an MCP or the repo's own docs): [harness/SKILLS_AND_MCPS.md](../harness/SKILLS_AND_MCPS.md).

## Summary

| Layer | Best approach |
|-------|---------------|
<!-- morph-init: fill one row per stack layer: the skill, MCP or doc an agent reaches for first. Example: "| Database | the vendor's agent skill + its MCP (read-only) after auth |", "| Payments | `docs/BILLING.md`, then the provider's docs |", "| Browser tests | the e2e runner's skill |", "| Git / PRs | the PR host's MCP or CLI |". -->

## Installed (repo)

| Skill | Path |
|-------|------|
<!-- morph-init: fill each skill installed in the repo and its path (for example `.agents/skills/<name>/`, with `.claude/skills` as a symlink to it). Write "None yet" when there are none. -->

## MCPs

| MCP | Config | Use for |
|-----|--------|---------|
<!-- morph-init: fill each MCP: where it is configured (`.mcp.json` in the repo, or the person's own connector), and what agents use it for. For an account-wide connector, say which project or environment id agents must always target. Example: "| Docs lookup | `.mcp.json` | version-specific library docs |". -->

**Remote environments:** no agent writes through an MCP (`AGENTS.md`): no migrations, DDL, data changes, deploys or settings changes. Read-only tools are fine; tools that can both read and write are `ask` in `.claude/settings.json`, tools that only write are `deny`.

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
