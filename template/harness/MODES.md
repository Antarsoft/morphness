# Harness modes

## Working alone (plain changes)

When `bash scripts/risk-check.sh` prints `Mode: plain`, the main chat makes the change itself: no Full-stack or QA subagent. That is light mode and small mode below. Full-stack and QA run only in full and bug mode (learned: on everyday changes the hand-offs between agents cost more than the work, and the risk check already sends risky ones to full mode).

Working alone, the main chat follows the builder's rules as well as its own:

- Before the first edit, read `harness/agents/fullstack-engineer.md` § Do, § UI screenshots and § Before handoff, and `project/agents/fullstack-engineer.md` (this project's builder rules). Tests follow `.claude/rules/testing.md`. Where those sections say `progress.md`, write the PR record (light mode) or the plan's § Check (small mode); § Ownership limits and § Hand back are for the subagent.
- With **UI change: yes**, also follow `harness/agents/qa-engineer.md` on screenshots and the layout pass (open each after-shot; check every page at the narrowest width when styles or a shared component change). With **Needs live app/services**, its rules for the local stack and `deferred: local` apply, and `project/CONTROLS.md` § Manual smoke when it has rows.
- Same branch, commit and PR rules as any feature (`AGENTS.md` § Golden rules), and the same guard hook: a deny is final.
- The `before_qa` checks after the change, scoped by what changed; then, for small mode, the `before_signoff` checks once in full on the final commit ([CONTROLS.md](./CONTROLS.md)). A check the environment refused is **not run**, never a pass.
- Before the hand-off, run `bash scripts/risk-check.sh` again with no files (§ Choosing mode, step 4). When it prints `Mode: full`, stop: write a full plan with this change linked, and the agents take it from there.

## Full harness

**Use when** `bash scripts/risk-check.sh` prints `Mode: full` for the change (it touches a risk path in `project/CONTROLS.md` § Risk paths, deletes stored data, or changes more files than `mode.plain_max_files`), when the Technical Lead raises a plain change to full because the request leaves a real product choice open, or when the owner asks for full mode (§ Choosing mode).

**Process**

1. Create the feature folder under `_harness/features/<slug>/<version>/`.
2. Technical Lead → Full-stack engineer → QA engineer per [STRATEGY.md](./STRATEGY.md) and [SETUP.md](./SETUP.md).
3. Run the checks from [CONTROLS.md](./CONTROLS.md) before each handoff.
4. Retro and learnings file at the end ([SETUP.md](./SETUP.md) § Retrospective).

## Light mode

**Use when** the risk check prints `Mode: plain` and the change alters no behaviour: documentation, comments, formatting, config that changes nothing at run time, a dependency bump whose named checks pass, or an approved prune or small retro item applied to harness docs. A change a user can see (copy, layout) or that changes what the code does is small mode or higher, however small.

**Process**

- The main chat makes the change itself (§ Working alone), application code included. The owner's request is the approval; there is no plan to approve.
- No `_harness/` feature folder required, no QA agent, no retro: the named checks are the only verification.
- When the change turns out to alter behaviour or to need a test of its own, stop before going further: it is small mode, with a plan the human approves.
- Still run the applicable named checks if the change touches code ([CONTROLS.md](./CONTROLS.md)): the `before_qa` checks, scoped by what changed. The record is the PR (or the commit message with no PR): the checks run with their exit codes, under a **Light mode** line saying why the change qualified.
- With `cost.track` on, the closing message ends with the `Cost ≈ $…` line from `bash scripts/feature-cost.sh` (with `--since <time the task started>` when the session did other work first). It goes in the message only; light mode writes no file for it.

## Small mode

**Use it when** the risk check prints `Mode: plain` for the files the change will touch and the change alters behaviour (a flag, a field, a format, a message, a sort order, a limit, pagination). The script, not a reading of the request, decides: a change to a risk path is full mode however small, and a change off them is small mode however it is worded. A bug is bug mode.

**Process**

The main chat plans, builds and checks the change itself (§ Working alone); the plan and the merge gate stay (learned: on small, fully specified changes, full mode cost many times a plain session for the same result).

1. **Plan.** Read the code the change touches, then write `_harness/features/<slug>/<version>/Plan/plan.md` from [templates/small-plan.md](./templates/small-plan.md): the risk check's output, the change, the files, 3 to 8 acceptance criteria with their tests, and the limit. No `feature.md` and no plan checklist run. The human approves it as any plan.
2. **Build.** Make the change and write the tests the criteria name, then run the `before_qa` checks. A change that needs more than § Limit allows stops before the change: write a full plan with this one linked.
3. **Check.** On the final commit, run the `before_signoff` checks in full and fill the plan's § Check: each check with its exit code, and each criterion with the test or output that shows it holds. A criterion nothing shows is not met: fix it or stop and tell the human. No `progress.md` or `qa-result.md`.
4. **Close.** § After QA pass as in full mode, with § Check in place of the QA verdict. No `retro.md`: the learnings file has the verdict and cost lines and **Retro:** `none (small mode)`, with an action item only when something went wrong. It counts toward the prune counter, so the prune sees whether small mode lets problems through.

## Bug mode

**Use when**

- Something that worked, or that an AC, the docs or the product promise, is broken: a bug report, an error in production, "this used to work", and the human wants it fixed
- A production bug that can't wait for the next release: bug mode on a hotfix branch ([RELEASE.md](./RELEASE.md) § Hotfix)

Not for wrong copy or a typo that nobody reported as broken (small or light mode, § Choosing mode), for new behaviour that fixes nothing (full), or for "why does this happen?" with no fix asked yet (research, then bug mode if it is one).

**Process**

The three agents and the merge gate stay as in full mode; what changes is the order and the plan. The test that proves the bug comes before any fix, the cause is written down before the code changes, and the fix is the smallest one that makes the test pass.

1. **Plan (Technical Lead).** When production is broken right now, first tell the human whether a rollback ([RELEASE.md](./RELEASE.md) § Rollback, theirs to run) would stop the damage while the fix is made. Create the feature folder `_harness/features/<slug>/<version>/` and write `Plan/plan.md` from [templates/bug-plan.md](./templates/bug-plan.md) (it replaces `feature.md` and the full plan): the symptom, where it was seen, what should happen and the source that says so, the reproduction steps, the code path the TL read itself, the regression test QA writes, the fix limit, and the branch (the integration branch, or a hotfix). Run the pre-approval checklist as in full mode: § Planning and scope always (item 5, reproduce and read, is the heart of a bug plan), other groups only when the fix area needs them, the rest as one "n/a" line per group. The human approves the plan, including the branch; a hotfix is never the TL's call alone.
2. **Reproduce (QA).** The Technical Lead launches QA with the bug-reproduction brief ([HANDOFFS.md](./HANDOFFS.md) § Subagent prompt blocks). QA writes the regression test the plan assigns, runs it, and records in `QA/qa-result.md` § Reproduction that it fails for the reported reason, with the failure's tail. It fixes nothing. The Technical Lead commits the test alone (`WIP(<slug>): failing test`), so the history shows it red before the fix. When QA can't reproduce it, it records what it tried; the Technical Lead takes that to the human (more detail, research mode, or close as not reproduced) and nothing gets fixed blind. This run is not a QA round.
3. **Root cause and fix (Full-stack).** The Technical Lead launches Full-stack with the bug-mode brief. Full-stack writes `Development/progress.md` § Root cause first (the `file:line`, why it happens, since when, why no test caught it, and the same pattern elsewhere with the grep and its hit count), then makes the smallest fix that turns the regression test green without editing the test, and runs the `before_qa` checks as usual. A fix that would cross the plan's **Fix limit** (new behaviour, a migration, a public API change, a risk area the plan doesn't name, files beyond the plan) stops before the change and hands back: the Technical Lead re-plans (a full plan, with the bug plan linked) and asks the human. The Technical Lead checks § Root cause against the code (`file:line`) before QA, like any subagent finding ([SETUP.md](./SETUP.md) § Findings from a review subagent).<!-- module:security --> With the `security` module, a fix that changes who can sign in or read or change data, moves money, handles secrets or deletes or shares people's data gets the security review before QA whatever the effort ([modules/security/](./modules/security/README.md) § Security review before QA).<!-- /module:security -->
4. **Re-run (QA).** The normal QA pass on the bug plan's ACs: the regression test, unchanged since the failing-test commit, now passes; the reproduction steps no longer show the symptom; each same-pattern place is fixed or out of scope with a reason; and the `before_signoff` checks. QA rounds, rework and escalation are as in full mode. The failing-test commit is the negative run [testing.md](../.claude/rules/testing.md) asks for.
5. **After QA pass.** [SETUP.md](./SETUP.md) § After QA pass as in full mode: the steps file (for a hotfix, at least the check in production after the merge), the PR marked ready. On a hotfix branch, the rest is [RELEASE.md](./RELEASE.md) § Hotfix: the `Hotfix vX.Y.Z` title, the tag, and bringing the fix back into the integration branch.
6. **Retro line (Technical Lead).** No `retro.md`. The learnings file `_harness/learnings/<slug>-v<version>.md` ([templates/learnings-entry.md](./templates/learnings-entry.md)) is the look-back: the verdict and cost lines, **Escaped** (which feature let the bug through, and the AC, check or review that should have caught it, from § Root cause), **Retro:** `none (bug mode)`, and one action item for the escape: the rule, checklist item or test that would have caught it, or one line on why none would; a rule it adds ends with `(from <slug>, <date>)` ([MORPHING.md](./MORPHING.md) § Rule provenance). An escape is the one miss QA never saw, so it is the retro's best source of rules (learned: a run of clean retros added no rules while a bug of the same kind sat on a new route). The fix also checks the sibling paths for the same gap (other routes or pages that read the same data) and closes them in the same branch. The Technical Lead decides items as in § Retrospective. It counts toward the prune counter like a feature, so the prune sees what keeps escaping. The hand-off message ends with the cost and prune counter lines.

## Research mode

**Use when**

- The human wants an answer, not a change: how something in the repo works, why a bug happens, which library or service fits, what a new API version changes, how others solve a problem
- A question has to be settled before a feature can be planned, and finding the answer means reading a lot of code or the web

**Process**

1. The Technical Lead creates `_harness/research/<YYYY-MM-DD>-<slug>.md` from [templates/research.md](./templates/research.md) and writes § Question, § Scope and § Context (with the current commit), and the researcher effort ([SETUP.md](./SETUP.md) § Effort per feature).
2. The Technical Lead launches the **researcher** subagent (Agent tool, the variant for that effort) with the file's absolute path. Two independent questions (for example one about the repo and one on the web) can go to two researchers at once, each with its own file.
3. The researcher, which has no shell or edit tools, replies with the findings, recommendation and sources; the Technical Lead pastes the reply's sections, unchanged, between the file's two lines.
4. The Technical Lead re-opens the sources behind the findings the recommendation depends on (§ Check), then records § Decision: a feature to plan (in full mode, with the research file linked from `plan.md` § References), a light-mode change, or no action. Decisions that change product behaviour, add a step for the human or cost money are the human's. With the decision it fills the three § How it went lines: whether the check held, whether the scope and researcher effort were right, and whether the answer got used, and the header's **Cost** line from `bash scripts/feature-cost.sh` (with `--since` when the session did other work first).
5. The research file is committed like a light-mode docs change, or on the feature branch when it leads to a plan. Files that end in `no action` are kept: they record what was checked.

No application code changes, no QA, no retro, and research files don't count toward the prune counter: a full retro would have little to look back on, and research doesn't change how features are built. § How it went is the look-back instead; the prune reads it across research files and proposes tweaks ([SETUP.md](./SETUP.md) § Prune).

**Research before a plan.** In full mode the Technical Lead may launch the researcher before planning, for a large codebase sweep or an unfamiliar API; the file then lives at `<feature>/<version>/Research/<topic>.md` and `plan.md` § References links it. It is optional: small features don't wait on it. The Technical Lead still reads the exact files and functions the plan changes itself, because the plan's detail is what prevents rework.

## Choosing mode (Technical Lead)

The first match wins. The human's wording ("quick fix", "ship it fast", "no time for QA") never changes the mode; only the owner choosing one does ("use full mode", "run it plain"), passed to the script as `--force full` or `--force plain`, or set for every change in `harness.config.yml` → `mode.force`.

1. **A question, no change asked** ("how does", "why does", "which should we use", "compare") → research mode. A question one or two files the Technical Lead reads anyway can answer gets a direct answer, with no research file.
2. **Something that worked is broken and a fix is asked** ("bug", "broken", "error in production", "this used to work") → bug mode, on a hotfix branch when it can't wait for the next release. A bug fix that touches a risk path never runs Full-stack at `medium`.
3. **Any other change:** name the files it will touch and run `bash scripts/risk-check.sh <files>`. `Mode: full` → full mode. `Mode: plain` → light mode when the change alters no behaviour (§ Light mode), small mode otherwise. When the owner forced plain and the script still names a risk path, the change runs alone too, with no QA agent (§ Working alone): forcing plain is the owner's choice to go without the agents, so say so in the plan or the PR record. The Technical Lead may raise plain to full when the request leaves a real product choice open, naming the choice; it never lowers full to plain. The script's output goes in the small plan's § Why small, or in a light change's PR or commit record.
4. **Before the hand-off** of a small or light change, run `bash scripts/risk-check.sh` again with no files: it reads what the branch really changed. When it now prints `Mode: full`, stop and switch to full mode (a plan, with the first one linked, and QA) before anything is handed off.
