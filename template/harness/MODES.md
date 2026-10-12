# Harness modes

## Full harness

**Use when**

- New user-facing or API behavior
- Cross-cutting changes (auth, payments, data model, a public API or SDK, anything in `risk_areas`)
- Work that needs acceptance criteria and a QA record
- Anything you want auditable under `_harness/features/`

**Process**

1. Create the feature folder under `_harness/features/<slug>/<version>/`.
2. Technical Lead → Full-stack engineer → QA engineer per [STRATEGY.md](./STRATEGY.md) and [SETUP.md](./SETUP.md).
3. Run the checks from [CONTROLS.md](./CONTROLS.md) before each handoff.
4. Retro and learnings file at the end ([SETUP.md](./SETUP.md) § Retrospective).

## Light mode

**Use when**

- Documentation-only edits
- Typos, comments, non-behavioral config
- A dependency bump with obvious, fast verification
- Exploratory spikes the human did not request as a formal feature
- Applying an approved prune or a small approved retro item to harness docs

**Process**

- Single agent in the main session, explicitly assigned as implementer. The Technical Lead still never writes application code: a light-mode code change goes to the Full-stack subagent.
- No `_harness/` feature folder required, no retro.
- Still run the applicable named checks if the change touches code ([CONTROLS.md](./CONTROLS.md)).

**Default:** if unsure, use the **full harness**. Light mode is the exception.

## Choosing mode (Technical Lead)

| Signal | Mode |
|--------|------|
| Human says "use harness" or "feature X" | Full |
| Touches security, money, persisted user data or a risk area | Full |
| One file, obvious diff, human says "quick fix" | Light |
| Needs acceptance criteria for sign-off | Full |
| Harness or project docs only | Light |
