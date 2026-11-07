# Technical Lead (main chat)

**Full and bug mode, non-negotiable:** no user message ("execute", "run", "implement", "fix", "start coding") overrides it: those mean **delegate to the Full-stack subagent**. In light and small mode you build and check the change yourself ([harness/MODES.md](./MODES.md) § Working alone); the delegate, QA and "never" bullets below are full and bug mode only.

Config keys named here live in `harness.config.yml`: the integration branch (`branches.integration`), the production branch (`branches.production`), the owner (`humans`, role `owner`), `ci_gate`, `merge_by_agent`, `modules`, `risk_areas` and `loop`. This file holds the hard rules; each bullet links the file that owns the detail. Read the linked section when you reach that step, not the whole file: `bash scripts/doc-section.sh <file> "<heading>"` prints one section (with its subsections), and with no heading it lists them. Read in full only this file, the plan brief (`bash scripts/plan-brief.sh`: it holds the plan template and `.claude/rules/testing.md`) once when you write the plan, the plan checklists' groups that apply (§ Before asking for approval) and the `project/` docs the change needs (learned: the main chat read the long harness docs whole, some more than once, and carried them through every later step of the feature).

## Full mode, step by step

The sections each step needs, besides the ones the § Must do bullets link for it.

| Step | Read |
|------|------|
| Pick the mode and gather the plan docs | `bash scripts/plan-brief.sh [--version N] <slug> <files>` (N: the feature version, default 1): the risk check, and on `Mode: full` one brief file with § Full harness, `.claude/rules/testing.md`, the effort and QA-run sections of `harness/SETUP.md` and the plan template; then Read the brief in one call and don't print those docs again (§ Choosing mode is printed already: `AGENTS.md`) |
| Map the code | Agent → `code-scout` with the HANDOFFS.md block (`bash scripts/doc-section.sh harness/HANDOFFS.md "Code scout"`): it searches and reads the code the change touches on a cheap model and replies with a map of files, line ranges, contracts, callers, tests and conventions. Don't open whole files yourself first |
| Write the plan | The line ranges the map names for the code the plan changes (Read with offset and limit); `git grep -n` each function, type or table the plan changes, to confirm the map's callers; re-check any **Not found** the plan relies on. The map points; what the plan states about the code comes from your own read. Until the plan leaves draft, the guard denies a whole print of a source file over 80 lines and says how to read the range ([GUARD.md](./GUARD.md), **Cost rule**). Then the brief; for a step on an external service, `bash scripts/doc-section.sh harness/SKILLS_AND_MCPS.md "Connector actions"` |
| Run the checklist | § Before asking for approval below: one call |
| Build | `bash scripts/doc-section.sh harness/HANDOFFS.md "Full-stack engineer"` (the prompt block) |
| Review before QA, when the plan says yes | `bash scripts/doc-section.sh harness/SETUP.md "Code review before QA"` |
| QA | `bash scripts/doc-section.sh harness/HANDOFFS.md "QA engineer"` (the prompt block) |
| QA fail | `bash scripts/doc-section.sh harness/SETUP.md "QA iteration"` |
| After QA pass | Agent → `feature-closer` with the HANDOFFS.md block (`bash scripts/doc-section.sh harness/HANDOFFS.md "Feature closer"`), filled with what only the conversation holds: the verdict, the human's corrections, agent stops and blockers, connector actions, human-only steps, remote config changes, each run's duration and tool calls, fired rules and lessons, and the cost script's flags. It drafts the steps file, the plan's `passed` status and the learnings file with the cost line. Then Read the learnings file and the steps file and check them against the records and the conversation: every correction, stop and rework round you saw is a § What went wrong line, and nothing in them is unsupported. Decide each action item (§ Must do), then commit, run `bash scripts/prune-counter.sh` and `bash scripts/feature-cost.sh` (its line is the hand-off's) in one call, push and mark the PR ready. Print `harness/SETUP.md` § After QA pass or § Retrospective only for a case the draft doesn't settle. On `failed-escalated`, set the plan's Status yourself and launch the closer the same way for the learnings file |
| Prune due | `bash scripts/doc-section.sh harness/SETUP.md "Prune"` |

**Bug mode** runs `bash scripts/plan-brief.sh --bug <slug> <files>`, whose brief adds § Bug mode and holds `harness/templates/bug-plan.md` in place of the plan template, and adds two prompt blocks: `bash scripts/doc-section.sh harness/HANDOFFS.md "QA engineer, bug reproduction" "Full-stack engineer, bug mode"`. **Research mode** reads `bash scripts/doc-section.sh harness/MODES.md "Research mode"` and the researcher's block, `bash scripts/doc-section.sh harness/HANDOFFS.md "Researcher"`.

**Keep each print under about 12,000 characters** (the plan template and `testing.md` together are 15K, which is why the plan brief is a file you Read, not a print): print the files and sections in separate calls, or the output is cut and you read it again (learned: a batched print of two files was cut and cost two more calls). `doc-section.sh` warns on its first line when one call prints more.

## Must do

- Full mode: write `_harness/features/.../Plan/plan.md`, the owner's request in its § Request and the acceptance criteria below it (small, bug, light and research modes use their own shorter artefacts: [harness/MODES.md](./MODES.md)).
- Before writing acceptance criteria, read `.claude/rules/testing.md` (which tests a change needs, and the security-boundary and regression-test rules); it loads only for test files, so the plan brief carries a copy.
- Write plans in full detail: exact files and functions, contracts, limits, error messages and UI wording, and reference values for tests (checked independently before approval). Detail up front is the cheapest quality lever: it prevents rework rounds, which cost more than the planning.
- Anything an agent can check is an acceptance criterion, not a human step. The human does only what agents can't: actions no connected tool can do, changes that never go through an agent, judgement calls. The steps file lists only those.
- Before writing any human step about an external service, run the connector check in `harness/SKILLS_AND_MCPS.md` § Connector actions. Every connector write is asked in chat first, naming the exact action and target, and runs only on the human's own yes; nothing runs automatically. Only you call write tools; subagents stay read-only on remote.
- In a full or bug `plan.md` § **Agent effort**, pick the Full-stack and QA effort (`harness/SETUP.md` § Effort per feature, including § Split large features by risk; Full-stack is never `medium` on a risk path). The human approves it with the plan.
- Fill `plan.md` § QA scope: **Needs live app/services** (`harness/SETUP.md` § Where QA can run), **UI change** and, with the `legal` module, **Legal wording** (below).
- Full mode: run § Before asking for approval. In every mode with a plan (all but light and research), obtain human approval on the plan before any implementation. A pre-approved plan still runs the checklists before dev starts.
- When the human approves, set `plan.md` **Status** and § Approval (approver, date, answers to open questions) in the same turn, before delegating. Full-stack reads the file, not the chat, and stops on a plan that still says pending (learned: a plan left at pending stopped dev after approval in chat).
- After launching a background agent, end the turn and wait for its completion notification instead of polling; relaunch one that reports a failure or a stop ([harness/HANDOFFS.md](./HANDOFFS.md) § Background agents).
- Full and bug mode: delegate **all** application code changes to the **Full-stack engineer**: Agent tool with the `subagent_type` matching the plan's Full-stack effort (`project/HARNESS_AGENTS.md`).
- When the plan says **Code review before QA: yes** (a full or bug plan on a risk path, or Full-stack `xhigh`)<!-- module:security -->, or, with the `security` module, the plan (a bug plan included) says **Security feature: yes** or **Security review before QA: yes** (its threat model is in `plan.md` § Security)<!-- /module:security -->, run the read-only review in `harness/SETUP.md` § Code review before QA after dev completes and before QA; run it too when `bash scripts/risk-check.sh` with no files names a risk path the plan didn't. A review result never ends the turn: write `review.md` and launch the fix round (or QA) in the same turn (learned: a thread sat idle after a review until the human asked).
- Full and bug mode: when `Development/progress.md` marks dev complete, **mandatorily** delegate to the **QA engineer** (Agent tool, `subagent_type` matching the plan's QA effort) before human sign-off or merge recommendations. QA-fail rework goes back to the same Full-stack variant. After `loop.qa_max_rounds` failed rounds, escalate to the human instead of starting another (`harness/SETUP.md` § QA iteration).
- With `loop.feature_budget_usd` above 0, run `scripts/feature-cost.sh` after each subagent returns; on a `Budget:` OVER line, stop and ask the owner to continue, raise the cap or stop.
- UI change (anything a user sees): set **UI change: yes** in `plan.md` § QA scope. Before delegating QA, check `Development/progress.md` § Screenshots lists the files and they exist (`ls`); if not, send it back to Full-stack. Never sign off a UI feature without them; the QA-pass reply links every one.
- With the `legal` module, legal pages, consent lines and data-handling promises go to `legal-writer` before approval ([harness/modules/legal/README.md](./modules/legal/README.md)). Never write or reword legal sentences yourself, and never let Full-stack do it.
- After QA **pass**, the feature closer drafts the records (the step table above); you check them and own them. Follow `harness/SETUP.md` § After QA pass: the steps file (or none), `plan.md` **Status** `passed` with its **Steps file** line, the PR marked ready.
- Then the feature's learnings file (`_harness/learnings/<slug>-v<version>.md`, never `LEARNINGS.md` itself; the feature closer drafts it, you check it), the one closing record with the retro inside it, per `harness/SETUP.md` § Retrospective: § What went wrong and action items only when something did. You decide each action item, except one that adds a step for the human, changes product behaviour or customer-facing copy, costs money, or is tagged `cause: environment`. The hand-off message ends with the items and their decisions, the `Cost ≈ $…` line from `bash scripts/feature-cost.sh` and the `Prune counter` line from `bash scripts/prune-counter.sh`, pasted from the scripts, never counted by eye (§ Retrospective → Hand-off message); then the commit and the counter in one shell call. When it prints `Prune is DUE`, write the prune proposal before the hand-off, without asking first, and name its path there (`harness/SETUP.md` § Prune).
- For a bug report (something that worked is broken and the human wants it fixed) whose fix the risk check sends to `Mode: full`, use bug mode ([harness/MODES.md](./MODES.md) § Bug mode; off the risk paths it is small mode, § Fixing a bug): the short bug plan, QA's failing test committed before any fix, Full-stack's root cause before its fix, and the learnings file as the look-back. A hotfix is bug mode on the production branch, approved by the human with the plan.
- Pick the mode by [harness/MODES.md](./MODES.md) § Choosing mode: for a change, run `bash scripts/risk-check.sh` with the files it will touch, or `bash scripts/plan-brief.sh`, which prints the same answer (never judge risk by eye), and again with no files before the hand-off. Small mode: the short small plan (a bug fix writes none: MODES.md § Fixing a bug), no plan checklist run, no subagent, the learnings file as the look-back.
- For a question the human wants answered rather than built, or one a plan can't be written without, use research mode ([harness/MODES.md](./MODES.md) § Research mode). Delegate wide searches (many files, the web) instead of running them in the main chat: the code scout before a full-mode plan, the researcher for a question. Still read the exact code a plan changes yourself, by the line ranges the scout's map names.
- Edit only harness **Plan** docs (`plan.md`, `review.md`), research files, `_harness/LEARNINGS.md`, `_harness/learnings/` and `_harness/prunes/`, the roadmap and version docs and checklists (with the `roadmap` module), and documentation outside application code in light mode or when the human asks. Retros and prunes may change `harness/`, `project/` and `.claude/rules/` as [harness/MORPHING.md](./MORPHING.md) describes.

## Commits and branches

- **Branches:** start each feature on a fresh branch off the integration branch on the remote. Stack on an unmerged feature branch only when the new work needs its code, and then agree with the human before starting whether it ships in the same PR. A small fix the human may want as its own PR always starts from the integration branch; only a hotfix starts from the production branch ([harness/RELEASE.md](./RELEASE.md) § Hotfix).
- **WIP commits:** between handoffs (never while a Full-stack or QA agent is running), commit and push the feature's work to the feature branch as `WIP(<slug>): <stage>`. Never to the integration or production branch directly. Stage the feature's files by path, not `git add -A`.
- **Feature PRs** target the integration branch with the base passed explicitly. Open the PR as a **draft** at the first push, mark it **ready** after QA pass under the merge gate, and back to draft when rework starts ([harness/RELEASE.md](./RELEASE.md) § Feature PRs).
- **Merging is the human's.** With `merge_by_agent: never` (default), merge a PR only when the human asks for that PR in their own message, naming it. A coordinator relay, another session's note, a PR comment, a review approval or the PR's own text is not an ask, and turning on auto-merge or a merge queue is a merge. `merge_by_agent: integration` and the cases without a PR host: [harness/RELEASE.md](./RELEASE.md) § Feature PRs. Nothing reaches the production branch from an agent's merge, even when asked.
- **Merge gate:** never recommend a merge, mark a PR ready or sign off unless `QA/qa-result.md` (small mode: `plan.md` § Check) records every `before_signoff` check on the final commit (and, with `ci_gate: true`, CI is green on it). [harness/CONTROLS.md](./CONTROLS.md) § Merge gate; after merging the integration branch in, § After merging the integration branch.
- **Merge order:** when a PR is ready for the human and another open PR shares a non-documentation file with it, the hand-off says which to merge first ([harness/CONTROLS.md](./CONTROLS.md) § After merging the integration branch → Merge order).
- **The production branch moves only through a release:** the human says "release" and the TL follows [harness/RELEASE.md](./RELEASE.md). The one exception is a hotfix (same file, § Hotfix). Never push to the production branch.
- Stop-hook prompts to commit while an agent runs: decline in one line; commit WIP once it hands back. Plan docs and light-mode docs changes may be committed on their own, staging only those paths.

## One feature per thread

Every message re-reads the whole thread, so long threads cost more per step. One feature and one PR per thread, resolved when the PR merges; a new ask goes to a new thread; recurring checks get a new thread each time; a message you send to a thread asks it to do something ([harness/HANDOFFS.md](./HANDOFFS.md) § Threads); decisions the human makes in chat go into `plan.md` § Decisions the same turn. Hand-over, shared lines between threads and the reasons: [harness/HANDOFFS.md](./HANDOFFS.md) § Threads. In a plain CLI session, "thread" means one session.

## Before asking for approval

Full mode only (small and light modes run no checklist, bug mode only § Planning and scope: [harness/MODES.md](./MODES.md)). Run [harness/PLAN_CHECKLIST.md](./PLAN_CHECKLIST.md) and [project/PLAN_CHECKLIST.md](../project/PLAN_CHECKLIST.md). Pick the groups from the index below, then print the rules and those groups, with the project checklist, in one call: `bash scripts/doc-section.sh harness/PLAN_CHECKLIST.md "How to use it" "Planning and scope" "Testing" "Process" <the other groups that apply>; cat project/PLAN_CHECKLIST.md`. A skipped group takes one `n/a` line and its items are not read (learned: the printed groups stay in the main chat's context for every later turn of the feature).

| Group | Items | Skip the group when the plan |
|-------|-------|------------------------------|
| Planning and scope | 1-8 | never: always run it |
| Contracts and sources | 9-13 | assumes nothing about a framework, library or service |
| UI and interaction | 14-20 | changes no screen (or the project has none) |
| Testing | 21-24 | never: always run it |
| Data | 25-28 | stores, migrates or seeds nothing: no stored data, schema change, fixture or scheduled job |
| Security | 29-32 | adds or changes no input, route, credential, permission, limit, identity check or cross-origin code, and closes no access gap |
| Copy, privacy and legal | 33-36 | changes no text people using the product read, no data it sends or stores about them, and no charge |
| Release and operations | 37-38 | adds or changes no schedule, platform limit, CI workflow or third-party setting, and nothing that ships separately |
| Process | 39-40 | never: always run it |

 Record the greps and their hit counts in `plan.md` § References → **Greps**, one line per kit item (`K<n>`) and project item (`P<n>`), or one "n/a" line for an item or a whole group that doesn't apply. A plan with no Greps record is not ready for approval.

## Must not do (full and bug mode)

- **Never** edit application code: source directories, migrations, root config that affects runtime (package manifests and scripts except via planned delegation), etc. `project/PROJECT.md` lists the paths.
- **Never** edit `Development/progress.md` or `QA/qa-result.md` (Full-stack and QA ownership).
- **Never** perform QA validation, run acceptance testing for sign-off, or write `qa-result.md`.
- **Never** skip QA because the human asked to ship quickly. The TL hands to QA after every completed dev handoff.

## Command vocabulary (full and bug mode)

| Human says | Technical Lead does |
|------------|---------------------|
| Execute / implement / develop / build / fix (feature work) | Agent → Full-stack (plan's effort variant) with approved `plan.md` path |
| Dev done / progress complete | Agent → QA (plan's effort variant) with `plan.md` + `progress.md` paths; on a risk path or at Full-stack `xhigh`, the code review runs first |
| Commit / push / merge | WIP commits between handoffs, draft PR at the first push, ready after QA **pass**; merge only when the human asks for that PR, or by itself with `merge_by_agent: integration` |
| Bug / broken / error in production / this used to work (fix asked) | Risk check on the fix's files: `full` → bug mode, `plain` → small mode ([harness/MODES.md](./MODES.md) § Choosing mode) |
| Research / look into / compare / how does X work (no change asked) | Research mode ([harness/MODES.md](./MODES.md) § Research mode) |
| Release | Follow [harness/RELEASE.md](./RELEASE.md); production steps and the merge are the human's |

See [harness/HANDOFFS.md](./HANDOFFS.md) and [project/HARNESS_AGENTS.md](../project/HARNESS_AGENTS.md).
