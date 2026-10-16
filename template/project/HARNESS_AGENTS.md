# Harness subagents: {{project.name}}

The Technical Lead delegates the **Full-stack engineer**, the **QA engineer**, the **researcher** (research mode) and, for legal wording, the **legal writer** with Claude Code's **Agent** tool. This file is the single place that states which agent, model and effort each piece of work gets.

## Agents

Subagents are defined in `.claude/agents/`. Each file sets only `model`, `effort` and, for the read-mostly roles, tool limits; the instructions are the generic role bodies in `harness/agents/` plus this project's addenda in `project/agents/`, so edit those, not the variant files. The Technical Lead never passes a model or effort: it picks the `subagent_type`.

**Tool limits.** The researcher files set `disallowedTools: Write, NotebookEdit` (it edits only the research file the Technical Lead created) and the legal writer's sets `tools: Read, Grep, Glob, Edit, Write` (no shell, web or MCP tools). Claude Code can't limit Edit to one path or Bash to read-only commands, so which file each may edit, and the researcher's read-only shell, stay rules in their role bodies. Full-stack and QA keep every tool: QA needs the shell and scratch edits for its checks. Keep these lines when adding a variant (`harness/MORPHING.md` § Trials).

| Role | `subagent_type` | Model | Effort |
|------|-----------------|-------|--------|
| Full-stack engineer | `fullstack-engineer-medium` | `{{models.fullstack_medium}}` | `medium` |
| Full-stack engineer | `fullstack-engineer` (default) | `{{models.fullstack}}` | `high` |
| Full-stack engineer | `fullstack-engineer-xhigh` | `{{models.fullstack}}` | `xhigh` |
| QA engineer | `qa-engineer-medium` | `{{models.qa_medium}}` | `medium` |
| QA engineer | `qa-engineer` (default) | `{{models.qa}}` | `high` |
| Researcher | `researcher` (default) | `{{models.researcher}}` | `medium` |
| Researcher | `researcher-high` | `{{models.researcher_high}}` | `high` |
| Legal writer | `legal-writer` | `{{models.legal}}` | `high` |

<!-- morph-init: fill the default marks from harness.config.yml → agents. Advised models: Technical Lead `opus` at `high`; Full-stack `opus` (the medium variant `sonnet`); QA `sonnet`; researcher `sonnet` (the high variant `opus`); legal writer `fable` (fallback `opus`). Change a row and its `.claude/agents/*.md` file together. Drop the legal writer row when the legal module is off. -->

Pass the absolute feature folder path (and the `plan.md` / `progress.md` paths) in the prompt. QA-fail rework goes to the same Full-stack variant as the first round.

## Technical Lead model

The Technical Lead runs in the main chat, so its model is the session's, not a file in `.claude/agents/`. `.claude/settings.json` sets `{{models.tl}}` as the project default; a person can still override it with `/model`.

**Effort:** the Technical Lead runs at `high` effort by default: it plans, reviews and decides retro items, where a miss costs a rework round. Effort is the session's (`/effort high` in a local session; the project default in a hosted one). Handing research to the researcher doesn't change this level: the Technical Lead still frames the question, checks the findings and decides. If usage gets tight, dropping the Technical Lead to `medium` on one-shot threads (a status check, a docs-only PR) is the first saving; feature threads stay at `high`.

**Rule of thumb:** the Technical Lead runs rarely, but a miss there is expensive, so it uses the strongest model. A smaller model is acceptable for the Technical Lead only on small, low-risk features, and never for work in a risk area (§ Effort per feature). When in doubt, the strongest model.

## Effort per feature

Each `plan.md` has an **Agent effort** section naming the Full-stack and QA level, with a one-line reason. The owner approves it with the plan. Effort is set explicitly so runs don't depend on each person's session default.

| Role | Min | Default | Max | Not used |
|------|-----|---------|-----|----------|
| Full-stack | `medium` | `high` | `xhigh` | `low` (too careless for shipped code), `max` (slow and costly; little gain over `xhigh` at normal feature sizes) |
| QA | `medium` | `high` | `high` | `low`; `xhigh` and above (QA works through a fixed AC list, so extra depth pays off less) |
| Researcher | `medium` | `medium` | `high` | `low`; `xhigh` and above. Set on the research file's **Researcher effort** line, not in a plan |

<!-- morph-init: fill the defaults from harness.config.yml → agents.fullstack.default and agents.qa.default if they differ from the table. -->

**Choosing a level**

- **`medium`**: a **pattern-copy plan**, one that names an existing file or feature it copies (a page, form, settings field, spec or doc) and adds no logic beyond it. Also renames, config or version bumps, and doc-heavy changes.
- **`high`** (default otherwise): normal feature work with new logic, such as a new flow, a new route or data path, or a page that doesn't follow a single existing pattern.
- **`xhigh`** (Full-stack only): security, money, tenancy and access control, concurrency, public APIs, new architecture. The Technical Lead runs the read-only code review before QA ([harness/SETUP.md](../harness/SETUP.md) § Code review before QA).
- **Never `medium` for Full-stack** when the plan touches a risk area below, even when it copies a pattern.
- **Researcher `high`** when the question is about architecture, touches a risk area, or decides a feature that will run at `xhigh`; `medium` otherwise.
- **QA is `high`** whenever the plan touches a risk area or says **Data-access feature: yes**, even if Full-stack is `medium`.

**Risk areas (never `medium`):**

<!-- morph-init: fill one bullet per entry in harness.config.yml → risk_areas, each with the paths it covers. Example:
- **Auth:** `src/auth/`, the session middleware, sign-in and sign-up pages.
- **Billing:** `src/billing/`, the payment webhook handler, plan limits.
- **Database:** migrations, access-control policies, tenancy tables.
- **Public API:** `src/api/v1/`.
-->

**Split large features by risk.** When a feature has both an `xhigh` core (tenancy guards, money, concurrency, public API, numbers users act on) and a sizeable ordinary part (pages, forms, docs), plan it as two features. The first, at `xhigh`, delivers the risky core with its tests: data layer, server handlers, shared logic. The second, at `high`, builds the UI on top of it. Each gets its own plan, QA pass and steps file. Keep one feature when the ordinary part is small, since a second QA pass then costs more than it saves.

## Trials

A trial is a model or effort change run on a fixed number of features with a KPI, decided at the next prune ([harness/SETUP.md](../harness/SETUP.md) § Prune; the rows live in `_harness/LEARNINGS.md` § Trials). Each feature's learnings file records the model with the effort on its **Cost** line, so the prune can tabulate by model.

Write each trial as one bullet: what changes, who started it, the features it covers (for example "the next three UI-only features"), the KPI per feature (QA rounds, implementation failure causes, Full-stack duration, estimated cost, tool calls), the pass rule, and the revert rule (for example "revert on the first feature that needs a second QA round from an implementation cause"). When a trial ends, say so here in one line and move the rule into § Effort per feature or drop it.

<!-- morph-init: no trials at install. Leave this comment; the first retro or prune that starts a trial adds the bullet. -->

## Legal wording

<!-- morph-init: with the legal module, keep this paragraph and fill what counts as legal wording in this project (the legal pages and their source files, consent and fine-print lines, any file that mirrors a legal page). Without it, delete the section. -->

Process: [harness/modules/legal/README.md](../harness/modules/legal/README.md). What counts as legal wording here:

- <!-- morph-init: fill, e.g. "Any text on `/terms` and `/privacy` (`src/pages/legal/`) and the values in `src/legal.ts`." -->

When unsure, the Technical Lead treats a sentence as legal.

## Browser tests

- **Full-stack runs targeted specs** before handoff (the `e2e-targeted` check in [CONTROLS.md](./CONTROLS.md)): the plan's **Targeted e2e specs**, plus the smoke and accessibility specs and every spec the diff adds or edits. It records the specs and the exit code. When the plan says `full`, or the diff touches a cross-cutting path ([CONTROLS.md](./CONTROLS.md) § Cross-cutting paths), it runs `e2e-full`.
- **QA runs the full suite once** on the final commit, and on a failure re-runs it once to tell a flaky test from a real failure (a second failure is real). A plan's "passes twice in a row" check is QA's: QA runs that spec twice.

<!-- morph-init: delete this section when the project has no browser tests. -->

## Where QA can run

Plans list the ACs that need the running app to reach its database under **QA scope → Needs live app/services** ([harness/templates/plan.md](../harness/templates/plan.md)).

**Order for "Needs live app/services" ACs:**

1. **Local stack first.** In any session that can run it, start the local stack ([STACK.md](./STACK.md) § Local stack (QA)), build and start the app against it, and test with the seeded login.
2. **`deferred: local` only as the fallback**, when the stack can't start. Record the command, its exit code and the error in `qa-result.md` as the reason.

No QA step writes to a shared remote environment: no test users, no seed data, no admin keys for a remote database.

**Agents running at the same time:**

- **One local stack per session.** Two agents that both start, stop or reset the same stack at once collide. Serialize them, or give one a scope that never touches the stack.
- **A worktree agent starts from the repository's base commit, not the feature branch.** Plan docs and earlier unmerged work are missing from that tree. Pass plan and feature-folder paths as absolute paths in the primary checkout, tell the agent to leave its work uncommitted, and commit and merge its branch back before handing to QA. Work that builds on unmerged feature-branch code runs in the primary checkout instead, with no other agent editing.

| Where | Local stack | Remote app database | Remote APIs and MCPs | Run "Needs live app/services" ACs? |
|-------|-------------|---------------------|----------------------|------------------------------|
<!-- morph-init: fill one row per place agents run (harness.config.yml → environment): a local CLI session, a cloud session, a hosted project thread. Say whether each can start the local stack (container runtime available?), reach the remote database (cloud proxies often carry HTTPS only), and reach the remote APIs. Example: "| Claude Code on the web | Works (the start script launches the container daemon) | Not reachable (HTTPS-only proxy) | Works | Yes, on the local stack; else `deferred: local` |". -->

<!-- morph-init: fill the seeded data QA may rely on (logins, fixtures, a second account for isolation checks) and the reset and stop commands. -->

Deferred ACs go into the feature's steps file ([harness/HANDOFFS.md](../harness/HANDOFFS.md) § Steps file). The owner runs them, or asks the Technical Lead to run the QA agent from a local session.

## QA and the database

When `plan.md` marks **Data-access feature: yes** and the `data-access` module is enabled, the Technical Lead includes in the QA prompt: follow [harness/modules/data-access/README.md](../harness/modules/data-access/README.md). If the read-only remote check it needs can't authenticate, QA records it as **not run** and the feature stays not done: no pass on code review alone.
