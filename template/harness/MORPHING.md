# Morphing: how this harness changes itself

This harness was installed from Morphness, and from that moment it is **this repository's own**. Nothing upstream overwrites it. Every retro may change it and every prune audits it, so after a few dozen features it fits this project better than the copy it started from. That is the point: the rules that stay are the ones this project's failures earned.

There is no harness version and no upgrade step. Morphness never pushes changes into an installed harness. New ideas from other projects arrive only as single **lessons** that the owner chooses to adopt (§ Health check and upstream lessons).

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
| A hard limit on the Technical Lead | `.claude/rules/technical-lead.md` | "Set the plan's status in the same turn as the approval" |
| What tests to write | `.claude/rules/testing.md` (generic) or `project/TESTING.md` (this stack) | "A bug fix gets a regression test proven by a negative run" |
| A structural setting (branches, modules, checks, effort variants, loop limits) | `harness.config.yml`, plus the rendered files that use it | "QA default effort becomes medium" |
| A model or effort mapping | `project/HARNESS_AGENTS.md` and `.claude/agents/*.md` | "A cheaper Full-stack variant for UI-only features" (as a trial first) |

When a lesson fits two places, it goes to the one owner and the other links to it. Never restate a rule in a second file: two copies drift.

## How rules change

- **Retro action items** ([SETUP.md](./SETUP.md) § Retrospective): at most `loop.retro_max_items` per feature. The TL decides each (approve, skip, defer) and lists the decisions in the hand-off. An item that adds a step for the human, changes product behaviour or customer-facing copy, or costs money goes to the human. A small approved doc or harness item rides the finished feature's PR as its own commit; a large one gets its own plan; a code item gets its own feature.
- **Prune decisions** ([SETUP.md](./SETUP.md) § Prune): the TL proposes keep, merge, shorten, move to on-demand or remove for each audited rule; the human approves per row. Only approved rows change anything, applied as a light-mode docs change.
- **The human, any time:** the owner may edit any harness file directly. The TL records the change as a decision in the current plan, or as a light-mode commit with a one-line reason.

Kit files have no placeholders, so editing them is safe. Rendered files (`CLAUDE.md`, `AGENTS.md`, `.claude/agents/*`, `project/*`) were filled once by `/morph-init`; edit them like any other file.

## Rule provenance

Every rule ends with where it came from, so a prune can find its evidence and a reader can tell a scar from a guess:

- A rule a feature taught ends with that feature's slug in parentheses: `(checkout-retry)`. A rule tightened later appends the next slug: `(checkout-retry, invite-flow)`.
- A rule that came with the kit ends with a short reason, `(learned: <the failure it prevents>)`, or with nothing when it is plain process.
- A rule adopted from an upstream lesson ends with `(lesson: <id>)`.

The prune's rule audit (step 2) reads these to find when a rule landed and whether it has fired since. A rule with no provenance that the TL can't trace is audited like any other; `never fired` across two windows moves it to on-demand.

## Trials

A trial is a change whose value is uncertain (most often a model or effort variant, sometimes a process rule) run on a fixed number of features with a KPI, then decided at the next prune. A trial never becomes the rule by default.

1. **Start.** The owner decides it (a trial that costs money or changes who reviews what always goes to the owner), or an approved retro item proposes it. Add a row to `_harness/LEARNINGS.md` § Trials: name, start, scope (which features qualify, for example "the next three UI-only features"), KPI per feature, pass condition, revert condition, and the prune that decides it. A model or effort trial also adds its variant file to `.claude/agents/`, its row to `project/HARNESS_AGENTS.md` and the variant to `harness.config.yml` → `agents`.
2. **Run.** Each qualifying feature's plan names the trial variant in § Agent effort. Each learnings file records the model with the effort on its **Cost** line, so the prune can tabulate by model. Good KPIs are the ones the harness already records: QA rounds, failure causes by type, review findings, duration, tokens and tool calls, and escapes (bugs found after a QA pass).
3. **Stop early** on the revert condition (for example the first second QA round from an implementation cause). Record it in the learnings file and the Trials row.
4. **Decide at the prune** ([SETUP.md](./SETUP.md) § Prune, step 1): the TL tabulates the KPI over the window and proposes `keep` (the trial becomes the rule and its row moves to the rule's owner file) or `revert` (the variant goes back to the previous default), with the numbers. The owner decides. A trial that no feature qualified for carries on to the next prune, said so in the row.

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

## Health check and upstream lessons

`/morph-doctor` checks that the installed harness is still wired and consistent, and lists upstream lessons this project might want:

- **Health:** `harness.config.yml` parses; every named check has a command in `project/CONTROLS.md`; every enabled module has its files; no unfilled render placeholder or `morph-init: fill` comment is left in rendered files; rule owner links resolve; the prune counter and open action items are reported.
- **Upstream lessons:** `harness.config.yml` → `installed_from` records the Morphness commit the harness was installed from. The doctor lists the lessons added upstream since then whose tags match this project (its stack, services and enabled modules) and that are not already here (matched by `(lesson: <id>)` provenance). It only lists; it changes nothing.
- **Adopting one:** the owner picks a lesson; the TL applies it as a light-mode docs change to the lesson's target file (or this project's better owner, § Where a lesson lands), ending the rule with `(lesson: <id>)`. The next prune audits it like any other rule.
