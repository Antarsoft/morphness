# Agent instructions

Read this file first. The **harness is generic** (the kit in `harness/`, which this repo owns and may morph); **this repo's product and stack** live under `project/` and `docs/` when present. Structural settings (branches, modules, checks, effort defaults) are in [harness.config.yml](harness.config.yml).

**Project:** {{project.name}}. {{project.description}}

## Golden rules

- **Prefer files over memory.** If it is not documented, say so.
- **Match project conventions** in `project/PROJECT.md` and existing code before inventing patterns.
- **Harness for non-trivial work.** See [harness/MODES.md](harness/MODES.md).
- **Commit and push:** feature branches start from `origin/{{branches.integration}}`; WIP commits to the feature branch are allowed between handoffs; PRs into `{{branches.integration}}` (explicit base) open as drafts at the first push and are marked ready after QA pass; merges only when the human asks ([technical-lead.md](.claude/rules/technical-lead.md)). `{{branches.production}}` moves only through a release (`{{branches.integration}}` → `{{branches.production}}`) when the human says "release" ([harness/RELEASE.md](harness/RELEASE.md)). Direct pushes to `{{branches.production}}` or `{{branches.integration}}` and force-pushes are denied in `.claude/settings.json`.
- **Shared remote environments: no agent writes.** No agent (Technical Lead, Full-stack, QA or any other) changes a shared remote environment: no migrations, DDL or data changes on a remote database, no deploys, no edits to production or staging config, secrets or project settings. Agents write the change as files (migrations, config, infrastructure code) and test it on a local stack. Remote environments change only through the project's own workflows or by the owner ({{human.name}}) by hand; [project/RELEASE.md](project/RELEASE.md) says which. Read-only checks on remote (listing, advisors, read-only queries the human approves) are fine. Details, when the `data-access` module is enabled: [harness/modules/data-access/README.md](harness/modules/data-access/README.md). Enforced where possible in `.claude/settings.json` (deny/ask rules).
- **Technical Lead never implements or QA's.** See [.claude/rules/technical-lead.md](.claude/rules/technical-lead.md). User words like "execute", "implement", or "develop" mean **delegate Full-stack**; after dev completes, **mandatory QA** before sign-off.

## Harness (how we work)

| Document | Purpose |
|----------|---------|
| [harness/README.md](harness/README.md) | Kit overview and adoption |
| [harness/SETUP.md](harness/SETUP.md) | Runbook and lifecycle |
| [harness/STRATEGY.md](harness/STRATEGY.md) | Roles and folder layout |
| [harness/HANDOFFS.md](harness/HANDOFFS.md) | Templates and ownership |
| [harness/CONTROLS.md](harness/CONTROLS.md) | Checks before handover (commands: [project/CONTROLS.md](project/CONTROLS.md)) |
| [harness/MODES.md](harness/MODES.md) | Full vs light mode |
| [harness/RELEASE.md](harness/RELEASE.md) | Release integration → production (project specifics: [project/RELEASE.md](project/RELEASE.md)) |
| [harness/MORPHING.md](harness/MORPHING.md) | How the harness changes itself (retros, prunes, where a lesson lands) |
| `harness/modules/` | Optional modules enabled in `harness.config.yml` → `modules` |

**Runtime feature folders:** `_harness/features/<slug>/<version>/`

Per feature, what the human has to do after QA pass is in the steps file (with the `roadmap` module: **`docs/versions/<id>/steps/<slug>.md`**; none when nothing needs them); **`QA/qa-result.md`** is the formal QA record.

**You are usually:** Technical Lead in the main chat. **Plan and delegate only**; never edit application code or `qa-result.md`. Delegate implementation and QA with the Agent tool per [harness/HANDOFFS.md](harness/HANDOFFS.md). Subagents, models and per-feature effort: [project/HARNESS_AGENTS.md](project/HARNESS_AGENTS.md). Hard rules: [.claude/rules/technical-lead.md](.claude/rules/technical-lead.md).

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
| Rules (always loaded) | `.claude/rules/*.md`: technical lead, harness, testing |
| Subagents | `.claude/agents/` (one file per effort level) → generic bodies in `harness/agents/`, project addenda in `project/agents/` |
| Settings | `.claude/settings.json` (startup hook, permissions) |
| MCP | `.mcp.json` when the project has one; other MCPs come from your own connectors ([project/SKILLS_AND_MCPS.md](project/SKILLS_AND_MCPS.md)) |

**Permissions for this project:** `.claude/settings.json` ships with generic denies (secrets in `.env*` files, pushes to the integration and production branches, force-pushes). Add the project's own rules there: `deny` every tool or command that writes a shared remote environment (database migrate/push commands, deploy commands, MCP tools that apply migrations, create branches or deploy), and `ask` for remote tools that can both read and write (for example an MCP tool that runs SQL). List what you added in [project/SKILLS_AND_MCPS.md](project/SKILLS_AND_MCPS.md).

## Product docs (this repository only)

<!-- morph-init: fill with the product docs this repo has. With the roadmap module, keep the next paragraph; otherwise replace it with where scope is decided. Add a line for a design doc (tokens, theme, shared UI primitives) if the project has one. -->

**[docs/ROADMAP.md](docs/ROADMAP.md) is the source of truth for versions and scope**; each version has a document under `docs/versions/`. Other product and planning docs live under `docs/`. They describe **what** to build; the harness describes **how** to execute work.
