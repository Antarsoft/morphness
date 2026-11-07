# Module: autonomous (brief to first version, unattended)

Optional, off by default. It runs a whole first version from a product brief with nobody at the keyboard: an Opus director writes the product docs and the feature order, the owner approves them once, and then a driver script builds the features one at a time, each in a fresh Claude Code session that runs the normal harness (Technical Lead, modes, guard, checks, QA, retro). Everything that needs a person goes to the version checklist, and the run keeps going. It stops only when a feature runs out of tries or the run budget is spent.

The default mode is unchanged. Without `MORPH_AUTO=1` in the environment, nothing in this module applies, and the owner approves every plan as usual.

**Needs the roadmap module** (the version checklist is where owner items go). **Not runnable yet:** the driver (`scripts/auto/`) and the `/morph-auto` skill come in a later kit release; this folder holds the rules and templates they use.

## How a run goes

1. **Brief.** The owner writes `docs/brief.md` (from `harness/templates/auto/brief.md`) and sets `auto.enabled: true`, `auto.budget_usd` and `loop.feature_budget_usd`.
2. **Docs.** `/morph-auto start` creates the run branch (`auto.branch`, default `auto/v1`) from the integration branch, and the director session writes `docs/product/` (product, tech, design and finance docs, and `order.md`), the version doc and its checklist with § Needs you filled first. The driver checks the order (unique slugs, known dependencies, no cycle), commits, and prints a cost estimate.
3. **Approval.** The owner reads the docs, edits them if needed, and runs `/morph-auto approve`. That is the only approval in a run. The driver records who approved, when, and a hash of `docs/product/`.
4. **Features.** For each feature in order whose dependencies have passed, the driver branches `feature/<slug>` from the run branch and starts one headless session. The Technical Lead picks the mode, writes the plan, approves it under § Run rules, delegates, runs QA and the retro, and ends by writing the feature's card. The driver checks the card against `plan.md` and the last `qa-result.md`, merges the branch into the run branch (`--no-ff`), runs `checks.on_stop`, and moves on.
5. **End.** The run ends `done` when every feature passed, `done_waiting` when the rest wait on the owner, or `exited` (below). `/morph-auto pr` opens one PR from the run branch to the integration branch, after merging the integration branch into it; the owner reviews and merges it as usual.

One feature runs at a time. The run branch is never pushed to an environment branch, and nothing in a run deploys, publishes or merges into the integration branch.

## When a run stops

| Stop | What happens |
|------|--------------|
| A feature runs out of tries: QA failed past `loop.qa_max_rounds` (`failed-escalated`), a crash after `auto.crash_retries` restarts, or `loop.feature_budget_usd` spent | The run exits at once and writes `_harness/auto/exit.md` |
| The run budget (`auto.budget_usd`), `auto.max_hours` or `auto.max_features` would be passed by the next feature | The run exits before starting it |
| The owner creates `_harness/auto/STOP` or runs `/morph-auto stop` | The run exits after the current feature |
| A usage limit | Not a stop: the driver waits `auto.usage_wait_minutes` (doubling, at most 4 hours) and tries again; the try doesn't count |
| A crash (no card, or a non-zero exit) | The driver starts the feature again from its last commit with the resume prompt, with Full-stack on `auto.last_try_model`, up to `auto.crash_retries` times (default once); the next crash exits |

`exit.md` opens with what the owner has to do, then the reason, the feature, the spend and the command to resume. `/morph-auto resume` starts the feature again from its last commit with fresh tries.

## Run rules

These replace every owner approval and owner ask in the harness while `MORPH_AUTO=1` is set. Everything else in the harness applies as written.

1. **Plans.** After the plan checklist passes, the Technical Lead approves the plan itself: **Status** `approved`, and in § Approval **Approver:** `Technical Lead (autonomous mode); product doc approved by <owner> on <date>` (from `_harness/auto/state.json` → `approval`). A plan never departs from `docs/product/` without saying so on the card (`departure: yes`).
2. **Branch only.** Work on `feature/<slug>`, commit there, and stop. No PR, no push, no merge, no checkout of the run branch: the driver does those.
3. **Owner questions.** Where the harness would ask the owner:
   - A budget stop or an escalation (`failed-escalated`): write the card with `status: escalated` and stop.
   - The docs answer it: follow `docs/product/`.
   - A reversible gap (a label, a default, an order): choose the default the docs point to, record it in the plan's § Decisions, and add an `assumed, confirm` item to § Needs you.
   - Pricing, legal wording, data and privacy promises: draft them, mark them draft in the code, and add a § Needs you item. Never present them as final.
4. **Guard denials.** A denied call (in a headless run every ask is a denial) becomes a § Needs you item with the command and why it was needed. Finish the feature without it when you can; otherwise write the card with `status: waiting_owner` and what the owner must do.
5. **Rework model.** After the first QA fail, and in a resumed session, Full-stack rework runs on `auto.last_try_model`.
6. **Retro.** Action items that change a rule get `human decides` and go to the checklist's § Harness changes. No trials in a run.
7. **Bugs outside the plan** go on the card under `bugs_found` with where they are; don't fix them in this feature.
8. **Never** run store builds or submits, EAS updates, deploys, publishes or hotfixes, and never touch secrets, billing or access settings. Those are the owner's alone.
9. **End by writing the card**, `_harness/auto/cards/<slug>.md` from `harness/templates/auto/card.md`, as the feature's last commit.

## The card and the ledger

The card is what the next features know about this one: a header the driver reads (`status`, `mode`, `qa_rounds`, `departure`, `split_into`, `bugs_found`, `v1_items`) and at most 40 lines on what was built, the interfaces other features can use, decisions and departures. A card with `status: passed` counts only when `plan.md` says `passed` and the last `qa-result.md` verdict is `pass`.

The driver appends each passed card's body to `_harness/auto/ledger.md`. A feature session reads only the cards of the features it depends on, not the whole ledger. When the ledger passes `auto.ledger_kb`, the director compacts it by milestone and keeps the last five cards whole.

What the driver does with each card status:

| Card | Driver |
|------|--------|
| `passed` | Merges, runs the end-of-task checks, appends to the ledger |
| `escalated` | Exits the run |
| `waiting_owner` | Marks the feature and every feature that depends on it `waiting_owner`, and carries on with the rest |
| `split` | Puts the parts from `split_into` in the feature's place; they keep its dependants |
| `bugs_found` (with any status) | Adds a fix item for each bug before the first feature that depends on the buggy one |
| `departure: yes` | Runs a director re-plan of the remaining order before the next feature |

The driver also runs a re-plan when `docs/product/` changes during a run (the owner edited it).

## Pruning and rule changes

After each feature the driver runs `scripts/prune-counter.sh`. When a prune is due, it starts a separate prune session that writes the proposal in `_harness/prunes/` and stops; the cuts wait for the owner in the checklist's § Harness changes, with the retro's rule items. No rule file changes during a run.

## Files

| Path | What |
|------|------|
| `docs/brief.md` | The owner's brief (from `harness/templates/auto/brief.md`) |
| `docs/product/product.md`, `tech.md`, `design.md`, `finance.md` | The director's docs (templates in `harness/templates/auto/`). The finance doc holds cost and pricing assumptions only; prices are the owner's |
| `docs/product/order.md` | The feature order the driver reads |
| `<versions_dir>/<id>/checklist.md` | The version checklist, with § Needs you (owner items, newest last) and § Harness changes (rule changes waiting for the owner) |
| `_harness/auto/state.json` | The run state; the driver writes it, agents never do |
| `_harness/auto/ledger.md` | Passed cards, compacted when it grows |
| `_harness/auto/tracker.md` | The tracker: a table and a flowchart coloured by status |
| `_harness/auto/cards/<slug>.md` | One card per feature |
| `_harness/auto/exit.md`, `STOP` | The exit note; the owner's stop file |
| `_harness/auto/logs/` | Session logs (git-ignored) |

Templates and prompts live in `harness/templates/auto/`: the brief and doc templates, the card and exit note, and the prompts the driver gives the director (`director-prompt.md`, `replan-prompt.md`), each feature session (`feature-prompt.md`, `resume-prompt.md`) and the prune session (`prune-prompt.md`).

## Config

```yaml
auto:
  enabled: false
  branch: auto/v1
  budget_usd: 0
  max_features: 30
  max_hours: 24
  crash_retries: 1
  director_model: opus
  last_try_model: opus
  ledger_kb: 8
  usage_wait_minutes: 30
```

`enabled: true` lets `/morph-auto start` begin a run; the owner sets it. `budget_usd: 0` refuses to start a run. `loop.feature_budget_usd` must be above 0 too (the start suggests 15), and each session gets `--max-budget-usd` at 1.5 times it. Feature sessions use the models in `agents:`; the director runs on `auto.director_model`. With this module, `mode.bug_repro: fullstack` is recommended (one QA run per bug).

## Safety

The driver is a script, not an agent. It refuses to start inside a Claude Code session or on a dirty tree, runs every session with `--permission-prompts none` (anything that would prompt is denied and logged) and `--max-budget-usd`, and never uses a mode that skips permissions. While a run is on, the guard denies agent writes to `harness.config.yml`, `_harness/auto/state.json`, `_harness/auto/ledger.md` and `scripts/auto/`, and agent pushes, merges and checkouts of the run branch.

## On install

- Needs `roadmap` in `modules`; if it is missing, add it first with `/morph-module add roadmap`.
- Put back the marked text (`module:autonomous`): the run-rules line in `harness/TECHNICAL_LEAD.md` § Must do and the autonomous approver line in § Approval of `harness/templates/plan.md`, `small-plan.md` and `bug-plan.md`.
- Copy `harness/templates/auto/`.
- Add the `auto:` block above to `harness.config.yml` with `enabled: false`, and `autonomous` to `modules`.
- Add `_harness/auto/logs/` to `.gitignore` (create the file if there is none).
- Ask the owner whether to set `mode.bug_repro: fullstack`, with the reason above.

## On remove

When the project doesn't choose this module, morph-init deletes this folder and the items below, then the empty `harness/templates/auto/` folder. Run files a past run left (`docs/brief.md`, `docs/product/`, `_harness/auto/`, the checklist's § Needs you and § Harness changes) stay: they are the project's.

**Delete these files:**

- `harness/templates/auto/brief.md`
- `harness/templates/auto/product.md`
- `harness/templates/auto/tech.md`
- `harness/templates/auto/design.md`
- `harness/templates/auto/finance.md`
- `harness/templates/auto/card.md`
- `harness/templates/auto/exit.md`
- `harness/templates/auto/director-prompt.md`
- `harness/templates/auto/replan-prompt.md`
- `harness/templates/auto/feature-prompt.md`
- `harness/templates/auto/resume-prompt.md`
- `harness/templates/auto/prune-prompt.md`

**Delete the marked text:** every span and line marked `module:autonomous`, with the command in [harness/README.md](../../README.md) § Modules → **Module markers**.

**Delete or reword these lines** (unmarked: config text):

- `harness.config.yml`: delete the `auto:` block and its comment, and remove `autonomous` from `modules`.
- `.gitignore`: delete the `_harness/auto/logs/` line.

**Unlink:** every Markdown link left pointing into `harness/modules/autonomous/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/autonomous' --include='*.md' . | grep -v '^./harness/modules/'`.
