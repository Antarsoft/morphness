# Harness strategy: agents and folders

The harness uses **three agents** with fixed responsibilities, a read-only **researcher**, a **code scout** that writes one map file, a **feature closer** for the closing records<!-- module:legal -->, an optional **legal writer**<!-- /module:legal -->, and a **versioned folder** per feature.

## Agents (high level)

| Agent | Title | Runs as |
|-------|--------|---------|
| Main chat | **Technical Lead** | Orchestrator; plans; in full and bug mode no product code, no QA; builds and checks light and small changes itself |
| Subagent | **Full-stack engineer** | Implements from `plan.md`; updates `progress.md` |
| Subagent | **QA engineer** | Validates against acceptance criteria; updates `qa-result.md` |
| Subagent | **Researcher** | Answers one question about the code or the web with cited evidence, in a reply the Technical Lead writes into the research file ([MODES.md](./MODES.md) § Research mode) |
| Subagent | **Feature closer** | After a QA pass, drafts the steps file, the passed status and the learnings file; the Technical Lead checks and decides ([agents/feature-closer.md](./agents/feature-closer.md)) |
| Subagent | **Code scout** | Before a full-mode plan, maps the code the change touches on a cheap model into `Plan/code-map.md`, so the Technical Lead, the Full-stack engineer, the review and QA read only the lines the change touches ([agents/code-scout.md](./agents/code-scout.md)) |
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
          plan.md         # Tech Lead; the human's request in § Request, approved by the human before dev (bug mode: the short bug plan)
          review.md       # Tech Lead; pre-QA code review findings (risk path or xhigh Full-stack)
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
  trials/
    <trial-slug>.md       # one per change under trial (harness/MORPHING.md § Trials)
  LEARNINGS.md            # trends, action items (folded by the prune)
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
- Capture the human's request in `Plan/plan.md` § Request (the human may draft it).
- Research implementation (skills, docs, web when needed) and write `Plan/plan.md` from the code scout's map and its own read of the lines the plan changes. A question that needs a wide search goes to the researcher ([MODES.md](./MODES.md) § Research mode); the TL frames it, checks the findings the answer rests on, and decides.
- Include in `plan.md`: title, dates, version, summary, implementation steps (phased if needed), references, **acceptance criteria**, QA scope, agent effort, open questions (with suggested defaults), approval state.
- Set lifecycle **status** ([SETUP.md](./SETUP.md) § Lifecycle status).
- Run [PLAN_CHECKLIST.md](./PLAN_CHECKLIST.md) and seek **human approval** on `plan.md` before delegating to the Full-stack engineer.
- After dev completes, delegate to the QA engineer (on a risk path or for `xhigh` Full-stack work, after the read-only review in [SETUP.md](./SETUP.md) § Code review before QA).
- After the QA verdict: if **pass**, hand to the human; if **fail**, delegate a new Full-stack run one effort step up with `qa-result.md` ([SETUP.md](./SETUP.md) § QA iteration) (at most `loop.qa_max_rounds` QA rounds per version; the Tech Lead enforces this, QA does not track the count).
- On the last allowed QA **fail**, set `failed-escalated` and hand to the human; further work uses a **new version** folder.
- After QA **pass**, write the steps file (or none) and set the plan to `passed` ([SETUP.md](./SETUP.md) § After QA pass) before handing to the human.
- After the QA pass hand-off (or on `failed-escalated`), write the feature's own learnings file in `_harness/learnings/`, with the retro inside it ([SETUP.md](./SETUP.md) § Retrospective).

### Should not (full and bug mode)

- Write or edit **application** code or config outside harness docs (read-only for investigation).
- Perform QA validation (that is QA's role).
- Edit `progress.md` or `qa-result.md`.
- Write or reword legal sentences (with the legal module, that is the legal writer's role).

## Agent 2: Full-stack engineer

### Should

- Read the approved `plan.md`, then create and update `Development/progress.md`.
- Implement everything the plan requires in the **application codebase** (outside `_harness/`, except `progress.md`), and the project fact docs its steps name.
- Keep `progress.md` current: steps, status, notes, validation run per step, **Started** and **Ended** (the agent's note from `date`; update Ended on QA rework, keep Started; the TL records real duration).
- Validate work with the automated checks the plan and [CONTROLS.md](./CONTROLS.md) name (commands in `project/CONTROLS.md`).
- Before handoff: run every `before_qa` check ([CONTROLS.md](./CONTROLS.md) § Before Full-stack → QA handoff; exit 0 required); log each check and its exit code in `progress.md` § **Validation (required before handoff)** (`end-of-task hook` for the `checks.on_stop` checks, which run when the turn ends: [CONTROLS.md](./CONTROLS.md) § End-of-task checks).
- Follow project skills, rules and guidelines.
- Hand back to the Technical Lead when implementation is complete.

### Should not

- Edit `plan.md`, `qa-result.md`, the steps file or `Legal/legal-copy.md`.
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

Answers one question per research file, with every claim cited (`file:line` or a URL with the date read). It has no shell and no edit tools (`disallowedTools` in `.claude/agents/researcher*.md`): it replies with the sections that go between the file's two lines, and the Technical Lead writes them in unchanged. It never writes to a remote environment, and never decides: the Technical Lead checks its findings and records the decision. Role body: [agents/researcher.md](./agents/researcher.md). Subagents can't start subagents, so only the Technical Lead launches it.

## Agent 6: Code scout

Before a full-mode plan, it searches and reads the code the change touches and writes a map to `<feature>/Plan/code-map.md`: files and functions with line ranges, contracts, callers, tests, conventions, adjacent defects and what it didn't find. It runs on a cheap model (`agents.scout`, haiku by default) with `tools: Read, Write, Bash, Grep, Glob`, read-only by its role body apart from that one file. The Technical Lead reads only the line ranges the plan changes and checks the callers itself, and the Full-stack engineer, the code review and QA get the map's path in their prompts, so the code is searched once per feature and no context carries whole files. Role body: [agents/code-scout.md](./agents/code-scout.md).

## Agent 7: Feature closer

After a full- or bug-mode QA pass, it drafts the closing records from the feature's files and the facts the Technical Lead passes it: the steps file (or none), `plan.md` set to `passed`, and the learnings file with the cost line pasted from `scripts/feature-cost.sh` and every proposed action item left `open`. It runs on a cheap model (`agents.closer`, haiku by default) with no web or MCP tools, and edits only those records. The Technical Lead checks the draft, decides the items, commits and hands off, so the close's docs and templates stay out of the main chat's long context. Role body: [agents/feature-closer.md](./agents/feature-closer.md).

## Skills, MCPs, guides, rules

- Prefer the skills and MCPs listed in [SKILLS_AND_MCPS.md](./SKILLS_AND_MCPS.md) and **`project/SKILLS_AND_MCPS.md`**.
- Project conventions live in `project/PROJECT.md`, and rules in `AGENTS.md` and `.claude/rules/` (the main chat's) and `project/agents/` (each subagent's), per repository.
