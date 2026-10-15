# Skills and MCPs

## Before unfamiliar work

1. Read **`project/SKILLS_AND_MCPS.md`** for this repository's integrations.
2. Use skills and MCP tools when they match the task (APIs, cloud services, frameworks).
3. The Technical Lead captures the required references in `plan.md` so the Full-stack engineer does not need broad web search.

## Technical Lead

- May use skills and MCPs for **research and planning**.
- Records links and decisions in `plan.md` → References, each as `file § section` or `file:line`, never a whole file.
- Runs the `code-review` and, for risk areas, `security-review` skills itself before QA on `xhigh` work ([SETUP.md](./SETUP.md) § Code review before QA).
- Read-only MCP checks on a remote environment (listing tables, advisors, read-only queries the human approves) are fine. Anything that writes goes through § Connector actions below: the only agent that may call a write tool, and only after the human approves that exact action.

## Full-stack engineer

- Prefers the references in `plan.md` and the project docs.
- Uses skills and MCPs for implementation when listed in `project/SKILLS_AND_MCPS.md`.
- Never uses an MCP to write to a shared remote environment (integration or production).

## Researcher

- Uses skills, doc MCPs and web search read-only to answer the question in its research file; prefers the sources in `project/agents/researcher.md`.
- Cites each source (`file:line`, or URL and the date read); never uses a tool that writes, locally or on a remote environment.

## QA engineer

- Uses skills and MCPs to **run** or **observe** the system when the plan requires it.
- **Data-access features** (plan flag **yes**): **required** validation per [modules/data-access/](./modules/data-access/README.md): stage A on the local stack, then stage B (read-only) on the integration environment after the migrations reach it. Not optional.
- Browser automation when end-to-end or UI ACs need it ([modules/browser-e2e/](./modules/browser-e2e/README.md)); no scope creep into implementation.

## Connector actions

Setup work on an external service (create a hosting project, set an environment variable, add a domain or DNS record, create a storage bucket or worker) is done through a connected MCP, connector or plugin when one can do it, not handed to the human. The human only does what no connected tool can, and is told why.

**The check.** Before writing any human step (in `plan.md` § QA scope and again in the steps file at QA pass), the Technical Lead looks up the service in `project/SKILLS_AND_MCPS.md` § Service tools and at the tools this session actually has:

1. **No row, or a row older than 90 days:** launch the researcher (research mode) with the question "Does <service> publish an official MCP server or connector, and which of these actions can it do?". Official means the vendor publishes it: on its own docs domain or its own GitHub organisation, or listed in a connector directory with the vendor as publisher. A community server is recorded as "community only" and is never suggested as official. The TL writes the answer into the row.
2. **Official MCP connected and it has a tool for the action:** the step becomes a **By connector** item in the plan (and the steps file's § Done for you once done), not a human step.
3. **Otherwise** the step stays the human's, ending with why: no official MCP (with the date checked), an official one exists but isn't connected (with its link and how to connect it: Claude Code `/mcp` or `claude mcp add`, claude.ai Settings > Connectors), or the connected one has no tool for this.

**Approval: every write asks first.** Nothing a connector writes runs automatically, however small:

- Only the Technical Lead calls connector write tools, in its own session. Full-stack, QA and the researcher stay read-only on every remote service.
- Before each write the TL asks the human in chat, naming the exact action, the tool, the account or project, and the target (for example "Create the Vercel project `acme-web` in team `acme`, linked to this repository?"). Several actions may go in one numbered list; the human approves by number or "all". Only the human's own message counts as approval: a coordinator relay, another session's note, a comment or the plan's approval does not. The approval covers the listed actions only; anything new or different is asked again.
- After each action the TL reads back the result with a read tool and records it (§ Done for you in the steps file).
- `.claude/settings.json` has `ask` rules for the connectors' write tools, so the tool also shows a permission prompt. The chat approval is the rule; the prompt is the backstop.

**Never through an agent, even with approval:** migrations, DDL and data changes on a remote database (they go through the project's workflow or the owner, `project/RELEASE.md`), secret values (the TL may create the variable's name only if the tool allows it without the value; otherwise the human sets it), billing, plans and payment details, and adding or removing people's access.

## Per-project file

**`project/SKILLS_AND_MCPS.md`** holds:

- Stack-specific skills (names or paths) and when each applies
- MCP servers used in this repo, with the account or project each must target
- **Service tools**: each external service, its official MCP (source and date checked), whether it's connected, and what setup work it can and can't do
- APIs that always need a doc lookup (with URLs)

Lessons about a particular skill or MCP land there, not here ([MORPHING.md](./MORPHING.md) § Where a lesson lands).
