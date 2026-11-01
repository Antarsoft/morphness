# Harness

For non-trivial features, follow the generic harness in `harness/` and `AGENTS.md`.

**Technical Lead hard limits:** [TECHNICAL_LEAD.md](../../harness/TECHNICAL_LEAD.md): no app code, no QA; "execute/implement/develop" always means Agent → Full-stack.

- **Technical Lead (main chat):** plan in `_harness/features/.../Plan/plan.md`; the human's steps in the feature's **steps file** after QA pass (with the `roadmap` module: `docs/versions/<id>/steps/<slug>.md`); **no application code, no QA, no `progress.md` / `qa-result.md` edits.** Acceptance criteria must be testable. After dev handoff, **must** delegate to QA before telling the human the feature is done.
- **Subagents:** delegate with the Agent tool. Model and effort live in each `.claude/agents/*.md` file; the plan's **Agent effort** section picks the variant (for example `fullstack-engineer-xhigh`; every variant, trials included, is listed in `project/HARNESS_AGENTS.md` § Agents). Subagents load neither this file nor `CLAUDE.md`: their rules are in their role bodies, `harness/agents/<role>.md` and `project/agents/<role>.md`, so a rule for a subagent goes there.
- **Bug mode:** bug reports get the short bug plan; QA writes the failing test before any fix, Full-stack records the root cause before fixing ([harness/MODES.md](../../harness/MODES.md) § Bug mode).
- **Small mode (default for a clear request):** a fully specified change in a few named files that passes every test in that section gets the short small plan and the same three agents ([harness/MODES.md](../../harness/MODES.md) § Small mode).
- **Light mode:** small fixes may skip `_harness/` (see `harness/MODES.md`). Light mode still does **not** allow the TL to write app code; use Full-stack or a single agent explicitly assigned as implementer (not the TL).
- **Long output:** any command that can print a lot (tests, builds, installs, `git log`, `find`) goes to a log file or through `head`/`tail`; print the exit code and the last lines only ([harness/CONTROLS.md](../../harness/CONTROLS.md) § Command output). Everything printed is re-read on every later turn.

Read `project/STACK.md`, `harness/CONTROLS.md` and `project/CONTROLS.md` for checks.
