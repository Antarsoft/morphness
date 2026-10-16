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

- Single agent in the main session, explicitly assigned as implementer. The Technical Lead still never writes application code: a light-mode code change goes to the Full-stack subagent with the light brief in [HANDOFFS.md](./HANDOFFS.md) § Subagent prompt blocks, which replaces `plan.md`.
- No `_harness/` feature folder required, no QA agent, no retro.
- Still run the applicable named checks if the change touches code ([CONTROLS.md](./CONTROLS.md)): the `before_qa` checks, scoped by what changed. The record is the PR (or the commit message with no PR): the checks run with their exit codes, under a **Light mode** line saying why the change qualified.
- With `cost.track` on, the closing message ends with the `Cost ≈ $…` line from `bash scripts/feature-cost.sh` (with `--since <time the task started>` when the session did other work first). It goes in the message only; light mode writes no file for it.

## Research mode

**Use when**

- The human wants an answer, not a change: how something in the repo works, why a bug happens, which library or service fits, what a new API version changes, how others solve a problem
- A question has to be settled before a feature can be planned, and finding the answer means reading a lot of code or the web

**Process**

1. The Technical Lead creates `_harness/research/<YYYY-MM-DD>-<slug>.md` from [templates/research.md](./templates/research.md) and writes § Question, § Scope and § Context, and the researcher effort ([SETUP.md](./SETUP.md) § Effort per feature).
2. The Technical Lead launches the **researcher** subagent (Agent tool, the variant for that effort) with the file's absolute path. Two independent questions (for example one about the repo and one on the web) can go to two researchers at once, each with its own file.
3. The researcher, read-only, fills the findings, recommendation and sources, and hands back.
4. The Technical Lead re-opens the sources behind the findings the recommendation depends on (§ Check), then records § Decision: a feature to plan (in full mode, with the research file linked from `plan.md` § References), a light-mode change, or no action. Decisions that change product behaviour, add a step for the human or cost money are the human's. With the decision it fills the three § How it went lines: whether the check held, whether the scope and researcher effort were right, and whether the answer got used, and the header's **Cost** line from `bash scripts/feature-cost.sh` (with `--since` when the session did other work first).
5. The research file is committed like a light-mode docs change, or on the feature branch when it leads to a plan. Files that end in `no action` are kept: they record what was checked.

No application code changes, no QA, no retro, and research files don't count toward the prune counter: a full retro would have little to look back on, and research doesn't change how features are built. § How it went is the look-back instead; the prune reads it across research files and proposes tweaks ([SETUP.md](./SETUP.md) § Prune).

**Research before a plan.** In full mode the Technical Lead may launch the researcher before planning, for a large codebase sweep or an unfamiliar API; the file then lives at `<feature>/<version>/Research/<topic>.md` and `plan.md` § References links it. It is optional: small features don't wait on it. The Technical Lead still reads the exact files and functions the plan changes itself, because the plan's detail is what prevents rework.

**Default:** if unsure, use the **full harness**. Light mode is the exception.

## Choosing mode (Technical Lead)

| Signal | Mode |
|--------|------|
| Human says "use harness" or "feature X" | Full |
| Touches security, money, persisted user data or a risk area | Full |
| One file, obvious diff, human says "quick fix" | Light |
| Needs acceptance criteria for sign-off | Full |
| Harness or project docs only | Light |
| Human asks a question ("how does", "why does", "which should we use", "research", "compare") and no change yet | Research |
| A plan can't be written until a question is answered | Research first (or research before the plan), then Full |
