# Harness

For non-trivial features, follow the generic harness in `harness/` and `AGENTS.md`.

**Technical Lead hard limits:** [TECHNICAL_LEAD.md](../../harness/TECHNICAL_LEAD.md): no app code, no QA; "execute/implement/develop" always means Agent → Full-stack.

- **Technical Lead (main chat):** plan in `_harness/features/.../Plan/plan.md`; the human's steps in the feature's **steps file** after QA pass (with the `roadmap` module: `docs/versions/<id>/steps/<slug>.md`); **no application code, no QA, no `progress.md` / `qa-result.md` edits.** Acceptance criteria must be testable. After dev handoff, **must** delegate to QA before telling the human the feature is done.
- **Full-stack subagent:** implement per approved plan; outside application code, **only** edit `Development/progress.md` in that feature folder. Add or update **meaningful** tests (see `.claude/rules/testing.md`). Before handoff: run every `before_qa` check ([harness/CONTROLS.md](../../harness/CONTROLS.md) § Before Full-stack → QA handoff; commands in `project/CONTROLS.md`) to exit 0, narrowed or skipped only as CONTROLS § Scoping by what changed allows; record in the `progress.md` validation section.
- **QA subagent:** **mandatory** after each dev-complete `progress.md`; validate acceptance criteria; for **data-access plans** (migrations, access policies, tenant isolation) follow [harness/modules/data-access/README.md](../../harness/modules/data-access/README.md) when that module is enabled; **only** edit `QA/qa-result.md`; no product code changes (the one exception is bug mode's regression test, below).
- **Subagents:** delegate with the Agent tool. Model and effort live in each `.claude/agents/*.md` file; the role body is `harness/agents/<role>.md` plus `project/agents/<role>.md`. The plan's **Agent effort** section picks the variant (for example `fullstack-engineer-xhigh`; every variant, trials included, is listed in `project/HARNESS_AGENTS.md` § Agents). See `project/HARNESS_AGENTS.md`.
- **Researcher subagent:** research mode and optional research before a plan ([harness/MODES.md](../../harness/MODES.md) § Research mode); read-only, cites every claim, **only** edits its research file between the two lines; never decides (the TL checks and records it).
- **Bug mode:** bug reports get the short bug plan; QA writes the failing test before any fix, Full-stack records the root cause before fixing ([harness/MODES.md](../../harness/MODES.md) § Bug mode).
- **Mode** ([harness/MODES.md](../../harness/MODES.md) § Choosing mode, first match wins): question → research; reported breakage → bug; any other change → `bash scripts/risk-check.sh <files>`: `full` → full mode, `plain` → light with no behaviour change, else small. Never judge risk by eye; wording never lowers the mode.
- **Light mode:** no `_harness/` folder, no QA. The TL edits documentation outside application code; application code goes to Full-stack with the light brief.
- **Long output:** any command that can print a lot (tests, builds, installs, `git log`, `find`) goes to a log file or through `head`/`tail`; print the exit code and the last lines only ([harness/CONTROLS.md](../../harness/CONTROLS.md) § Command output). Everything printed is re-read on every later turn.

Read `project/STACK.md`, `harness/CONTROLS.md` and `project/CONTROLS.md` for checks.
