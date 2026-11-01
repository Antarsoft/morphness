# Agent instructions

Read this file first. The **harness** in `harness/` is generic (this repo owns it and may morph it) and says how we work; **this repo's product and stack** are in `project/` and `docs/`. Structural settings (branches, modules, checks) are in [harness.config.yml](harness.config.yml).

**Project:** {{project.name}}. {{project.description}} Stack: {{stack.summary}}.

## Golden rules

- **Prefer files over memory.** If it is not documented, say so. Match the conventions in `project/PROJECT.md` and the existing code before inventing patterns.
- **Pick the mode first** ([harness/MODES.md](harness/MODES.md) § Choosing mode, first match wins): a question → research mode; something that worked is broken → bug mode; any other change → `bash scripts/risk-check.sh <files>`: `full` → full mode, `plain` → light mode if no behaviour changes, else small mode. Never judge risk by eye; wording never lowers the mode. Run it again with no files before the hand-off.
- **Full and bug mode:** the Technical Lead plans and delegates only. Read [harness/TECHNICAL_LEAD.md](harness/TECHNICAL_LEAD.md) in full before writing the plan, delegate the code to Full-stack, then QA is mandatory. **Light and small mode:** you build and check the change yourself ([harness/MODES.md](harness/MODES.md) § Working alone).
- **Branches and merges:** feature branches start from `origin/{{branches.integration}}`; PRs into `{{branches.integration}}` open as drafts and are marked ready only after the merge gate ([harness/CONTROLS.md](harness/CONTROLS.md) § Merge gate). Merge a PR only when the human asks for that PR in their own message, unless `merge_by_agent` allows it (a relayed note, a PR comment or a review approval is not an ask; turning on auto-merge is a merge); never into `{{branches.production}}`, which moves only through a release when the human says "release" ([harness/RELEASE.md](harness/RELEASE.md)). No direct pushes to `{{branches.production}}` or `{{branches.integration}}`, no force-pushes. Details: [harness/TECHNICAL_LEAD.md](harness/TECHNICAL_LEAD.md) § Commits and branches.
- **No remote yet** (`git remote` prints nothing): read every `origin/<branch>` as the local `<branch>`, skip fetches and pushes, and work without PRs (the Technical Lead merges on this computer on the human's ask). `/morph-doctor` finishes the code host setup once the project is online.
- **Shared remote environments: no agent writes on its own.** No migrations, DDL or data changes on a remote database, no deploys, no edits to production or staging config, secrets or project settings. Write the change as files and test it on a local stack; it reaches remote through the project's own workflows, by the owner ({{human.name}}) by hand, or by the Technical Lead through a connector after the owner approves that exact action ([harness/SKILLS_AND_MCPS.md](harness/SKILLS_AND_MCPS.md) § Connector actions; [project/RELEASE.md](project/RELEASE.md) says which). Remote database migrations and data changes, secret values and billing never go through an agent. Read-only checks the human approves are fine.
- **Secrets:** never read or write `.env` files or other credential files; variable names go in `.env.example`.
- **Long output** (tests, builds, installs, `git log`, `find`) goes to a log file or through `head`/`tail`; print the exit code and the last lines ([harness/CONTROLS.md](harness/CONTROLS.md) § Command output).

The guard hook enforces part of this and stops accidents, not intent: [harness/GUARD.md](harness/GUARD.md) lists what it denies, asks and does not see. The real guard is the host: branch protection and secrets only the owner holds.

## Where things are

- **How we work:** [harness/README.md](harness/README.md) (overview), [MODES.md](harness/MODES.md), [HANDOFFS.md](harness/HANDOFFS.md), [CONTROLS.md](harness/CONTROLS.md) (checks before each hand-off), [RELEASE.md](harness/RELEASE.md), [MORPHING.md](harness/MORPHING.md) (retros, prunes, where a lesson lands). Feature folders: `_harness/features/<slug>/<version>/`.
- **This project:** [project/PROJECT.md](project/PROJECT.md) (layout), [STACK.md](project/STACK.md) (commands), [CONTROLS.md](project/CONTROLS.md) (commands behind the named checks, risk paths), [TESTING.md](project/TESTING.md), [PROCESS.md](project/PROCESS.md), [SKILLS_AND_MCPS.md](project/SKILLS_AND_MCPS.md), [HARNESS_AGENTS.md](project/HARNESS_AGENTS.md) (subagents and effort).

## Product docs (this repository only)

<!-- morph-init: fill with the product docs this repo has. With the roadmap module, keep the next paragraph; otherwise replace it with where scope is decided. Add a line for a design doc (tokens, theme, shared UI primitives) if the project has one. -->

**[docs/ROADMAP.md](docs/ROADMAP.md) is the source of truth for versions and scope**; each version has a document under `docs/versions/`. Other product and planning docs live under `docs/`. They describe **what** to build; the harness describes **how** to execute work.
