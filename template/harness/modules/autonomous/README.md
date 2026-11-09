# Module: autonomous (brief to first version, unattended)

Optional, off by default. It runs a whole first version from a product brief with nobody at the keyboard: an Opus director writes the product docs and the feature order, the owner approves them once, and then a driver script builds the features one at a time, each in a fresh Claude Code session that runs the normal harness (Technical Lead, modes, guard, checks, QA, retro). Everything that needs a person is written down for the owner (the feature's steps file and the version checklist), and the run keeps going. It stops when a feature runs out of tries, a run limit (budget, hours, features) is reached, or the owner stops it.

The default mode is unchanged. Unless the driver started the session (`MORPH_AUTO=1` set and the run state running that feature), nothing in this module applies, and the owner approves every plan as usual.

**Needs the roadmap module** (owner items go to its steps files and version checklist). The driver is `bash scripts/auto/run.sh` (`start`, `approve`, `run`, `resume`, `status`, `stop`). `/morph-auto` prepares each step (brief, budgets, review of the docs, status, stop, resume, the run's PR) and gives the owner the command to type.

## How a run goes

1. **Brief.** The owner writes `docs/brief.md` (from `harness/templates/auto/brief.md`) and sets `auto.enabled: true`, `auto.budget_usd` and `loop.feature_budget_usd`.
2. **Docs.** The owner runs `bash scripts/auto/run.sh start` from a terminal (the driver refuses to run inside a Claude Code session). It creates the run branch (`auto.branch`, default `auto/v1`) from the integration branch, and the director session writes `docs/product/` (product, tech, design and finance docs, and `order.md`), and in the next version's checklist (the one the roadmap marks next; created only when there is none) a § Needs you section with every owner item it can foresee. The driver checks the order (unique slugs, known dependencies, no cycle), commits, and prints a cost estimate. Before it makes the branch, `start` (and `run` and `resume`) checks that Claude Code is signed in: `claude auth status`, then a one-word session on the small model in an empty folder (about a cent).
3. **Approval.** The owner reads the docs, edits them if needed, and runs `bash scripts/auto/run.sh approve`, then `run`. That is the only approval in a run. The driver records who approved, when, and a hash of `docs/product/`; it updates the hash after each of its own re-plans.
4. **Features.** For each feature in order whose dependencies have passed, the driver branches `feature/<slug>` from the run branch and starts one headless session. The Technical Lead picks the mode, writes the plan, approves it under § Run rules, delegates, runs QA and the retro, and ends by writing the feature's card. The driver checks the card against the feature's records (§ The card and the ledger), merges the branch into the run branch (`--no-ff`), runs `checks.on_stop`, and moves on.
5. **End.** The run ends `done` when every feature passed, `done_waiting` when the rest wait on the owner, or `exited` (below). `/morph-auto pr` opens one PR from the run branch to the integration branch, after merging the integration branch into it; the owner reviews and merges it as usual.

One feature runs at a time. The run branch is never pushed to an environment branch, and nothing in a run deploys, publishes or merges into the integration branch.

## When a run stops

| Stop | What happens |
|------|--------------|
| A feature runs out of tries: QA failed past `loop.qa_max_rounds` (`failed-escalated`), a crash after `auto.crash_retries` restarts, or the feature's spend passing 1.5 times `loop.feature_budget_usd` (the session's hard cap; never counted as a crash, and a passed card written before the cap still counts) | The run exits at once and writes `_harness/auto/exit.md` |
| The run budget (`auto.budget_usd`), `auto.max_hours` or `auto.max_features` (bug fixes the run inserts count too) would be passed by the next feature | The run exits before starting it |
| The owner runs `bash scripts/auto/run.sh stop` (from a second terminal) or creates `_harness/auto/STOP` | The run exits after the current feature |
| A usage limit (the session's own error says so) | Not a stop: the driver waits `auto.usage_wait_minutes` (doubling, at most 4 hours) and tries again; the try doesn't count. After 12 waits in a row it exits |
| A session runs past `auto.session_hours`, moves a protected branch or the run branch, or a merge conflicts | A session past its hours is a crash; the others exit the run at once |
| Claude Code isn't signed in (the session's own error says it couldn't authenticate: an expired sign-in, a bad API key, a 401) | Never a crash and never a try: the run exits at once, the feature stays `todo`, and `exit.md` gives the steps: in a terminal type `claude`, then `/login` and sign in, then `/exit`, then resume. At `start` the driver refuses before it makes the branch, and after a failed director it commits nothing unless the director wrote docs |
| A crash (no card, or a non-zero exit) | The driver starts the feature again from its last commit with the resume prompt, with Full-stack on `auto.last_try_model`, up to `auto.crash_retries` times (default once); the next crash exits |

`exit.md` opens with what the owner has to do, then the reason, the feature, the spend and the command to resume. After a "tries used up" exit, resume gives the retry the exit reason and the stopped feature's own card, so it starts from why it stopped. `bash scripts/auto/run.sh resume` starts the feature again from its last commit with fresh crash tries, budget and clock; after `done_waiting` it runs the waiting features again once the owner has done their items. A driver that was killed (a closed terminal, a sleeping Mac) is picked up by `run`: the interrupted session counts as a crash. After `failed-escalated`, the harness allows no more QA rounds on that version: the owner writes a direction in `exit.md` § Owner direction and commits it (resume refuses without one), and resume starts the feature's next version folder with it in § Request (`harness/SETUP.md` § QA iteration).

## Run rules

These apply only in a session the driver started: `MORPH_AUTO=1` is set and `MORPH_AUTO_FEATURE` names this feature. They replace every owner approval and owner ask in the harness, and its push, PR, merge and branch steps. Everything else applies as written.

1. **Plans.** After the plan checklist passes, the Technical Lead approves the plan itself: **Status** `approved`, and in § Approval **Approver:** `Technical Lead (autonomous mode); product doc approved by <owner> on <date>` (the feature prompt gives both). A plan never departs from `docs/product/` without saying so on the card (`departure: yes`).
2. **Branch only.** Work on `feature/<slug>` (the driver made it from the run branch, not the integration branch), commit there, and stop. In a run, `scripts/risk-check.sh` and `scripts/handoff.sh` compare the feature branch with the run branch it left (`MORPH_AUTO_BRANCH`), so the mode, the QA diff and the bug-order check see only this feature's change; read the diff with `git diff $(git merge-base <run branch> HEAD)` the same way. No PR, no push, no merge (a batched retro's merge of the integration branch included), no checkout of another branch: the driver does those.
3. **Owner questions.** Where the harness would ask the owner:
   - A budget stop or an escalation (`failed-escalated`): write the card with `status: escalated` and stop.
   - The docs answer it: follow `docs/product/`.
   - The owner answered it: the prompt lists what the owner recorded since the feature started (a new row of theirs in a version doc's Decisions table, an owner item they ticked or annotated in the checklist or `steps/`). Follow the answer. A question answered there is not an owner item and never a reason for `waiting_owner`; the driver gives a `waiting_owner` card whose every item is already answered one more session with the answers.
   - A reversible gap (a label, a default, an order): choose the default the docs point to, record it in the plan's § Decisions and, for a product decision, in the version doc's Decisions table marked `assumed`, and add an `assumed, confirm` item to the steps file.
   - Pricing, legal wording, data and privacy promises: draft them, mark them draft in the code, and add a steps-file item. Never present them as final.
   - An accepted risk (a threat model's § Accepted risks) or a security exception: never accept one yourself. When the plan can't go on without it, write the card with `status: waiting_owner`.
4. **Owner items** go to the feature's steps file as usual (`harness/SETUP.md` § After QA pass, step 4), each also one line in the card's § Owner items (a rule item starts `rule:`); the driver copies those lines to the checklist's § Needs you and § Harness changes after the merge. Features never edit the checklist.
5. **Guard denials.** In a headless run every call that would prompt is denied, so a shell command outside the allow rules in `.claude/settings.json` is too. Run one command per call, the named checks through `bash scripts/checks.sh run`, and file work with the file tools; when a chain is denied, try its commands one at a time. A call still denied becomes a steps-file item with the command and why it was needed. Finish the feature without it when you can; otherwise write the card with `status: waiting_owner` and what the owner must do.
6. **Rework model.** After the first QA fail, and in a resumed session, Full-stack rework runs on `auto.last_try_model` (the Agent call's model), in place of the same-variant rule.
7. **Retro and prune.** Action items that change a rule get `human decides` (listed in § Owner items with `rule:`). No new trials start in a run; a trial already on in the config runs as configured. On `Prune is DUE`, don't write the proposal, and its exit code doesn't hold the hand-off: the driver runs the prune session.
8. **Bugs outside the plan** go in the card's § Bugs found as `- <slug> | what | where | kind | reproduction`; don't fix them in this feature. The kind is `behaviour` (the code does the wrong thing), `style` (naming, layout, a small cleanup), `docs` (a doc says the wrong thing) or `decision` (a question only the owner answers). The reproduction is a failing test or the steps that show it; a behaviour bug with none isn't a fix yet. A bug in the harness itself (its scripts, rules or templates) is `- harness | what | where`: the driver puts it in the checklist's § Harness changes for the owner instead of adding a fix item.
9. **Never** run store builds or submits, EAS updates, deploys, publishes or hotfixes, connector writes, writes to a remote database, migrations on a shared environment, or changes to hosted settings and variables, and never touch secrets, billing or access settings. Each one needed becomes a steps-file item; they are the owner's alone.
10. **End by writing the card**, `_harness/auto/cards/<slug>.md` from `harness/templates/auto/card.md`, as the feature's last commit.

## The card and the ledger

The card is what the next features know about this one: a header the driver reads (`status`, `mode`, `qa_rounds`, `departure`) and at most 40 lines on what was built, the interfaces other features can use, decisions and departures, with three lists the driver acts on, one `- ` line per item: § Owner items, § Bugs found and § Split into. `bash scripts/auto/card.sh <card>` checks one. The card must be written in the session that ends with it, and the branch must change more than the card. A card with `status: passed` counts only when the mode's own record says so: full and bug mode, `plan.md` **Status** `passed` and the last `qa-result.md` verdict `pass`; small mode, `plan.md` **Status** `passed` with § Check filled; light mode and a small bug fix (`mode: small-bug`, `harness/MODES.md` § Fixing a bug), the feature's commit with its checks passing (`checks.on_stop`, run by the driver; with no `on_stop` checks such a card doesn't count). A `small` card with no feature folder whose branch has a failing-test commit followed by the fix is checked as `small-bug`, with a warning; without those commits the exit reason says to relabel the card `small-bug`. The records are read from `_harness/features/<slug>/`, the feature's exact slug, which the prompt names and `scripts/plan-brief.sh` insists on in a run. When that folder is missing but the session added one named after the slug without its trailing `-<n>` (`fix-app-shell` for `fix-app-shell-1`), and no feature of the run has that name, the driver reads that one and prints a warning with the `git mv` to rename it. When the records don't agree, the exit reason says whether `qa-result.md` is missing, blocked (`blocked: permission`) or failing, and the driver reads the session's log, subagents included, for commands refused with no prompt: `exit.md` names them and the allow rule to add.

The driver appends each passed card's body to `_harness/auto/ledger.md`. A feature session reads only the cards of the features it depends on, not the whole ledger. When the ledger passes `auto.ledger_kb`, the director writes a compacted copy, `ledger.next.md` (by milestone, the last five cards whole), and the driver swaps it in.

What the driver does with each card status:

| Card | Driver |
|------|--------|
| `passed` | Merges, runs the end-of-task checks, appends to the ledger |
| `escalated` | Exits the run |
| `not-a-bug` (a fix the run inserted only) | The fix found no bug: it doesn't reproduce (`reason: not-reproduced`), it is a product decision a plan or doc records (`product-decision`, with an owner item to confirm it), or another fix covers it (`duplicate`). `evidence:` names a file:line on the branch, the plan's decision id (`D2`) or the slug it duplicates. No feature folder is needed. The driver merges the card (and any guard test, which then gets the end-of-task checks), marks the feature `skipped`, and carries on |
| `waiting_owner` | Marks the feature and every feature that depends on it `waiting_owner`, and carries on with the rest |
| `split` | Puts the parts from § Split into in the feature's place (checked like the order: kebab-case, new slugs, known dependencies); every feature that depended on it depends on all the parts |
| § Bugs found (with any status) | A line whose `where` is under `scripts/`, `harness/`, `project/`, `.claude/` or `_harness/` is about the harness: it goes to `_harness/HARNESS_BACKLOG.md` and the checklist's § Harness changes, never a fix item. A line about a fix (its slug starts `fix-`) goes to the backlog as a follow-up, so a fix never spawns a fix of itself. Otherwise by kind. Only `behaviour` with a reproduction becomes a fix item, before the first remaining feature that depends on the buggy one, or next when none does; its prompt starts with the reproduction. A behaviour line with no reproduction (or a line with no kind) goes to the checklist's § Needs you as unconfirmed. `style` goes to the prompt of the next feature that depends on the buggy one, fixed only if that feature changes the file anyway, and is dropped when none does. `docs` becomes an item in `_harness/HARNESS_BACKLOG.md`. `decision`, and any line that names an assumed decision (`D<n>`), an owner item, a product decision or "by design", goes to § Needs you, since it's the owner's call. An unknown kind makes the card invalid |
| `departure: yes` | Runs a director re-plan of the remaining order before the next feature |

The driver also runs a re-plan when the committed `docs/product/` changes outside the run's own commits (the owner edited and committed it between runs). A re-plan keeps the fixes and split parts the run added unless the director orders them, and a failed one restores `docs/product/`. The driver records each re-plan in `state.json`, and the director adds it to product.md § Decisions the director made, so the final PR shows what changed after approval.

## Pruning and rule changes

After each feature the driver runs `scripts/prune-counter.sh`. When a prune is due, it starts a separate prune session on the run branch that writes the proposal in `_harness/prunes/` and stops; the driver commits it, and the cuts wait for the owner in the checklist's § Harness changes, with the retro's rule items. No rule file changes during a run.

## Files

| Path | What |
|------|------|
| `docs/brief.md` | The owner's brief (from `harness/templates/auto/brief.md`) |
| `docs/product/product.md`, `tech.md`, `design.md`, `finance.md` | The director's docs (templates in `harness/templates/auto/`). The finance doc holds cost and pricing assumptions only; prices are the owner's |
| `docs/product/order.md` | The feature order the driver reads |
| `<versions_dir>/<id>/checklist.md`, `steps/` | The version checklist, with § Needs you (owner items: the director's first, then the driver's copies of each card's § Owner items) and § Harness changes (rule changes and prune proposals waiting for the owner), and each feature's steps file as usual |
| `_harness/auto/state.json` | A snapshot of the run state, committed on the run branch. The live state, the session logs and the stop request live in the git folder (`.git/morphness/auto/`), outside every branch, so no session can commit them |
| `.git/morphness/auto/logs/NNNN-<label>.jsonl` | One log per session, written as the session streams (`--output-format stream-json`). While a session runs, the terminal shows a line per tool call (the file it writes, the command it runs) and a "still running" line after 2 quiet minutes; `tail -f` on the log shows everything |
| `_harness/auto/ledger.md` | Passed cards, compacted when it grows |
| `_harness/auto/tracker.md` | The tracker the driver redraws after each feature: a table and a flowchart coloured by status |
| `_harness/auto/cards/<slug>.md` | One card per feature |
| `_harness/auto/exit.md`, `STOP` | The note the driver writes when the run ends (exited, done or done_waiting); the owner's stop file |
| `scripts/auto/` | The driver: `run.sh` (the commands), `driver.py` (standard-library Python), `card.sh` (checks a card), `tracker.sh` (redraws the tracker) |

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
  session_hours: 4
```

`enabled: true` lets `run.sh start` begin a run; the owner sets it. `budget_usd: 0` refuses to start a run. `loop.feature_budget_usd` must be above 0 too (the start suggests 15), and each session gets `--max-budget-usd` at 1.5 times it. Feature sessions use the models in `agents:`; the director runs on `auto.director_model`. With this module, `mode.bug_repro: fullstack` is recommended (one QA run per bug); it is a trial, so the owner turns it on before the run. A `loop.feature_budget_usd` set for a run also caps features outside runs; set it back to 0 after the run if you don't want that.

## Safety

The driver is a script, not an agent. It refuses to start inside a Claude Code session, inside a session it started, or on a dirty tree; runs every session with `--permission-prompts none` (anything that would prompt is denied) and `--max-budget-usd`, and refuses a Claude Code without those flags; never uses a mode that skips permissions; and pushes only the run branch and feature branches, never the integration, production or an environment branch. Each session runs with `MORPH_AUTO=1`, `MORPH_AUTO_SESSION` and `MORPH_AUTO_BRANCH`, and the guard then turns every ask into a deny and denies agent writes to the driver's files and `harness.config.yml`, writes to `docs/product/` outside a director session, pushes, merges, checkouts of the run branch, and PR writes on the code host (`harness/GUARD.md` § During an autonomous run). Outside a run the guard behaves as before.

## Starting over

To drop a run: delete the run branch (`git branch -D auto/v1`), its `feature/*` branches, and the live state folder `.git/morphness/auto/`. After a failed director, `run.sh start` tries again on the same branch without that.

## On install

- Needs `roadmap` in `modules`; if it is missing, add it first with `/morph-module add roadmap`.
- Put back the marked text (`module:autonomous`): the autonomous approver line in § Approval of `harness/templates/plan.md`, `small-plan.md` and `bug-plan.md`, and the § During an autonomous run line in `harness/GUARD.md`. `harness/TECHNICAL_LEAD.md` gets no line (it sits at its size cap): the driver's feature and resume prompts tell the Technical Lead to read § Run rules first.
- Copy `harness/templates/auto/` and `scripts/auto/`.
- Add read-only allow rules to `.claude/settings.json` → `permissions.allow`, so a run's sessions can use them with no prompt: `Bash(date:*)`, `Bash(git show:*)`, `Bash(git grep:*)` and `Bash(git rev-parse:*)`, and the formatter's check command when the project has one that only reads (`gofmt -l`, `prettier --check`). They stay on remove.
- When `project/CONTROLS.md` has a manual smoke, offer to make it a named check (`smoke`, a script under `scripts/` that builds the product and runs it against a scratch data folder): a run's sessions can't start the built product directly, but they can run `bash scripts/checks.sh run smoke`.
- Add the `auto:` block above to `harness.config.yml` with `enabled: false`, and `autonomous` to `modules`.
- Ask the owner whether to set `mode.bug_repro: fullstack`, with the reason above.
- Tell the owner that `/morph-auto start` is the next step when they want a run: it writes the brief and sets the budgets.

## On remove

When the project doesn't choose this module, morph-init deletes this folder and the items below, then the empty `harness/templates/auto/` and `scripts/auto/` folders. Run files a past run left (`docs/brief.md`, `docs/product/`, `_harness/auto/`, the checklist's § Needs you and § Harness changes) stay: they are the project's.

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
- `scripts/auto/run.sh`
- `scripts/auto/driver.py`
- `scripts/auto/card.sh`
- `scripts/auto/tracker.sh`

**Delete the marked text:** every span and line marked `module:autonomous`, with the command in [harness/README.md](../../README.md) § Modules → **Module markers**.

**Delete or reword these lines** (unmarked: config text):

- `harness.config.yml`: delete the `auto:` block and its comment, and remove `autonomous` from `modules`.

**Unlink:** every Markdown link left pointing into `harness/modules/autonomous/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/autonomous' --include='*.md' . | grep -v '^./harness/modules/'`.
