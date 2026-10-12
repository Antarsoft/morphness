# Skills and MCPs

## Before unfamiliar work

1. Read **`project/SKILLS_AND_MCPS.md`** for this repository's integrations.
2. Use skills and MCP tools when they match the task (APIs, cloud services, frameworks).
3. The Technical Lead captures the required references in `plan.md` so the Full-stack engineer does not need broad web search.

## Technical Lead

- May use skills and MCPs for **research and planning**.
- Records links and decisions in `plan.md` → References, each as `file § section` or `file:line`, never a whole file.
- Runs the `code-review` and, for risk areas, `security-review` skills itself before QA on `xhigh` work ([SETUP.md](./SETUP.md) § Code review before QA).
- Read-only MCP checks on a remote environment (listing tables, advisors, read-only queries the human approves) are fine; anything that writes is not ([STRATEGY.md](./STRATEGY.md)).

## Full-stack engineer

- Prefers the references in `plan.md` and the project docs.
- Uses skills and MCPs for implementation when listed in `project/SKILLS_AND_MCPS.md`.
- Never uses an MCP to write to a shared remote environment (integration or production).

## QA engineer

- Uses skills and MCPs to **run** or **observe** the system when the plan requires it.
- **Data-access features** (plan flag **yes**): **required** validation per [modules/data-access/](./modules/data-access/README.md): stage A on the local stack, then stage B (read-only) on the integration environment after the migrations reach it. Not optional.
- Browser automation when end-to-end or UI ACs need it ([modules/browser-e2e/](./modules/browser-e2e/README.md)); no scope creep into implementation.

## Per-project file

**`project/SKILLS_AND_MCPS.md`** holds:

- Stack-specific skills (names or paths) and when each applies
- MCP servers used in this repo, with the account or project each must target
- APIs that always need a doc lookup (with URLs)

Lessons about a particular skill or MCP land there, not here ([MORPHING.md](./MORPHING.md) § Where a lesson lands).
