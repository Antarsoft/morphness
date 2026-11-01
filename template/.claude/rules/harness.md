# Harness

For non-trivial features, follow the generic harness in `harness/` and `AGENTS.md`.

- **Technical Lead (main chat), full and bug mode** ([TECHNICAL_LEAD.md](../../harness/TECHNICAL_LEAD.md)): plan in `_harness/features/.../Plan/plan.md`; the human's steps in the feature's **steps file** after QA pass (with the `roadmap` module: `docs/versions/<id>/steps/<slug>.md`); **no application code, no QA, no `progress.md` / `qa-result.md` edits.** Acceptance criteria must be testable. After dev handoff, **must** delegate to QA before telling the human the feature is done.
- **Subagents:** delegate with the Agent tool. Model and effort live in each `.claude/agents/*.md` file; the plan's **Agent effort** section picks the variant (for example `fullstack-engineer-xhigh`; every variant, trials included, is listed in `project/HARNESS_AGENTS.md` § Agents). Subagents load neither this file nor `CLAUDE.md`: their rules are in their role bodies, `harness/agents/<role>.md` and `project/agents/<role>.md`, so a rule for a subagent goes there.
- **Bug mode:** bug reports get the short bug plan; QA writes the failing test before any fix, Full-stack records the root cause before fixing ([harness/MODES.md](../../harness/MODES.md) § Bug mode).
- **Mode** ([harness/MODES.md](../../harness/MODES.md) § Choosing mode, first match wins): question → research; breakage → bug; other changes → `bash scripts/risk-check.sh <files>`: `full` → full mode, `plain` → light if no behaviour changes, else small. Never judge risk by eye; wording never lowers the mode.
- **Light and small mode:** no subagent; you make the change and run the checks (MODES.md § Working alone).
- **Long output:** any command that can print a lot (tests, builds, installs, `git log`, `find`) goes to a log file or through `head`/`tail`; print the exit code and the last lines only ([harness/CONTROLS.md](../../harness/CONTROLS.md) § Command output). Everything printed is re-read on every later turn.

Read `project/STACK.md`, `harness/CONTROLS.md` and `project/CONTROLS.md` for checks.
