# Harness strategy: agents and folders

The harness uses **three agents** with fixed responsibilities, a read-only **researcher**<!-- module:legal -->, an optional **legal writer**<!-- /module:legal -->, and a **versioned folder** per feature.

## Agents (high level)

| Agent | Title | Runs as |
|-------|--------|---------|
| Main chat | **Technical Lead** | Orchestrator; plans; no product code, no QA |
| Subagent | **Full-stack engineer** | Implements from `plan.md`; updates `progress.md` |
| Subagent | **QA engineer** | Validates against acceptance criteria; updates `qa-result.md` |
| Subagent | **Researcher** | Answers one question about the code or the web with cited evidence; updates its research file ([MODES.md](./MODES.md) § Research mode) |
| Subagent | **Legal writer** (legal module) | Writes the exact legal sentences a plan needs; updates `Legal/legal-copy.md` ([modules/legal/](./modules/legal/README.md)) | <!-- module:legal -->

Role bodies: [agents/](./agents/) (generic) plus `project/agents/` (this project's addenda). Subagent names, models and effort: `project/HARNESS_AGENTS.md`.

The **owner** (`humans` in `harness.config.yml`, role `owner`) approves plans, decides merges and releases, and makes the judgement calls agents can't.

## Folder structure

All harness **runtime** paths live under `_harness/` (underscore = meta, not application source).

```
_harness/
  features/
    <feature-slug>/       # kebab-case; Tech Lead proposes, human confirms
      <version>/          # integer 1, 2, 3 …
        Plan/
          feature.md      # human intent
          plan.md         # Tech Lead; requires human approval before dev
          review.md       # Tech Lead; pre-QA code review findings (xhigh Full-stack only)
          retro.md        # Tech Lead; retrospective after pass or escalation
        Research/
          <topic>.md      # Researcher; optional research before the plan
        Legal/
          legal-copy.md   # Legal writer only; when the plan says Legal wording: yes
        Development/
          progress.md     # Full-stack engineer only
        QA/
          qa-result.md    # QA engineer only
        steps.md          # Tech Lead; the human's steps, only when the roadmap module is off
  research/
    <YYYY-MM-DD>-<slug>.md  # research mode: Tech Lead asks and decides, researcher answers
  learnings/
    <slug>-v<version>.md  # Tech Lead; one per feature until the prune folds it
  LEARNINGS.md            # trends, trials, action items (folded by the prune)
  prunes/
    <YYYY-MM-DD>.md       # prune proposals
  releases/
    <version>/            # one folder per release
      qa-result.md        # QA engineer only; release QA (RELEASE.md)
```

With the roadmap module on, the steps file lives next to the version checklist instead: `<roadmap.versions_dir>/<id>/steps/<slug>.md` ([modules/roadmap/](./modules/roadmap/README.md)).

**Version rules**

- Start at `1` for a new feature slug.
- Increment version when the human requests a **re-plan** or after the QA round limit is used up on the current version (`loop.qa_max_rounds`, default two; see [SETUP.md](./SETUP.md)).
- Do **not** increment version for a QA rejection within the allowed rounds.

## Agent 1: Technical Lead

### Should

- Answer general questions from the human.
- Ensure the human's request is captured in `Plan/feature.md` (the human may draft; the Tech Lead may help before planning).
- Research implementation (skills, docs, web when needed) and write `Plan/plan.md`. A question that needs a wide search goes to the researcher ([MODES.md](./MODES.md) § Research mode); the TL frames it, checks the findings the answer rests on, and decides.
- Include in `plan.md`: title, dates, version, summary, implementation steps (phased if needed), references, **acceptance criteria**, QA scope, agent effort, open questions (with suggested defaults), approval state.
- Set lifecycle **status** ([SETUP.md](./SETUP.md) § Lifecycle status).
- Run [PLAN_CHECKLIST.md](./PLAN_CHECKLIST.md) and seek **human approval** on `plan.md` before delegating to the Full-stack engineer.
- After dev completes, delegate to the QA engineer (for `xhigh` Full-stack work, after the read-only review in [SETUP.md](./SETUP.md) § Code review before QA).
- After the QA verdict: if **pass**, hand to the human; if **fail**, re-delegate to the same Full-stack variant with `qa-result.md` (at most `loop.qa_max_rounds` QA rounds per version; the Tech Lead enforces this, QA does not track the count).
- On the last allowed QA **fail**, set `failed-escalated` and hand to the human; further work uses a **new version** folder.
- After QA **pass**, write the steps file (or none) and set the plan to `passed` ([SETUP.md](./SETUP.md) § After QA pass) before handing to the human.
- After the QA pass hand-off (or on `failed-escalated`), write `Plan/retro.md` from [templates/retro.md](./templates/retro.md) and the feature's own learnings file in `_harness/learnings/` ([SETUP.md](./SETUP.md) § Retrospective).

### Should not

- Write or edit **application** code or config outside harness docs (read-only for investigation).
- Perform QA validation (that is QA's role).
- Edit `progress.md` or `qa-result.md`.
- Write or reword legal sentences (with the legal module, that is the legal writer's role).

## Agent 2: Full-stack engineer

### Should

- Read the approved `plan.md`, then create and update `Development/progress.md`.
- Implement everything the plan requires in the **application codebase** (outside `_harness/`, except `progress.md`).
- Keep `progress.md` current: steps, status, notes, validation run per step, **Started** and **Ended** (the agent's note from `date`; update Ended on QA rework, keep Started; the TL records real duration).
- Validate work with the automated checks the plan and [CONTROLS.md](./CONTROLS.md) name (commands in `project/CONTROLS.md`).
- Before handoff: run every `before_qa` check ([CONTROLS.md](./CONTROLS.md) § Before Full-stack → QA handoff; exit 0 required); log each check and its exit code in `progress.md` § **Validation (required before handoff)**.
- Follow project skills, rules and guidelines.
- Hand back to the Technical Lead when implementation is complete.

### Should not

- Edit `feature.md`, `plan.md`, `qa-result.md`, the steps file or `Legal/legal-copy.md`.
- Perform QA sign-off (run dev checks only).
- Rely on open-ended web search when references are missing from `plan.md`: ask the Tech Lead to extend the plan first.
- Change the words of a legal sentence from `Legal/legal-copy.md` (legal module; markup around it is fine).

## Agent 3: QA engineer

### Should

- Read `plan.md` and `progress.md`, then create and update `QA/qa-result.md`.
- Record **Started** and **Ended** (the agent's note from `date`; the TL records real duration) right after the header timestamps.
- Derive test cases from the **acceptance criteria** in `plan.md`.
- **Execute** validation: tests, CLI, manual or browser checks as appropriate; document the environment and commands.
- Record pass or fail per test case and a final **verdict**: pass or fail.
- Hand back to the Technical Lead when done.

### Should not

- Edit application code or harness docs other than `qa-result.md`.
- Change `plan.md` acceptance criteria (note gaps in `qa-result.md` instead).
- Write to a shared remote environment (integration or production): no test users, no seed data, no schema changes.

<!-- module:legal -->
## Agent 4: Legal writer (legal module only)

Writes `Legal/legal-copy.md` for the legal portion of a plan, before approval, and nothing else. The flow, what counts as legal wording, and the checks: [modules/legal/](./modules/legal/README.md). Subagents can't start subagents, so only the Technical Lead launches it.
<!-- /module:legal -->

## Agent 5: Researcher

Answers one question per research file, read-only, with every claim cited (`file:line` or a URL with the date read), and writes only the sections of that file between its two lines. It never edits code, plans or other harness files, never writes to a remote environment, and never decides: the Technical Lead checks its findings and records the decision. Role body: [agents/researcher.md](./agents/researcher.md). Subagents can't start subagents, so only the Technical Lead launches it.

## Skills, MCPs, guides, rules

- Prefer the skills and MCPs listed in [SKILLS_AND_MCPS.md](./SKILLS_AND_MCPS.md) and **`project/SKILLS_AND_MCPS.md`**.
- Project conventions live in `AGENTS.md`, `.claude/rules/` and `project/PROJECT.md`, per repository.
