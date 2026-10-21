# Morphing: how this harness changes itself

This harness was installed from Morphness, and from that moment it is **this repository's own**. Nothing upstream overwrites it. Every retro may change it and every prune audits it, so after a few dozen features it fits this project better than the copy it started from. That is the point: the rules that stay are the ones this project's failures earned.

Morphness never pushes changes into an installed harness, and nothing upstream overwrites a rule this project wrote. Upstream ideas arrive in two forms, each offered one at a time for the owner's yes: **lessons**, single rules from other projects, and **kit updates**, changes to the kit itself such as a new module or a corrected process rule (§ Health check and upstream updates).

## Where a lesson lands

A retro action item or a prune decision is applied to exactly one owner file ([README.md](./README.md) § Rule owners). Pick the narrowest file that every agent who needs the rule already reads.

| The lesson is about | It lands in | Example |
|---------------------|-------------|---------|
| The process, true for any project (lifecycle, QA rounds, handoffs, evidence) | The kit file that owns it: `harness/SETUP.md`, `HANDOFFS.md`, `CONTROLS.md`, `RELEASE.md`, `templates/` | "Round 2 re-runs the full suite when the rework touches a cross-cutting path" |
| Something the TL checks before approval | `harness/PLAN_CHECKLIST.md` if any project would want it, `project/PLAN_CHECKLIST.md` if it names this stack | "A plan that adds a user-entered field says where it ends up" |
| A fact about this project (a command, a path, a seeded login, a vendor quirk, a cross-cutting path) | `project/*` (`CONTROLS.md`, `STACK.md`, `PROJECT.md`, `TESTING.md`, `RELEASE.md`) | "The local stack needs its containers stopped before a reset" |
| An optional module's area (browser tests, data access, legal wording, roadmap) | `harness/modules/<module>/README.md` | "Scan an open dialog's layer for accessibility, not the page behind it" |
| How a role works, for any project | `harness/agents/<role>.md` | "QA reports a run only once its new exit file exists" |
| A value or example that sharpens a kit process rule here (a check interval, the feature that taught it) | `project/PROCESS.md` | "Signs-of-life check every 10 minutes (learned in `<slug>`)" |
| How a role works here | `project/agents/<role>.md` | "Full-stack captures screenshots at these widths and themes" |
| A hard limit on the Technical Lead (one line; the how goes to the owner file above, linked) | `harness/TECHNICAL_LEAD.md` | "Set the plan's status in the same turn as the approval" |
| What tests to write | `.claude/rules/testing.md` (generic) or `project/TESTING.md` (this stack) | "A bug fix gets a regression test proven by a negative run" |
| A structural setting (branches, modules, checks, effort variants, loop limits) | `harness.config.yml`, plus the rendered files that use it | "QA default effort becomes medium" |
| A model or effort mapping | `project/HARNESS_AGENTS.md` and `.claude/agents/*.md` | "A cheaper Full-stack variant for UI-only features" (as a trial first) |

When a lesson fits two places, it goes to the one owner and the other links to it. Never restate a rule in a second file: two copies drift.

## How rules change

- **Retro action items** ([SETUP.md](./SETUP.md) § Retrospective): as many as the feature's findings call for, usually up to `loop.retro_max_items` (more with one line saying why, none is fine), each with its **Why raised**: the finding it answers and the evidence. The TL decides each (approve, skip, defer) and lists the decisions in the hand-off. An item that adds a step for the human, changes product behaviour or customer-facing copy, costs money, or is tagged `cause: environment` goes to the human. A small approved doc or harness item rides the finished feature's PR as its own commit; a large one gets its own plan; a code item gets its own feature.
- **Prune decisions** ([SETUP.md](./SETUP.md) § Prune): the TL proposes keep, merge, shorten, move to on-demand or remove for each audited rule; the human approves per row. Only approved rows change anything, applied as a light-mode docs change.
- **The human, any time:** the owner may edit any harness file directly. The TL records the change as a decision in the current plan, or as a light-mode commit with a one-line reason.

Kit files have no placeholders, so editing them is safe. Rendered files (`CLAUDE.md`, `AGENTS.md`, `.claude/agents/*`, `project/*`) were filled once by `/morph-init`; edit them like any other file.

## Rule provenance

Every rule ends with where it came from, so a prune can find its evidence and a reader can tell a scar from a guess:

- A rule a retro adds ends with the feature that taught it and the day it landed: `(from checkout-retry, 2026-10-12)`. A rule tightened later appends the next one: `(from checkout-retry, 2026-10-12; invite-flow, 2026-11-03)`. Keep it to that: the why lives in the action item's **Why raised**, not in the rule. Older rules that end with just the slug, `(checkout-retry)`, stay as they are.
- A rule that came with the kit ends with a short reason, `(learned: <the failure it prevents>)`, or with nothing when it is plain process.
- A rule adopted from an upstream lesson ends with `(lesson: <id>)`.

The prune's rule audit (step 2) reads these to find when a rule landed and whether it has fired since. `bash scripts/prune-counter.sh --prune` lists every `(from …)` tag with the number of features finished since its date, so `too new to judge` and "did the problem come back after this date?" are a lookup, not a hunt. `bash scripts/learned-rules.sh` (read-only; `--all` adds the untagged rules) lists the same tags as a table: file and line, source finding, the day it landed, the last day a learnings entry's `Fired:` line named that source (blank if none) and the rule text. `/morph-doctor` runs it. A rule with no provenance that the TL can't trace is audited like any other; `never fired` across two windows moves it to on-demand.

## Trials

A trial is a change whose value is uncertain (most often a model or effort variant, sometimes a process rule) run on a fixed number of features and measured, then decided at a prune from the numbers. A trial never becomes the rule by default.

1. **Start.** The owner decides it (a trial that costs money or changes who reviews what always goes to the owner), or an approved retro item proposes it. Write `_harness/trials/<trial-slug>.md` from [templates/trial.md](./templates/trial.md): the hypothesis, the exact rule text or variant, the feature it starts with, its length (N features), which features qualify, the metric (rework rounds, QA fails, cost from `scripts/feature-cost.sh`), the baseline (the last window's numbers and one comparable earlier feature, so the verdict is a before and after, not an impression), and the pass and revert conditions. A model or effort trial also adds its variant file to `.claude/agents/`, its row to `project/HARNESS_AGENTS.md` and the variant to `harness.config.yml` → `agents`. A rule trial puts its rule text in the owner file with `(trial: <trial-slug>)` at its end instead of `(from …)`.
2. **Run.** Each qualifying feature's plan names the trial in § Agent effort (or its plan, for a rule trial). Its retro answers the Trials line, and its learnings file gets `**Trial:** <trial-slug>`: that line is the result. The numbers come from the same file's **Verdict** and **Cost** lines, so the retro writes nothing into the trial file (parallel features would conflict there). `bash scripts/prune-counter.sh` prints `Trial <slug>: N/<length> features` in every hand-off.
3. **Stop early** on the revert condition (for example the first second QA round from an implementation cause). Record it on the learnings file's Trial line and set the trial file's **Status** to `reverted`.
4. **Decide at the prune** ([SETUP.md](./SETUP.md) § Prune, step 1) once it has run its length: `bash scripts/prune-counter.sh --prune` prints each trial's rework rounds, QA fails and cost over its features, and the TL proposes `keep` (the rule loses its `(trial: …)` tag and gets `(from <trial-slug>, <date>)`) or `revert` (the variant goes back to the previous default), with those numbers next to the window's. The owner decides. A trial that hasn't run its length carries on, and so does one that has but whose escape window is still open: a trial is decided only once one prune window (`loop.prune_every` features) has finished after its last qualifying feature, because a bug that QA missed shows days later, not at the hand-off (learned: a QA effort change was kept on a "0 escapes" reading taken hours after deploy, and the next window logged 4). The decision reads the numbers above plus the `Escaped` lines of bug-mode and fix-PR learnings files whose source feature is one of the trial's features (blame the fix's lines to the feature that wrote them); an escape traced to a trial feature counts against the trial, and without an escape reading the proposal says `carry on`. When the prune folds the learnings files, each trial feature becomes a row in its trial file's § Results, so the count survives the fold.

## Pruning

Rules accumulate faster than they retire: every retro can add one, and each costs context on every turn of every agent that loads it. The prune keeps the harness lean:

- Rules that fired stay. Rules that never fired in a window are questioned; never in two windows, they move to an on-demand file read only when it applies, or go.
- Rules that rarely fire but prevent an expensive failure are `insurance` and stay, with the cost named.
- Rules younger than three features are `too new to judge`.
- Old learnings are condensed to one line and archived, so `LEARNINGS.md` holds only the current window.

A prune that cuts nothing is a valid result. The aim is not a short harness; it is a harness where every line has earned its place.

## Sharing a lesson upstream

Morphness keeps a community catalog of lessons (`lessons/` in the Morphness repository): one file per lesson, with the rule text, why it exists, how to check it, and evidence of how often it fired. A lesson this project learned can help others.

- **When:** a rule that the prune audit marks `fired` (or `insurance` with a named cost) and that is not specific to this project. The TL may suggest it in the prune proposal; it never shares on its own.
- **How:** run `/morph-share` with the rule. It drafts the lesson file: a neutral rule text with project names, feature slugs, people and private paths removed; the target file in an installed harness; tags (stack, service, area); and evidence from the prune audits. It shows the draft and asks the owner.
- **Only with the owner's yes.** Sharing is optional and nothing leaves the repository without that yes. The owner may edit the draft, or decline and keep the lesson local.

## Sharing evidence

Lessons are single rules. To show that the harness worked in this project, `bash scripts/evidence.sh` builds a summary from the run records: features finished, how often QA passed first time, rework by prune window, escapes, estimated cost per feature, retro items applied or skipped, rule audit results, trials and lessons adopted. It prints counts and rates only, from a fixed list of fields: no feature names, retro text, paths or people. `--out` also writes it to `_harness/evidence/<date>.md` and `.json`; commit it or not. It is read-only, sends nothing, and says in its own text what the figures can't show (agent-recorded, escapes under-counted, no control).

- **Only with the owner's yes.** `/morph-share` runs it, shows the full summary and opens a pull request with it to Morphness (`showcase/`) only when the owner agrees. The owner may also paste it anywhere on their own.
- **Not a benchmark.** It shows what the process produced in this project, not what it saved against working without it.

## Health check and upstream updates

`/morph-doctor` checks that the installed harness is still wired and consistent:

- **Health:** `harness.config.yml` parses; every named check has a command in `project/CONTROLS.md`; every enabled module has its files; no unfilled render placeholder or `morph-init: fill` comment is left in rendered files; rule owner links resolve; the prune counter and open action items are reported.
- **Upstream:** it counts the kit updates and matching lessons this project hasn't seen and says to run `/morph-update`. It changes nothing.

`/morph-update` (or, for an agent without the plugin, `UPDATE.md` in the Morphness repository) brings upstream changes in:

- **What it reads:** `harness.config.yml` → `installed_from` records the Morphness commit this copy was last synced to and the update notes already applied, declined or put off. It lists the kit update notes added upstream since then that fit this project (its modules; a new module is offered as an opt-in), and the lessons added since then whose tags match and that are not already here (matched by `(lesson: <id>)` provenance). Fixes to a wrong or unsafe kit instruction come first.
- **Adopting one:** the owner picks per item: apply, decline (never offered again) or later. Kit updates are merged file by file against the template this copy started from: a file this project never edited takes the new version; an edited one gets a merge that keeps this project's rules, shown before it is written. Lessons land in their target file (or this project's better owner, § Where a lesson lands), ending with `(lesson: <id>)`. Everything goes on a branch as a light-mode docs change, and the next prune audits adopted rules like any other.
- **Where from:** by default it reads release notes and template text from github.com/antarsoft/morphness (`installed_from.repo`); it executes nothing and falls back to a local copy (a clone in `~/.cache/morphness`). `harness.config.yml` → `updates.source: local` always uses the clone. Only released updates are offered.
- **When:** whenever the owner asks, and at every prune: the Technical Lead runs the read-only check and lists what's pending in the prune proposal ([SETUP.md](./SETUP.md) § Prune), so a copy that falls behind upstream gets noticed.

Kit updates never replace this project's own direction: a declined update is recorded as declined, and a rule this project changed on purpose stays changed. When an update contradicts a local rule, the owner decides which wins.
