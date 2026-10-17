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

## Bug mode

**Use when**

- Something that worked, or that an AC, the docs or the product promise, is broken: a bug report, an error in production, "this used to work", and the human wants it fixed
- A production bug that can't wait for the next release: bug mode on a hotfix branch ([RELEASE.md](./RELEASE.md) § Hotfix)

Not for a typo or wrong copy with an obvious one-line fix (light mode), for new behaviour that fixes nothing (full), or for "why does this happen?" with no fix asked yet (research, then bug mode if it is one).

**Process**

The three agents and the merge gate stay as in full mode; what changes is the order and the plan. The test that proves the bug comes before any fix, the cause is written down before the code changes, and the fix is the smallest one that makes the test pass.

1. **Plan (Technical Lead).** When production is broken right now, first tell the human whether a rollback ([RELEASE.md](./RELEASE.md) § Rollback, theirs to run) would stop the damage while the fix is made. Create the feature folder `_harness/features/<slug>/<version>/` and write `Plan/plan.md` from [templates/bug-plan.md](./templates/bug-plan.md) (it replaces `feature.md` and the full plan): the symptom, where it was seen, what should happen and the source that says so, the reproduction steps, the code path the TL read itself, the regression test QA writes, the fix limit, and the branch (the integration branch, or a hotfix). Run the pre-approval checklist as in full mode: § Planning and scope always (item 5, reproduce and read, is the heart of a bug plan), other groups only when the fix area needs them, the rest as one "n/a" line per group. The human approves the plan, including the branch; a hotfix is never the TL's call alone.
2. **Reproduce (QA).** The Technical Lead launches QA with the bug-reproduction brief ([HANDOFFS.md](./HANDOFFS.md) § Subagent prompt blocks). QA writes the regression test the plan assigns, runs it, and records in `QA/qa-result.md` § Reproduction that it fails for the reported reason, with the failure's tail. It fixes nothing. The Technical Lead commits the test alone (`WIP(<slug>): failing test`), so the history shows it red before the fix. When QA can't reproduce it, it records what it tried; the Technical Lead takes that to the human (more detail, research mode, or close as not reproduced) and nothing gets fixed blind. This run is not a QA round.
3. **Root cause and fix (Full-stack).** The Technical Lead launches Full-stack with the bug-mode brief. Full-stack writes `Development/progress.md` § Root cause first (the `file:line`, why it happens, since when, why no test caught it, and the same pattern elsewhere with the grep and its hit count), then makes the smallest fix that turns the regression test green without editing the test, and runs the `before_qa` checks as usual. A fix that would cross the plan's **Fix limit** (new behaviour, a migration, a public API change, a risk area the plan doesn't name, files beyond the plan) stops before the change and hands back: the Technical Lead re-plans (a full plan, with the bug plan linked) and asks the human. The Technical Lead checks § Root cause against the code (`file:line`) before QA, like any subagent finding ([SETUP.md](./SETUP.md) § Findings from a review subagent).
4. **Re-run (QA).** The normal QA pass on the bug plan's ACs: the regression test, unchanged since the failing-test commit, now passes; the reproduction steps no longer show the symptom; each same-pattern place is fixed or out of scope with a reason; and the `before_signoff` checks. QA rounds, rework and escalation are as in full mode. The failing-test commit is the negative run [testing.md](../.claude/rules/testing.md) asks for.
5. **After QA pass.** [SETUP.md](./SETUP.md) § After QA pass as in full mode: the steps file (for a hotfix, at least the check in production after the merge), the PR marked ready. On a hotfix branch, the rest is [RELEASE.md](./RELEASE.md) § Hotfix: the `Hotfix vX.Y.Z` title, the tag, and bringing the fix back into the integration branch.
6. **Retro line (Technical Lead).** No `retro.md`. The learnings file `_harness/learnings/<slug>-v<version>.md` ([templates/learnings-entry.md](./templates/learnings-entry.md)) is the look-back: the verdict and cost lines, **Escaped** (which feature let the bug through, and the AC, check or review that should have caught it, from § Root cause), **Retro:** `none (bug mode)`, and an action item only when the escape points at a gap a rule, a checklist item or a test would close. The Technical Lead decides items as in § Retrospective. It counts toward the prune counter like a feature, so the prune sees what keeps escaping. The hand-off message ends with the cost and prune counter lines.

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
| Something that worked is broken ("bug", "broken", "error in production", "this used to work") and the human wants it fixed | Bug |
| A production bug that can't wait for the next release | Bug, on a hotfix branch |
| Needs acceptance criteria for sign-off | Full |
| Harness or project docs only | Light |
| Human asks a question ("how does", "why does", "which should we use", "research", "compare") and no change yet | Research |
| A plan can't be written until a question is answered | Research first (or research before the plan), then Full |
