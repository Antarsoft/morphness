# Harness subagents: {{project.name}}

The Technical Lead delegates the **Full-stack engineer**, the **QA engineer**<!-- module:legal -->, the **legal writer** (legal wording)<!-- /module:legal --> and the **researcher** (research mode) with Claude Code's **Agent** tool. This file is the single place that states which agent, model and effort each piece of work gets.

## Agents

Subagents are defined in `.claude/agents/`. Each file sets only `model`, `effort` and, for the read-mostly roles, tool limits; the instructions are the generic role bodies in `harness/agents/` plus this project's addenda in `project/agents/`, so edit those, not the variant files. The Technical Lead never passes a model or effort: it picks the `subagent_type`.

**Tool limits.** The researcher files set `disallowedTools: Bash, Edit, MultiEdit, Write, NotebookEdit` (no shell and no edit tools, so nothing can be run, sent or changed from there; it replies, and the Technical Lead writes the reply into the research file)<!-- module:legal --> and the legal writer's sets `tools: Read, Grep, Glob, Edit, Write` (no shell, web or MCP tools)<!-- /module:legal -->. Claude Code can't limit Edit to one path or Bash to read-only commands, so which file the others may edit stays a rule in the role bodies. Full-stack and QA keep every tool: QA needs the shell and scratch edits for its checks. Keep these lines when adding a variant (`harness/MORPHING.md` § Trials).

| Role | `subagent_type` | Model | Effort |
|------|-----------------|-------|--------|
| Full-stack engineer | `fullstack-engineer-medium` | `{{models.fullstack_medium}}` | `medium` |
| Full-stack engineer | `fullstack-engineer` (default) | `{{models.fullstack}}` | `high` |
| Full-stack engineer | `fullstack-engineer-xhigh` | `{{models.fullstack}}` | `xhigh` |
| QA engineer | `qa-engineer-medium` | `{{models.qa_medium}}` | `medium` |
| QA engineer | `qa-engineer` (default) | `{{models.qa}}` | `high` |
| Researcher | `researcher` (default) | `{{models.researcher}}` | `medium` |
| Researcher | `researcher-high` | `{{models.researcher_high}}` | `high` |
| Legal writer | `legal-writer` | `{{models.legal}}` | `high` | <!-- module:legal -->

<!-- morph-init: fill the default marks from harness.config.yml → agents. Advised models: all `sonnet` by default; the Opus preset sets the Technical Lead, Full-stack (high and xhigh) and the high researcher to `opus`; legal writer `fable` (fallback `opus`). Change a row and its `.claude/agents/*.md` file together. Drop the legal writer row when the legal module is off. -->

Pass the absolute feature folder path (and the `plan.md` / `progress.md` paths) in the prompt. QA-fail rework goes to the same Full-stack variant as the first round.

## Technical Lead model

The Technical Lead runs in the main chat, so its model is the session's, not a file in `.claude/agents/`. `.claude/settings.json` sets `{{models.tl}}` as the project default; a person can still override it with `/model`.

**Effort:** the Technical Lead runs at `high` effort by default: it plans, reviews and decides retro items, where a miss costs a rework round. Effort is the session's (`/effort high` in a local session; the project default in a hosted one). Handing research to the researcher doesn't change this level: the Technical Lead still frames the question, checks the findings and decides. If usage gets tight, dropping the Technical Lead to `medium` on one-shot threads (a status check, a docs-only PR) is the first saving; feature threads stay at `high`.

**Rule of thumb:** the Technical Lead runs rarely, but a miss there is expensive, so it runs at `high` effort on the model the project chose (Sonnet by default; the Opus preset is for projects where a missed edge case is costly).

## Effort per feature

Each `plan.md` has an **Agent effort** section naming the Full-stack and QA level, with a one-line reason; the owner approves it with the plan. The levels, how to pick one and when to split a feature by risk are in [harness/SETUP.md](../harness/SETUP.md) § Effort per feature. This project's defaults are the variants marked "(default)" in § Agents; its risk areas are below. A prune that tunes effort for this project (for example "architecture research defaults to `high`") adds a bullet here.

**Risk areas (never `medium`):** the areas in `harness.config.yml` → `risk_areas`, with their paths in [CONTROLS.md](CONTROLS.md) § Risk paths; `bash scripts/risk-check.sh` names the one a change touches.

## Trials

A model or effort trial runs on a fixed number of features and is decided at a prune from the numbers. Its file is `_harness/trials/<trial-slug>.md` ([harness/MORPHING.md](../harness/MORPHING.md) § Trials); here it gets one bullet naming the variant and linking that file. When it ends, say so here in one line and move the variant into § Effort per feature or drop it.

<!-- morph-init: no trials at install. Leave this comment; the first retro or prune that starts a trial adds the bullet. -->

<!-- module:legal -->
## Legal wording

<!-- morph-init: with the legal module, keep this paragraph and fill what counts as legal wording in this project (the legal pages and their source files, consent and fine-print lines, any file that mirrors a legal page). Without it, delete the section. -->

Process: [harness/modules/legal/README.md](../harness/modules/legal/README.md). What counts as legal wording here:

- <!-- morph-init: fill, e.g. "Any text on `/terms` and `/privacy` (`src/pages/legal/`) and the values in `src/legal.ts`." -->

When unsure, the Technical Lead treats a sentence as legal.
<!-- /module:legal -->

<!-- module:browser-e2e -->
## Browser tests

- **Full-stack runs targeted specs** before handoff (the `e2e-targeted` check in [CONTROLS.md](./CONTROLS.md)): the plan's **Targeted e2e specs**, plus the smoke and accessibility specs and every spec the diff adds or edits. It records the specs and the exit code. When the plan says `full`, or the diff touches a cross-cutting path ([CONTROLS.md](./CONTROLS.md) § Cross-cutting paths), it runs `e2e-full`.
- **QA runs the full suite once** on the final commit, and on a failure re-runs it once to tell a flaky test from a real failure (a second failure is real). A plan's "passes twice in a row" check is QA's: QA runs that spec twice.

<!-- morph-init: delete this section when the project has no browser tests. -->
<!-- /module:browser-e2e -->

## Where QA can run

The process (local stack first, `deferred: local` only as the fallback, no QA writes to a shared remote environment, one local stack per session, worktree agents) is in [harness/SETUP.md](../harness/SETUP.md) § Where QA can run. The local stack's commands are in [STACK.md](./STACK.md) § Local stack (QA). This section holds what this project's environments can reach.

| Where | Local stack | Remote app database | Remote APIs and MCPs | Run "Needs live app/services" ACs? |
|-------|-------------|---------------------|----------------------|------------------------------|
<!-- morph-init: fill one row per place agents run (harness.config.yml → environment): a local CLI session, a cloud session, a hosted project thread. Say whether each can start the local stack (container runtime available?), reach the remote database (cloud proxies often carry HTTPS only), and reach the remote APIs. Example: "| Claude Code on the web | Works (the start script launches the container daemon) | Not reachable (HTTPS-only proxy) | Works | Yes, on the local stack; else `deferred: local` |". -->

<!-- morph-init: fill the seeded data QA may rely on (logins, fixtures, a second account for isolation checks) and the reset and stop commands. -->

<!-- module:data-access -->
## QA and the database

When `plan.md` marks **Data-access feature: yes** and the `data-access` module is enabled, the Technical Lead includes in the QA prompt: follow [harness/modules/data-access/README.md](../harness/modules/data-access/README.md). If the read-only remote check it needs can't authenticate, QA records it as **not run** and the feature stays not done: no pass on code review alone.
<!-- /module:data-access -->
