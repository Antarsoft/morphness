@AGENTS.md

## Claude Code notes

Project rules live in `.claude/rules/*.md` and load automatically: `technical-lead.md`, `harness.md`, `testing.md`. Stack facts live in [project/STACK.md](project/STACK.md), not in a rule file.

- **Delegation:** the Agent tool with a `subagent_type` from `.claude/agents/`: `fullstack-engineer` / `qa-engineer`, or their effort variants picked in the plan's **Agent effort** section, `researcher` / `researcher-high` for research mode and research before a plan, and `legal-writer` for a plan's legal wording (when the `legal` module is enabled). Models, effort levels and the mapping are in [project/HARNESS_AGENTS.md](project/HARNESS_AGENTS.md). Pass the absolute feature folder paths in the prompt.
- **Subagent instructions:** each `.claude/agents/*.md` file only sets model and effort; the role body is `harness/agents/<role>.md` (generic), then `project/agents/<role>.md` (this project's addenda).
- **Config:** [harness.config.yml](harness.config.yml) holds the structural facts (branches, modules, named checks, CI gate, risk areas, effort defaults, loop limits). Rules refer to its keys by name.
- **Settings:** `.claude/settings.json` runs `scripts/session-start.sh` on session start (toolchain setup and dependency install) and denies reading `.env*` secrets. Personal overrides go in `.claude/settings.local.json` (gitignored).

<!-- morph-init: fill with project-specific Claude Code notes, e.g. where skills are installed, which MCP servers come from the repo (.mcp.json) and which from the user's connectors, and which remote project or environment an MCP must target. -->
