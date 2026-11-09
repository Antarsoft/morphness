@AGENTS.md

## Claude Code notes

- **Loaded for you:** this file and `AGENTS.md`. `harness/TECHNICAL_LEAD.md` is read when a full or bug mode plan starts (AGENTS.md § Golden rules). Rules in `.claude/rules/*.md` load when you open or write a file their `paths:` match with the Read, Edit or Write tools (not `cat` in Bash, so read files with Read): `harness.md` (feature folders), `testing.md` (tests), `data.md` (schema and migrations), `auth.md` (sign-in and access), `deploy.md` (CI and deploy config).
- **Subagents** set `omitClaudeMd: true` and load none of these; their rules are in `harness/agents/<role>.md`, then `project/agents/<role>.md`. A hand-off names any `.claude/rules/` file the plan's paths need ([harness/HANDOFFS.md](harness/HANDOFFS.md)).
- **Delegation:** the Agent tool with a `subagent_type` from `.claude/agents/`, the variant the plan's **Agent effort** picks ([project/HARNESS_AGENTS.md](project/HARNESS_AGENTS.md)). Pass the absolute feature folder paths in the prompt.
- **Settings:** `.claude/settings.json` runs `scripts/session-start.sh` on session start and `scripts/guard.sh` before tool calls ([harness/GUARD.md](harness/GUARD.md)). Personal overrides go in `.claude/settings.local.json` (gitignored).

<!-- morph-init: fill with project-specific Claude Code notes, e.g. where skills are installed, which MCP servers come from the repo (.mcp.json) and which from the user's connectors, and which remote project or environment an MCP must target. -->
