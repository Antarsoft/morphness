# Changelog

Releases, newest first. They are named by semantic version (`v0.13.0`); the releases before that were
named by date, and the [version map](#version-map-for-the-dated-releases) at the bottom gives each one
its version. Installed copies pick up kit changes (each with a note in
[updates/](updates/)) and new matching lessons through `/morph-update`; this file lists every change.
When releases are cut: [CONTRIBUTING.md](CONTRIBUTING.md) § Releases.

## v0.18.0 (2026-11-09)

- The autonomous module's driver: `bash scripts/auto/run.sh start` checks the brief and budgets, creates the run branch and has the director write the product docs and feature order; `approve` records the owner's one approval; `run` builds the features one at a time, each in its own headless session with `--permission-prompts none` and `--max-budget-usd`, checks every card against the feature's plan and QA result before merging it into the run branch, copies the card's § Owner items into the version checklist, and redraws `_harness/auto/tracker.md` (a table and a Mermaid flowchart coloured by status). It exits on a feature's tries used up, the run budget, hours, features or a stop request, writes `_harness/auto/exit.md` with what the owner has to do, and `resume` carries on. Waiting features hold their dependants, splits and bug fixes go into the order, and a departure or an owner edit to the docs triggers a re-plan. The live state and session logs stay in the git folder, out of every branch. A stub-`claude` self-test covers 25 scenarios.

- In an autonomous run, the feature prompt now names the exact feature folder (`_harness/features/<slug>/<version>/`), and `plan-brief.sh` refuses another slug. A session that still writes its records under the slug without the driver's `-<n>` suffix (`fix-app-shell` for `fix-app-shell-1`) no longer stops the run: the driver reads that folder and prints a warning with the `git mv` to rename it.

- New optional `autonomous` module, rules and templates first: an unattended run from a product brief to the first version on its own branch (`auto/v1` by default). An Opus director writes the product, tech, design and finance docs and the feature order, the owner approves them once, and each feature then runs through the normal harness in a fresh session. The Technical Lead approves its own plans under the module's run rules, writes owner-only items to the feature's steps file as usual, and ends each feature with a short card for the features after it. A run stops when a feature runs out of tries, a run limit (budget, hours, features) is reached, or the owner stops it. The module adds `harness/templates/auto/`, an `auto:` config block (off), and one line in each plan template's § Approval, marked so that installs without the module are unchanged; `harness/TECHNICAL_LEAD.md` is untouched. `/morph-module` and `/morph-doctor` know it.

- An autonomous run no longer loops on fixes. A bug a feature reports in the harness's own files (`scripts/`, `harness/`, `project/`, `.claude/`, `_harness/`) goes to the harness backlog and the checklist's § Harness changes, never to an inserted fix feature. A fix feature can't spawn a fix of itself either: its follow-ups go to the backlog. The feature prompt and the card template say so.

- In an autonomous run, a fix the run inserted can now end as "not a bug". The card takes `status: not-a-bug` with a `reason:` (not-reproduced, product-decision or duplicate) and its `evidence:`. The driver marks the feature skipped and carries on, where before it stopped the run because no feature folder existed. A product decision also needs an owner item to confirm it. A § Bugs found line that names an assumed decision (`D2`) or an owner item goes to the checklist's § Needs you instead of becoming a fix. After a "tries used up" exit, resume gives the retry the exit reason and the stopped card's own explanation.

- In an autonomous run, a feature session now gets the owner's answers recorded since the feature started. That means a new row of theirs in a version doc's Decisions table, or an owner item they ticked or annotated in the checklist or `steps/`. It follows those answers instead of asking again. A feature whose card waits on items the owner has already answered gets one more session with the answers, so it doesn't go to `waiting_owner` again.

- In an autonomous run, a feature sees every decision the owner recorded in a version doc's § Decisions table, including ones recorded before it started, so it doesn't wait on a question the owner already answered. When a later feature reports a bug that a fix already covers, the run doesn't insert a second fix.

- Fixes from the first real autonomous run, a ten-feature Go command-line tool built from a brief. Feature sessions now get told how to work with no prompts: one command per call, named checks through `checks.sh`, scripts by relative path, and a denied chain retried one command at a time. Run rule 5 says the same. The driver reads a QA verdict in every shape QA writes it (`- **Result:** pass`, a bare `**pass.**` under § Verdict, or a header `**Verdict:** pass`). Before, it stopped the run on work that had passed. Ledger compaction runs only when more than five whole cards are there to fold, and it keeps the ledger when the copy isn't smaller. The module's install adds read-only allow rules (`date`, `git show`, `git grep`, `git rev-parse`, a read-only formatter check) and offers a `smoke` named check.

- In an autonomous run, the risk check and the QA hand-off measure a feature from the run branch it left, not the integration branch. A two-file fix no longer shows every feature the run already merged, so it isn't raised to full mode, and QA reviews only that feature's diff. Outside a run nothing changes.

- The autonomous driver now handles a Claude Code that isn't signed in. Before, an expired sign-in counted as a crash: it used up crash retries, and after a failed director it committed a "draft" that didn't exist. A session that can't authenticate now ends the run at once and uses no try. The feature stays to do, and `exit.md` gives the steps: type `claude`, then `/login`, then `/exit`, then resume. `start`, `run` and `resume` check the sign-in before they make a branch or a commit (`claude auth status`, then a one-word session costing about a cent). The driver commits nothing when the director wrote no docs. While a session runs, the terminal now shows a line for each file it writes or command it runs, and "still running" after two quiet minutes. Session logs are written as the session streams (`.jsonl`).

- `small-bug` is now defined: a small-mode bug fix with no plan file, failing test first, then the fix (`harness/MODES.md` § Fixing a bug, the card template and the feature prompt). In an autonomous run, a `small` card for such a fix no longer stops the run. When the branch has a failing-test commit followed by the fix, the driver checks it as `small-bug` and prints a warning. Otherwise the exit says to relabel the card `small-bug`.

- `checks.sh run <check> <path>` no longer crashes. It refuses anything that isn't a check name and says how to run one test file instead. In an autonomous run, a card can report a bug in the harness itself as `- harness | what | where`. It goes to the checklist's § Harness changes, and the session is no longer restarted.

- **`checks.sh status` says clean on a clean tree.** Its header said "uncommitted changes" on every run because it read git's empty output as a failure; only the label was wrong. The prune now counts an action item with a status outside `open`, `approved`, `deferred`, `applied` and `skipped` as `open` and sweeps it with the leftovers. `/morph-init` no longer suggests leaving `e2e-targeted` and `e2e-repeat` out of `checks.before_qa` when the browser-e2e module is on, matching the module and the Full-stack docs.

- Plans now spell out interface edge cases. A new plan checklist item (41, in Testing) turns each edge-case row a design doc lists for an interface into one acceptance criterion with a test, and the code scout names the edge cases the existing code doesn't handle. In an autonomous run, the director writes those rows in `tech.md` § Interfaces between features for every interface (empty input, boundaries, a call before ready, errors, time edges). A card's § Bugs found line now has a kind and a reproduction, and only a behaviour bug with a failing test or steps becomes an inserted fix feature. Style notes go to the next feature built on that code, docs notes to the harness backlog, and decisions and unreproduced bugs to the owner.

- The guard knows an autonomous run: in a session `scripts/auto/run.sh` started (`MORPH_AUTO=1`), every ask becomes a deny, and it denies writes to the driver's files and `harness.config.yml`, changes to `docs/product/` outside a director session, `git push`, `merge` and `pull`, moves of the run branch, and PR writes on the code host. Outside a run nothing changes. 38 new guard cases, among them the same calls passing outside a run.

- The guard now asks before `git grep -O` (`--open-files-in-pager`), which runs the command it names. A read-only `git grep` allow rule, such as the one the autonomous module adds, can no longer run a command with no prompt.

- The guard no longer asks before the Claude Projects thread tools. A project thread ends every turn with one of them (a reply, a reaction, `no_reply_needed`), and the guard read them as connector writes, so a thread running on the owner's computer stopped for a prompt on every turn. Replies, edits, reactions, the progress checklist, decision cards, resolve and reminders, thread renames and messages to the coordinator or another thread now pass. Connecting a device, starting or stopping Remote Control, offering connectors and switching the model or effort still ask, and so does any other connector's tool with the same name.

- New `/morph-auto` skill for the autonomous module. `start` writes the brief with the owner, sets the budgets and gives the terminal steps. `approve` reviews the product docs, the cost estimate, the assumed decisions and the owner items before the owner's one approval. `status` reports progress, spend and what the owner needs to do. `stop` asks the run to stop. `resume` walks through the exit report's items, and the owner's direction after an escalation. `pr` merges the integration branch into the run branch, runs the sign-off checks and opens one PR. The driver runs only from a terminal, so the skill prepares each step and gives the command. `/morph-init` asks whether to add the module (default no) once a roadmap is chosen.

- Agents can run one test file without a prompt. `/morph-init` now allows each test runner's single-file form next to the named check that runs it (`Bash(npx jest:*)` next to `npm test`), and `/morph-doctor` warns when a runner has none. QA retries a refused command through the named check, records it, and writes `blocked: permission` instead of leaving `qa-result.md` missing. In an autonomous run, the driver tells a missing, blocked and failing QA result apart. When a refused command caused the stop, `exit.md` names it, including one refused inside a subagent, along with the allow rule to add.

## v0.17.0 (2026-11-07)

- `scripts/handoff.sh` now compiles an agent brief for the Full-stack engineer and QA: the project addendum, `.claude/rules/testing.md`, the path rules and the project docs the role reads before starting, without comments or empty template headings, in one file in the git folder that is rebuilt at every hand-off. The prompt names it on a new `Agent brief:` line, and the role bodies read it instead of the five to seven files it holds, one call instead of one per file.

- A new `loop.retro_every` setting lets the Technical Lead decide several features' retro action items in one pass. At `1` (the default), items are decided at each feature's close, as before. At a value from `2` to `5`, items stay `open (batched)` until `scripts/prune-counter.sh` prints `Retro decisions are DUE: <files>`, and then they are all decided together. An item from an **Escaped** line, or one the owner decides, is still handled at once.

- A small-mode bug fix that finds an adjacent defect it can only fix on a risk path, such as the `id` tie-breaker of an order or an edge input its own failing test names, now goes to bug mode for the whole fix instead of listing the defect as out of scope and finishing. `harness/MODES.md` § Fixing a bug says so; same-pattern hits in other places still stay out of scope.

- A trial switch, `mode.bug_repro: fullstack`, runs bug mode with one QA run: the Full-stack engineer writes the regression test, commits it alone as `WIP(<slug>): failing test` before any product change, and then finds the cause and fixes it. `scripts/handoff.sh qa` checks that order (a test-only commit, nothing before it, the test unchanged since) on a new Bug order line, and QA runs the test against the code as it was at that commit. The default, `qa`, keeps the separate reproduction run.

- A new `code-scout` subagent (haiku by default; read and shell tools only) maps the code a full-mode change touches before the plan: files, line ranges, contracts, callers, tests, conventions and adjacent defects. The Technical Lead reads only the line ranges the plan changes and checks the callers itself, so the main chat no longer carries whole source files through the rest of the feature.

- A trial switch, `mode.risk_by: change`, lets `scripts/risk-check.sh` send one kind of change to a risk-path file to small mode: an ordering or paging edit, where every changed line is an `order`, `sort`, `limit` or `range` call (or similar), a blank line or a comment, at most `mode.contained_max_lines` lines in an existing file, with no risk word in the functions it sits in. It prints a `~` line and asks for one code review. Areas about sign-in, secrets, money or the database, new files and `--force full` stay full, and a branch that changes the switch or § Risk paths is a risk path itself. The default, `file`, keeps the path-level check.

- `scripts/checks.sh` now reads a project's own changes to the documentation-only list from `checks.doc_paths_add` and `checks.doc_paths_remove` in `harness.config.yml`, so a path the project removed (a docs site built from its markdown) is checked as code and one it added is skipped like documentation. Scripts, hooks, settings and `..` paths never count as documentation whatever the lists say. The lists live in the config, which agents can't write, and not in `project/CONTROLS.md`.

- `scripts/evidence.sh`, the summary `/morph-share` offers to publish, no longer carries cost: the **Cost** line, the prune window table's **Avg cost** column and the cost caveat are gone, and `--json` drops `avg_cost_usd`, `median_cost_usd` and `cost_measured` (overall and per window). A cost shared without the feature's size, mode and model says more about the owner's spend than about what the harness caught, decided and learned. `/morph-share` adds no cost note to a summary or its PR, and `showcase/twinpage.md` drops its cost line, column and owner note. Cost tracking for the owner (`scripts/feature-cost.sh`, the learnings **Cost** line, the prune counter) is unchanged.

- A new `feature-closer` subagent (haiku by default, no web or MCP tools) drafts the closing records after a full- or bug-mode QA pass: the steps file, the plan's passed status and the learnings file with the cost line pasted from the script and every action item left open. The Technical Lead checks the draft, decides the items and commits, so the close no longer prints the long SETUP sections into the main chat.

- `scripts/feature-cost.sh` with no option still counts the whole session, but when that session began more than three hours before the branch's first commit, the `Cost ≈` line now says so and asks for `--since`, so a figure that holds other work isn't read as the feature's cost. `tests/known-gaps.md` words the remaining limit.

- `harness/GUARD.md` § Asks lists the commands that move an environment branch in the local clone, which the guard asks about since the previous change; the README and site list them too, and the site's "Asks you" card now matches the README's (git hooks, `git config` keys that run commands, `git reset --hard`, wide deletes).

- The guard now asks before a command moves an environment branch in the local clone: `git update-ref` on it (as `refs/heads/<b>`, `refs/remotes/<remote>/<b>` or a bare `<remote>/<b>`), `git update-ref --stdin`, a `git fetch` refspec that writes it, and `git checkout -B` / `git switch -C` with its name. The end-of-task checks and the merge gate read the project's checks from the integration branch as the clone has it, so moving that branch changed which commands they ran. A plain `git fetch origin <b>` still passes.

- The guard now asks before an Expo EAS call that can reach the app stores or the Expo project with the owner's login: `eas build`, `eas submit`, `eas update` (and `update:republish`, `update:rollback`), `eas deploy`, `eas env:create`, `eas credentials` and any other `eas` subcommand that is not a read, also through `npx eas-cli`, `pnpm exec` or `yarn eas`. Reads such as `eas whoami`, `eas build:list`, `eas update:view` and `eas env:list` pass (not with `--include-sensitive`), and so do `--help` and a leading `--version`. `eas login` and `eas logout` ask; `build:download`, `build:run` and `metadata:pull` pass. The classic `expo publish` (and `publish:set`, `publish:rollback`, `expo build:ios|android`, `expo upload:ios|android`) asks too; `expo start`, `expo install` and `expo prebuild` still pass. The `guard.deploys` switch turns these prompts off.

- A new `scripts/handoff.sh <role> <slug>` prints a subagent's prompt block from `harness/HANDOFFS.md` with every field a script can fill already filled: the feature folder, the code map's path and commit (dropped in bug mode), the path rules, and for QA the merge base, diff stat, untracked files and `checks.sh status`, for the closer the mode, commit and cost flag. It lists the placeholders left for the conversation and writes nothing. The plan brief now also holds the plan checklist's always-run groups and `project/PLAN_CHECKLIST.md`, and names the scout's `handoff.sh` call as the next step. A full-mode feature's main chat spent a turn printing each block and more turns filling it; each hand-off is now one call.

- `scripts/plan-brief.sh` gathers what a full-mode or bug-mode plan is written from (the risk check, the mode section, `testing.md`, the effort and QA-run sections and the plan template) into one ignored brief file, and the Technical Lead reads it in one call instead of printing each doc. It writes nothing for a plain change.

- While a full-mode plan is written, the guard denies the main chat a whole-file print of a source file over 80 lines (a Read without a range, `cat` and the like) and says how to read the code scout's line ranges instead. `guard.plan_reads: off` turns it off.

- `scripts/doc-section.sh` now says on its first line when the sections it prints together are over 12000 characters, and `harness/TECHNICAL_LEAD.md` tells the Technical Lead to keep each print under about 12,000 characters and to print files and sections in separate calls. A batched print that was cut cost the full-mode runs two more calls to read again.

- The security review before QA runs once; after a fix round it gets a second pass only when the review had `fix` items, and that pass covers the fix round's diff, not the whole change, with no 15-call minimum. A fix round that changed only tests, comments or files outside the review's scope needs no second pass. `harness/SETUP.md` § Code review before QA says so; `tests/known-gaps.md` words the cost accordingly.

- The code scout now writes its map to the feature's `Plan/code-map.md` instead of replying with it, and the Full-stack engineer, the code review and QA get the file's path in their prompts and read the code by its line ranges. In the benchmark the builder searched and read the same files the scout had already mapped, at several times the scout's cost; now the code is searched once per feature. The scout gets the Write tool for that one file and stays read-only otherwise; the Technical Lead may add a § Technical Lead notes section to the map.

## v0.16.0 (2026-11-04)

- **A new migration that only adds runs in small mode.** `scripts/risk-check.sh` reads a new `.sql` migration on a database risk path: when every statement only adds (new tables with row-level security, columns, indexes, policies and grants on the new tables), it prints `Mode: plain` with a `Needs:` line. The change then runs in small mode with the database tests and one code review (`harness/MODES.md` § Additive migration). Sign-in, secret, money and permission tables, edits to merged migrations and any other risk path stay full. The kit's self-test covers both sides.

- **A bug fix names and tests the edge inputs next to the symptom.** The small plan's § Bug and the bug plan's § Regression test gain an **Edge inputs** line: equal values, none, one, the limit and a last page that is not full, the ones that apply, each in the test. An order the bug touches ends with a unique key, so ties keep one order. The bug steps in `harness/MODES.md`, the bug-mode prompt blocks and the Full-stack bug rules ask the fix to hold for them, and only the reported case must fail before the fix. The kit's self-test checks the two templates.

- **A bug fix off the risk paths writes no plan file.** It keeps the failing test first, the root cause before the fix, the edge inputs and the checks, and records them in its commits and PR, as light mode does. It writes a learnings file only when something went wrong. The small plan template loses its bug section, and the kit's self-test checks both.

- **The fast checks run as code when a task ends.** The new `scripts/checks.sh` runs the checks in `checks.on_stop` (`typecheck`, `lint` and `unit`, plus `secrets` with the security module) from a `Stop` hook and a `SubagentStop` hook for the Full-stack agents. It runs only when the code changed. A pass prints nothing and costs no model turn, and a failure sends the agent back with the end of the log; a fix that still fails goes back again, at most `checks.stop_retries` times in a row. Commands come from `project/CONTROLS.md` as committed on the integration branch, because the hook runs outside the guard, and the guard asks before a tool-call write to the records in `.git/morphness/`. A secret scan keys on every file, documentation included. Full-stack and small mode write `end-of-task hook` for those checks, and QA and the merge gate read `bash scripts/checks.sh status` instead of running them again.

- **The README, the site and the results page say what the kit does.** The README and the site lead with the guard: what it blocks, what it asks about, when it blocks because it can't run its check, which tool calls it sees and its limits. They name the one-agent default and which modes have a QA agent, say prunes only propose cuts, and state the cost without numbers: small mode costs more than a plain session, full mode several times as much. `scripts/lesson-stats.sh` also checks the per-folder lesson counts and how many lessons have no `fired` count. A new `.github/workflows/release.yml` runs the results page at each release tag and fails unless the page is the run at that tag (`scripts/trust-report.sh --check-release`), then opens a PR with it. The badge names the release, the commit and the date it tested, and `trust-report.sh` no longer marks every run as having uncommitted changes. `tests/known-gaps.md` lists more of what the kit does not check, and claims whose only proof is a sentence in the kit's text count as present, not tested.

- `scripts/session-start.sh` puts `--ignore-scripts` right after each package install's subcommand, wherever the install sits in the install command: after `cd app &&`, a `NODE_ENV=…` prefix or `then`, behind `npm --prefix` or `pnpm -C`, inside `( … )`, before a redirect such as `2>&1` or a comment, and in every install of a chain. Before, only a line that started with the install got the flag, at its very end, so `npm ci && npx prisma generate` ran npm's lifecycle scripts and passed the flag to prisma. A command after the install no longer gets the flag, an install where the owner wrote the flag is left as written, and an install behind `env`, `sudo`, `timeout` or `corepack` is still left alone.

- `scripts/install.sh` now ends with every kit file in place or stops before copying and says why. It stops when the repo has its own `.claude/settings.json` without the guard hook (run `/morph-init`, which merges it and calls the script with the new `--merge` option), its own file at a kit script path such as `scripts/guard.sh`, a `.gitignore` rule that would leave kit files such as `.claude/settings.json` out of every commit, a kit folder that is a link (its files would land outside the repo), or a file where the kit needs a folder; before, most of these copied the rest and exited 0 with the guard unwired. A repo an earlier version already copied into, with the user's own `scripts/guard.sh` in place, stops the same way when `/morph-init` runs the copy step. The script stages the files and moves them in with `harness.config.yml` last, so a copy that stops half way is finished by running it again, which copies only what is missing (also for a copy an earlier version left half done, and `/morph-init` now runs the copy step for one). It no longer makes a user's own scripts executable, and an `AGENTS.md` that links to `CLAUDE.md` is kept as one file that `/morph-init` writes the kit's text into once.

- **Every session loads an 8 KB core.** Claude Code now loads only `CLAUDE.md` and `AGENTS.md` in every session, about 8 KB instead of about 35 KB. `harness/TECHNICAL_LEAD.md` is read when a full or bug mode plan starts. The guard's full list moves to the new `harness/GUARD.md`, which every guard deny names. Each `.claude/rules/` file has `paths:` and loads only when a matching file is read or edited: `harness.md` for plans and records, `testing.md` for tests, and new `data.md` (migrations and schema), `auth.md` (sign-in and access) and `deploy.md` (CI and deploy config). The Full-stack and QA prompts name the path rules a plan needs. The `Rules:` gauge prints a token estimate and the size of the agent and skill descriptions. The new `loop.owner_rules_kb`, set by `/morph-init`, gives an owner's existing `CLAUDE.md` its own allowance. `loop.rule_budget_kb` defaults to 16.

- **A full-mode feature keeps one plan file and one closing record.** The owner's request is `plan.md` § Request (no `feature.md`). The retro lives in the feature's learnings file, with § What went wrong and action items only when something did (no `retro.md`). After QA pass the main chat reads QA's record instead of re-running the checks, Full-stack updates the project fact docs as plan steps, and the close takes three steps instead of a retro file and its checks. The plan checklist's group index moved into `harness/TECHNICAL_LEAD.md`, so the main chat prints only the groups a plan needs, in one call.

- **QA reviews the diff in one pass, at `medium` unless Full-stack is `xhigh`.** The QA prompt now hands over the merge base, `git diff --stat`, the untracked new files and `bash scripts/checks.sh status`, and the new `harness/agents/qa-engineer.md` § Lean QA has QA read the change through `git diff <base>`, test each criterion once, run each check once and skip any check the end-of-task hook already passed on the final code. `agents.qa.default` is `medium` and `qa-engineer-medium` is the default QA agent; QA runs at `high` only when the plan's Full-stack effort is `xhigh`, and a risk path or a data-access feature no longer raises it on its own (the risk-area rule now says Full-stack is never `medium`). The morph-init model table and config example say the same, and the kit's self-test checks the Lean QA wording, the QA prompt block and the config default.

- `scripts/check-lessons.sh` and `scripts/check-updates.sh --since` stop a new or changed lesson or update note (agents paste or follow every part of one) that has a URL or host, a network or remote-shell command, a command that installs or runs text, an environment dump, or mentions the guard, settings, the harness config, permissions or secrets, until a maintainer has read it and the file says `reviewed: <why it is safe>`. A later change to a reviewed file needs a new reason, and CI prints each reviewed file's flagged text as a warning. Before, a lesson telling agents to send `env` to a host and turn the guard's network check off passed both checks. The lessons workflow runs the check on what a PR changes. `/morph-share` passes the project's own names (owner, repo, branches, environments, apps, variable names) to the check, which now matches them as whole words rather than as a regex, and searches its drafts for hostnames and email addresses before showing them.

- **The main chat prints the mode sections it needs instead of reading `harness/MODES.md` whole.** The mode line in `AGENTS.md` § Golden rules prints § Choosing mode and then the chosen mode's section with `scripts/doc-section.sh`, and no longer links the whole file. The kit's self-test checks it.

- `/morph-init` writes `.claude/settings.json` as its last file (render.md § 6b), after building it away from the repo and checking that it parses, holds no `{{` and runs the guard, so the guard turns on only when every other file is final: an install no longer stalls on guard prompts for its own config, script and workflow writes. Claude Code asks once before that write; an unattended install leaves the checked file in `_harness/pending/settings.json` for the owner to move into place, and the next `/morph-init` (or `scripts/install.sh`, which now says so) picks up from there and commits. `scripts/install.sh --merge` (the copy step morph-init runs) leaves that file to it. The render's searches for placeholders and fill comments name the kit's folders instead of `.`, so the guard allows them in a repo with a `.env`, and they look for the kit's own placeholder keys, so a project description with `{{name}}` in it no longer reads as "not set up" (also in `install.sh`, `/morph-update`, `/morph-module` and UPDATE.md). `scripts/session-start.sh` doesn't record commands that are still placeholders as its pin, so the first session after a by-hand install runs the real ones (an existing pin still holds back a changed command). When a repo's own settings choose a different `model` or `defaultMode` than the answers, morph-init asks once and records the choice, and `/morph-doctor` reports a settings `model` or `defaultMode` that disagrees with the config, and a ci-cd module with no CI workflow.

- `.claude/settings.json` no longer allows WebFetch on the whole of `api.github.com` and `raw.githubusercontent.com`. Those rules let any page on either host through with no prompt. The update checks read GitHub through the repo-scoped `gh api` and `curl` rules they already had, and WebFetch now asks.

- **Plain changes run with one agent.** When `scripts/risk-check.sh` prints `Mode: plain`, light and small mode run no subagent. The main chat follows the builder's rules (and QA's for UI changes), runs the checks and, in small mode, fills the plan's new § Check on the final commit; the merge gate accepts § Check as the record. The Technical Lead, Full-stack and QA split, and the "never codes" rules, are now for full and bug mode. Forcing plain on a risk path now means no QA agent. `scripts/evidence.sh` leaves small-mode features out of its QA figures. The Full-stack light-mode brief is gone.

- **Rules that said two things now say one.** The browser suites (`e2e-targeted`, `e2e-full`) run for every change; `harness/CONTROLS.md`, `project/CONTROLS.md`, the PR template and the plan template no longer limit them to screens, auth or a public API. A parallel plan's merge goes back to QA under § After merging the integration branch instead of the Technical Lead running QA's checks. The long-output golden rule shows the log recipe instead of a pipe through `tail`, which reports the wrong exit code. `harness.config.yml` → `agents` is the one source for models: `project/HARNESS_AGENTS.md` names the config key, and `/morph-doctor` compares each agent file's model and effort with it. `harness/PLAN_CHECKLIST.md` loses its duplicate § How to use it. A message to a thread asks for an action, one rule in `harness/HANDOFFS.md` § Threads. Vague words ("useful" tests, "setup cost is reasonable", "prefer files over memory") are replaced with tests an agent can apply. The kit's self-test now renders the shipped Sonnet preset and checks that the config, the agent files and the settings agree.

- Installs and updates are pinned to a commit. `INSTALL.md` and the README's by-hand steps clone the newest release tag instead of the default branch, and `/morph-init` records the full commit with the release (`v0.15.0+ce3921d` when the source is past a release). `/morph-update` resolves the newest release tag to its commit, shows both commits, reads every file at that commit, and stops when the tag a copy was installed from now points somewhere else, or when the release offered and the copy's base have split apart: a moved tag or rewritten history can mean the upstream repository was tampered with. A copy taken from the default branch past the newest release is told there is nothing newer. A release tag moved forward onto a new commit before a copy ever saw it can't be told apart from a real release. Community lessons you decline or answer "later" get a ledger in `installed_from.lessons`, so a lesson put off is offered again. The kit's self-test replays updates with owner edits right next to upstream changes (a scripted conflict resolution that must keep both sides), changed config values, an update put off for one run and applied on the next against its recorded base, and the `installed_from` record; STABILITY.md says the replay merges with git while a real update's merge is done by the model. The guard lets that commit comparison through: a `curl` of a Morphness URL now asks only for a `.` or `..` path segment, checked after decoding, instead of any `..` in the URL.

- **A script picks the mode.** `scripts/risk-check.sh` reads the files a change touches and prints `Mode: full` when one is on a risk path (new `project/CONTROLS.md` § Risk paths), when the change deletes stored data, or when more than `mode.plain_max_files` files change; otherwise `Mode: plain`. `harness/MODES.md` § Choosing mode is one ordered list built on it: questions are research, reported breakages are bug mode, other changes go full or plain by the script, and plain is light mode only when nothing behaves differently. The script runs again on the real diff before the hand-off, the human's wording never lowers the mode, and the owner can force either. In light mode the Technical Lead edits documentation itself, and a question one or two files answer gets a direct answer. `/morph-init` asks for the risk paths with the risk areas.

- **The code review before QA runs on every risk path, and `xhigh` is for sign-in, secrets and money.** Every full or bug plan whose risk check names a risk path now gets the Technical Lead's read-only code review before QA (`/code-review medium`, or `high` when Full-stack is `xhigh`), not only `xhigh` plans. The security review runs for changes to sign-in, access rules, secrets, money and public APIs; a risk path outside those gets the code review alone. Full-stack runs at `xhigh` only for sign-in and sessions, secrets and money; tenancy, access rules, concurrency, public APIs and new architecture run at `high` with the review. The plan templates, the Technical Lead rules and the security module say the same, and the kit's self-test checks it.

- **Rules reach the agent they are for.** Full-stack and QA read `.claude/rules/testing.md` before they start; Claude Code never loaded it for them, since subagents run with `omitClaudeMd`, though every lesson about tests lands there. `.claude/rules/harness.md` drops the bullets addressed to subagents, and Full-stack reads a short summary of the guard in its role body instead of all of `AGENTS.md`, the Technical Lead's file. The researcher gets no edit tools (`disallowedTools` now includes `Edit`): it replies with its sections and the Technical Lead writes them into the research file. The agent files say to read the role body in full rather than listing sections. `/morph-init` copies rules a builder needs from an existing `AGENTS.md` or project rule file to `project/agents/<role>.md`.

- **The Technical Lead prints the section a step needs instead of reading whole harness docs.** The new `scripts/doc-section.sh` prints named sections of a Markdown file (or lists its headings). `harness/TECHNICAL_LEAD.md` names the few files read in full and gains § Full mode, step by step, the section to print at each step. The plan checklist is printed by group, only the groups that apply, and each subagent prompt block in `harness/HANDOFFS.md` has its own heading. The kit's self-test runs the script and checks that every section the docs name exists.

- **A bug fix off the risk paths runs in small mode, failing test first.** The Technical Lead runs `bash scripts/risk-check.sh` on the files a fix will touch: `Mode: full` (or a production hotfix) is bug mode as before, and `Mode: plain` is small mode with the new `harness/MODES.md` § Fixing a bug. There, the main chat commits the regression test failing before any fix, writes the root cause first, makes the smallest fix and keeps the learnings file's **Escaped** line, with no Full-stack or QA agent. The small plan template gains § Bug, and `AGENTS.md`, `harness/TECHNICAL_LEAD.md`, `harness/SETUP.md` and `.claude/rules/testing.md` say the same. The kit's self-test checks the new routing and section.

## v0.15.0 (2026-11-01)

- `scripts/feature-cost.sh` no longer dies on one bad transcript line: torn lines, bad bytes, a byte-order mark, string token counts and timestamps without a zone are skipped or read, and skipped lines are counted on the `Cost ≈` line. A call copied into a resumed session counts once, Python runs isolated (`-I`) so a `json.py` in the project can't run in its place, an emoji in the project path no longer hides the transcripts, and the exit codes say what happened: 2 for an unknown option, 1 with a `not measured` line when the script fails (both were 0). With `--since`, a call whose time can't be read is left out and counted on the Cost line. `harness/MODEL_PRICES.md` prices Sonnet 5.5 cache reads at the published $0.10 per million tokens (was $0.20), which brings the estimate in line with Claude Code's own `total_cost_usd`, and says how to check the table against it.

- **Guard: a broken config can't unprotect the environment branches.** When `scripts/guard.sh` can't read the branches from `harness.config.yml` (the file missing or empty, a branch key not found, a value that isn't a branch name), it blocks every `git push` instead of letting pushes to `main` through. Without `awk` it blocks every call. `scripts/lib/config.sh` now reads a byte order mark, Windows line endings, quoted keys, anchors and a one-line `environments: [ … ]` list, and `config_get_all` reads a repeated key, whose values the guard all protects. A `.gitattributes` keeps the scripts and the config on LF line endings in Windows checkouts. `/morph-init` fills or drops every `{{branches.*}}` line in `.claude/settings.json` when the two branches are the same, and its self-check fails on a `{{` left there.

- **Guard: exfiltration and remote writes.** A command that prints the whole environment (`env`, `printenv`, `export -p`, `set`, also behind `sudo` or redirected) is denied, and a deny anywhere in a command now wins over an ask, so `env | curl -d @- …` or `curl …; git push --force` no longer stop at a prompt one yes would pass. Migrations with `atlas`, `sqitch`, `flyway`, `goose`, `dbmate` and `liquibase` are denied against a non-local database and ask when the target isn't on the command line. `gh gist` writes ask, MCP tools named for `destroy`, `purge`, `terminate`, `scale`, `flush`, `overwrite`, `restart` and similar verbs ask, and `WebFetch` now passes through the guard, which asks on GitHub pages outside the Morphness update paths.

- **Guard: blocks the call when it can't run.** The hook command in `.claude/settings.json` turns any exit other than 0 and 2 into a block, so a missing `scripts/guard.sh` (or `bash`, or `CLAUDE_PROJECT_DIR`) no longer lets every call through unchecked. The hook has a 60-second timeout, and the guard ends its own check at 15 seconds and blocks, because Claude Code runs a call whose hook times out; a `git` call that doesn't answer within 5 seconds blocks too, where its empty answer used to let a bare `git push` on `main` through. A long argument list no longer makes the guard slow (one check ran once per argument). The self-test runs the hook command as Claude Code does: with the script missing, with a crash, with 20,000 arguments and with a hanging `git`.

- **Guard: fewer false alarms.** `psql -h /tmp/<socket folder>` and other database clients on a Unix socket count as local. A recursive `grep` or `rg` over a folder with a secret file reads its `--include`, `--exclude`, `--exclude-dir` and `-g` filters as each tool does (order, letter case, path globs), is denied only when a secret file is still searched, and names the filters that leave each one out; an exclude for `.env*` no longer lets the search read a key file next to it.

- **Guard: `git config` that sets a command asks.** `git config`, `git -c`, `git --config-env` and `git clone -c` now ask before they set a key git later runs as a command or reads as a file: the hooks path, `core.sshCommand`, the pager and editor, `credential.helper`, aliases, filters, `include.path`, `trailer.*.command` and similar keys, a section renamed into one of them, and a clone or init `--template`. Before, `git config alias.p '!git push origin main'` followed by `git p` pushed past the guard. Reading or removing a key still runs, and so do `git -c core.editor=true` and `git -c core.pager=cat`.

- **Guard: one approval can't switch a protection off.** Every tool call that writes `scripts/guard.sh` or `scripts/lib/` is denied, including copies, links, downloads, patches, archives and `git restore` or `stash pop` that bring another copy, many of which used to run without a prompt; removing `scripts/` or `.claude/` is denied too. A change to `.claude/settings.json` or `harness.config.yml` goes through Edit or Write, and the guard denies one that removes the guard hook, a deny or ask rule, a `guard:` switch, an allowed host or an environment branch, or that sets `env` or adds a hook command; other changes still ask. `/morph-update` hands guard file updates to the owner, and `/morph-doctor` reports a guard that differs from the kit's, a changed hook, a missing deny rule and every switch that is off.

- **Guard: secrets by target, not only by name.** A symlink to a secret file (or into `~/.ssh`) is treated as the secret, also through a glob, after a `cd`, and with `grep -R`; `ln` to a secret is denied. The guard's own files and `settings.local.json` match in any letter case, as they do on macOS and Windows disks. New secret names: `*.tfvars`, `.dev.vars`, `kubeconfig`, `.dockercfg`, prefixed service-account and Firebase Admin keys, `secrets.sops.yaml` and `supabase/.temp/`. The Grep tool over a folder holding a secret file now asks unless its `glob` or `type` leaves the file out, and a tree too big to check asks.

- A feature PR is marked ready only when no more code will land on its branch (`harness/RELEASE.md` § Feature PRs).

- `scripts/session-start.sh` keeps step output in a private temp folder instead of a guessable `/tmp` name, writes a changed PATH to the session's env file quoted, bounds each step with perl where there's no `timeout` (stock macOS), and says when `python3` is a stub or older than 3.7 (the guard can't run on one). The module removal command in `harness/README.md` handles paths with spaces and no longer waits on stdin when nothing matches. `scripts/install.sh` and `/morph-doctor` now describe what really happens without python3 or awk, check grep, sed, sort, tr and wc, and name a python3 that can't run the guard. `scripts/trust-report.sh` checks gitleaks against checksums pinned in the script, times out stalled downloads, and extracts on Pythons without tar filters. The kit self-test runs shellcheck (`STRICT=1` needs it) and fails when the guard's program nears Linux's limit for one argument.

- `scripts/prune-counter.sh`, `scripts/evidence.sh` and `scripts/learned-rules.sh` stop with a message instead of passing silently. The prune counter exits 2 with a `not measured` line when a tool it needs (awk, git, python3 and the like) is missing or a record it reads isn't UTF-8 (exit 1 still wins when a size budget is over); it used to print blank gauges, skip the size budget check or drop the trial lines. A budget written `09` is read as nine, a prune proposal with spaces in its name is found, and all three reject unknown options. `/morph-doctor` reports a `not measured` line as a cause to fix, not drift. The kit self-test now checks every field name of `evidence.sh --json` and its options, fails under `STRICT=1` without the oldest supported release tag, and checks that an update leaves a project's run records byte for byte.

## v0.14.0 (2026-10-21)

- **Claims ledger in the self-test.** `tests/claims.jsonl` and `tests/claims.md` list each promise the README makes next to the check that proves it, and `scripts/kit-selftest.sh` fails when a listed promise has no proof. The self-test workflow now also runs when the ledger changes.

- **Config: `loop.feature_budget_usd`.** An optional soft spend cap per feature, off by default (`0`). With a number set, `scripts/feature-cost.sh` prints a `Budget:` line before its `Cost ≈ $…` line, and the Technical Lead runs it after each subagent returns; when the estimate is over, it stops, says where the feature stands and asks the owner whether to continue, raise the cap or stop. The figure is an estimate at API list prices checked between steps, so a step already running isn't cut off. `/morph-doctor` reports the value.

- **Learned rules list.** `bash scripts/learned-rules.sh` prints every rule that carries provenance (`(from <slug>, <date>)`, `(lesson: <id>)`, `(trial: <slug>)`): where it is, the finding it came from, the day it landed, the last day a learnings entry said it fired, and its text. Rules without a tag are counted per file, and `--all` lists them with blank columns. Last fired comes from a new optional `**Fired:**` line in the learnings entry (the source slugs of tagged rules that caught something), which the prune keeps when it folds the entry. `/morph-doctor` runs the script as a new section and reports the counts. Read-only.

- **Lesson age and counts.** `/morph-init` and `/morph-update` now show each offered lesson's report count, the date it was added and last reported, and `fired` of `features`, defined in `lessons/README.md` § Listing a lesson. The numbers are context for reading a rule: lessons are not sorted or filtered by them and are never described as popular.

- **Release PRs run the public tool report.** A new `release-check.yml` workflow runs on pull requests that change `.claude-plugin/plugin.json` (release PRs) and prints the public tool report in the check output. It reports only and never blocks the merge.

- **Trials by default.** A retro item that changes how a role works (an agent file, a role's model or effort, a rule a role follows) is now approved as a trial by default: the rule lands tagged `(trial: <slug>)` with a trial file and Baseline, runs its length, and is decided at the prune only after the escape window of one prune window has closed. Project facts, mechanisms and owner-marked permanent items skip the trial. The retro template's Decision gains `approve (trial)` and `approve (permanent, why)`.

## v0.13.0 (2026-10-21)

- **Guard: `find` that deletes the repo asks.** `find . -delete` or `find -exec rm {} +` from the repo root or outside it, with no name, path or age filter, now asks like `rm -rf .` does. Filtered clean-ups such as `find . -name '*.log' -delete` still run. AGENTS.md and the known limits on the results page also say that a project-wide search can print lines from a secret file and that reads outside the project aren't blocked.

- **Guard: fewer false prompts.** Reading Claude Code's own saved long output (`~/.claude/projects/<this project>/<session>/tool-results/…`) with the Read tool, Grep or `cat`, `head`, `tail`, `sed -n`, `grep` and similar no longer asks; writes, other projects' folders and everything else under `~/.claude` still ask. `echo $r $(cat a) $(cat b)` no longer asks "builds the command name at run time" (the second `$(` was read as a command named `$`). Agents are told to write script files with the Write tool and run them in a second call (`harness/CONTROLS.md` § Command output), and the template allows `Bash(cat > /tmp/*)` for a heredoc under `/tmp`.

- **Config: `harness_schema`.** `harness.config.yml` now carries `harness_schema: 1`, the version of the config keys and `_harness/` record formats listed in `STABILITY.md`. It rises only with a major release. `/morph-doctor` reports a copy without it, or with a number it doesn't know, and points to `/morph-update` or a plugin update.

- **Init: what the model choice costs.** `/morph-init` Q12 now tells the owner how the two presets compare on cost in relative terms (All Sonnet is 1x, the Opus preset roughly 1.5x to 2x per feature, `xhigh` effort noticeably more than `high`), read from `harness/MODEL_PRICES.md` and worded as a rough comparison, not a quote. The hand-off says each feature will end with its measured cost, so the choice can be judged on the project's own numbers. No dollar figures are shown at install time.

- **Releases are named by semantic version.** From `v0.13.0` on, tags, GitHub releases and CHANGELOG headings (`## v0.13.0 (2026-10-21)`) use `0.MINOR.PATCH` while Morphness is pre-1.0; the dated releases keep their tags and the version map at the bottom of this file gives each one its version (`2026-10-12` is v0.1.0, `2026-10-20.5` is v0.12.0). Nothing changes in how installs update: `/morph-update` orders dated tags before versions and compares versions as numbers. `plugin.json` keeps a date-shaped plugin build number so Claude Code keeps offering plugin updates. `scripts/release-changelog.sh --suggest` proposes the next version; the 1.0 bar is in CONTRIBUTING.md § Releases.

- **Trials record a baseline; agents don't look up answers.** `harness/templates/trial.md` gains a Baseline section (the last window's rework rounds, QA fails and cost, plus one comparable earlier feature) and a baseline row in Results, and `harness/MORPHING.md` § Trials asks for it at the start so the keep or revert verdict is a before and after. The QA and Full-stack agent files gain one rule each: acceptance criteria and expected results come only from the plan in the repo, never from public repos, issue trackers or benchmark and grading data; an apparent answer key is reported, not used. Idea from Google Research's Harness² paper, whose agent fetched a public grading rubric unprompted.

- **Stability promise and 1.0 criteria.** `STABILITY.md` lists the public surface (config keys, `_harness/` record formats, update-note format, skill names, agent roles, script entry points), which releases get safety fixes (v0.13.0 and later, 60 days after 1.0) and what 1.0 requires; CONTRIBUTING § Releases groups the six criteria. The kit self-test also renders an install at v0.13.0, the oldest supported release, updates it to the current kit and checks the result (it skips until the v0.13.0 tag exists). Lessons: two added (fakes vs a real service, long steps in renders); the count is 114.

## 2026-10-20.5

- **Fewer permission prompts.** The guard now knows that `npx firebase-tools@<version>` starts `firebase` (also `netlify-cli`, `eas-cli`, `@angular/cli` and a few more), so a pinned run of a known dev tool no longer asks, while `npx firebase-tools deploy` is still judged as a deploy. A new `guard.pr_writes` switch (default `allow`) lets the GitHub connector's pull request tools open, update and comment in the project's own repository without a prompt; merge, auto-merge, file writes and other connector writes still ask. The template sets `permissions.defaultMode: acceptEdits` and allows the git, `gh pr` and log commands agents run all day, the log recipe no longer uses `rm -f`, `/morph-init` asks once (Q14) whether to auto-approve edits and the named check commands, and `/morph-doctor` reports an install still on plain prompts.

## 2026-10-20.4

- **`/morph-share` evidence names.** Step 7 of `/morph-share` now asks whether the evidence summary goes out under the project's name or anonymously before it creates any branch or file, and names the branch, file and pull request from that answer. An anonymous share gets a neutral random slug (`showcase/anon-4f2k`), never a descriptive alias, and the PR text must not say what the project is. It also stops if `scripts/evidence.sh` reports unreadable entries instead of forcing past it. The PR template has a line for evidence summaries (generated by, named or anonymous) and its checklist separates them from lessons.

## 2026-10-20.3

- **Evidence summary reads older records.** `scripts/evidence.sh` now reads the older one-line entry form, prune files named with a letter after the date, rule audit tables with an id column and archived action-item tables, and ignores `Escaped: none`. It prints a "Records read" line and stops with an error, instead of printing a summary that looks complete, when more than a fifth of the folded entries match no known form. Found when the first version printed 6 features for a project with 150.

## 2026-10-20.2

- **Evidence summary.** `scripts/evidence.sh` builds an anonymous summary of how the harness worked in a project (features finished, first-time QA pass rate, rework by prune window, escapes, estimated cost, retro items, rule audit results, trials, lessons adopted, and commit counts from the integration branch: fix-titled commits and reverts) from its own run records, with a "Read with care" list of what the figures can't show. It is read-only and sends nothing. `/morph-share` gains an optional step 7 that shows the summary and, only on the owner's yes, opens a pull request adding it under `showcase/`.

- **Prune interval range.** `loop.prune_every` is limited to 8 to 30 features. `scripts/prune-counter.sh` uses 8 or 30 for a value outside the range and says so, because a window under 8 features leaves most rules "too new to judge" and decides trials before their escapes show.

## 2026-10-20

- Agent files: the `description:` of every agent in `template/.claude/agents/` is now a quoted string. Unquoted, the `Default (effort high): use when…` text was invalid YAML for any strict reader (found by running the agnix linter on the kit). The self-test now fails an agent description with an unquoted colon. The `/morph-module` skill description no longer contains `<name>`, which claude.ai and the API reject on upload.

- Self-test: a fresh install may carry at most 35 KB of always-loaded rules (`CLAUDE.md`, the files it imports and the unscoped `.claude/rules/`), the text every session pays for. Today a fresh install is 33.6 to 34.3 KB. A change that pushes it over fails the kit self-test, so growth is a deliberate choice (trim the text, or raise `ALWAYS_LOADED_CEILING_KB` in `scripts/kit-selftest.sh` on purpose).

- Settings: the ten `Write(./**/.env…)` deny rules in `template/.claude/settings.json` are removed. Claude Code never consults a `Write(path)` rule (only `Edit(path)` and `Read(path)`), and the same `.env` paths already have `Edit(...)` and `Read(...)` deny rules, so nothing becomes unprotected. Found by the agnix linter.

- Skills: `/morph-update` names the GitHub hosts once and lists its read endpoints as paths, and records an already-present note as "a bookkeeping entry; no file changes" instead of "applied without asking". `/morph-doctor` points at `/morph-update` § 1 and § 2 without the words that read as a skill editing itself. The meaning and the read-only limits are unchanged; the SkillSpector static scan now scores all five skills 0/100.

## 2026-10-19.3

- Guard: more of the ways around it now ask or deny instead of running. `scripts/guard.sh` asks before a shell reads
  its commands from a pipe, a here-string or a here-document, a command name built at run time (`$cmd push`), an
  `alias`, `xargs` starting a shell, a Python, Node or Ruby one-liner that starts another process, and a file the same
  command wrote and then runs. It asks before code that `curl` or `wget` fetches and a shell runs (`curl … | sh`,
  `sh -c "$(curl …)"`, `source <(curl …)`), also from an allowed host; before a package runner downloads a package that
  is not installed (`npx`, `bunx`, `pnpm dlx`, `uvx`, and `skills add`); before a `make`, package or script file named for a
  deploy, release or publish; before `ssh`; before `git reset --hard` and `git clean -f`; and before the file tools write
  outside the project and `/tmp`, a CI definition (`.github/workflows`), `.git/hooks` or `.git/config`. It denies a
  secret file name stored in a variable (`f=.env; cat $f`), a recursive `grep -r` or `rg --hidden` over a folder that
  holds a secret file unless it excludes it, and an environment branch in capitals (`git push origin Main`); `timeout`,
  `nice -n`, `stdbuf` and `sudo -u` no longer hide the command behind them, and `bash -lc '…'` is read like `bash -c`. A new
  `guard.installs` switch turns the package-runner asks off. `AGENTS.md` § Permissions for this project lists what is still
  not seen (a script file written in an earlier call, `npm install` of a named package, interpreter code that decodes
  itself, `WebFetch`).

- Kit self-test checks § references and config keys. `scripts/kit-selftest.sh` now fails when a `file § Heading` reference in the template, skills or docs names a heading (or bold lead-in) that file doesn't have, when a doc or script names a config key (`loop.prune_every`, `config_get guard.deploys`) that `template/harness.config.yml` lacks, and when a key in that file is named nowhere in the kit. `/morph-update` now writes the `installed_from.updates.*` keys by their full path.

- Updating an older install: `/morph-update` now compares and merges against the template rendered for the project (module spans stripped, placeholders filled), so module-marked files no longer look edited or conflict. File merges run once per file in one pass, notes are ordered by release then id, and a note can declare a moved file (`moved:` in `updates/`, used for the Technical Lead rule) so the project's edits follow it to the new path. Files of a module the project doesn't have (such as the legal writer agent) are skipped, a CI workflow scaffold update is applied to the live `.github/workflows` file, config values the owner chose are kept, and a local clone offers released notes only, like the GitHub source. The kit self-test now installs the previous release into each sample project and brings it up to date, with and without local edits.

## 2026-10-19.2

- Docs: the guard hook has one description (`AGENTS.md` § Permissions for this project) listing what it
  denies, asks and does not see; `CLAUDE.md`, `RELEASE.md` and `SKILLS_AND_MCPS.md` link to it. The README
  "Safe by default" row and its requirements (bash, git, python3, awk, perl) say what the code does.

- The plan checklist has a group index with skip conditions, so a plan with no UI or no data reads fewer items.

- The prune report prints a `Loop:` line (escapes and rule tags added in the window), so a project can
  see whether the learning loop does anything.

- Guard: the CLI guard is inverted. `scripts/guard.sh` asks before any call to a known deploy, cloud or
  database CLI (wrangler, netlify, fly, railway, heroku, gcloud, aws, az, kubectl, helm, pulumi, terraform,
  firebase, stripe, psql, mysql, mongosh, redis-cli and more, also behind npx and pnpm exec) unless a read
  verb (`get`, `list`, `status`, `plan` ...) is the only action, a local database host is the target, or
  `--dry-run` / `--help` is given. It also asks before `gh pr merge`, `gh release`, `gh workflow run`,
  `gh repo delete`, `gh auth token`, any `gh api` write and a GraphQL mutation, and before `docker push`,
  `twine upload`, `gem push` and other publishes. `guard.deploys` and `guard.schema_pushes` turn the asks off.

- Trials wait for an escape window: a trial that has run its length is decided only after one prune
  window of features has finished past its last trial feature, and the decision reads the `Escaped`
  lines of bug-mode and fix-PR learnings files traced to its features.

- Guard: destructive local and persistence asks. `scripts/guard.sh` asks before a recursive `rm` outside the
  repo (or of the repo folder, its `.git` or a path built at run time; `/tmp` passes), before a write to
  `~/.bashrc`, `~/.profile`, `~/.zshrc` and other startup files or schedules, before `crontab` (except `-l`),
  and before any read or change of `~/.claude`.

- Guard: git bypass forms. `scripts/guard.sh` follows `git checkout`, `switch`, `symbolic-ref HEAD` and
  `remote.*.push` through a command, so `git checkout main && git push` is judged as a push to `main`;
  it denies `git push --prune` and `git branch -D` (also `-f`, `-m`) on an environment branch, reads
  `HEAD:refs/for/main` and `$(git branch --show-current)`, asks on a push target it cannot read and
  before any tag push (`guard.publishes: off` turns that ask off).

- Guard: environment branches are protected whether `environments:` is written as one-line maps or as
  a block list. `scripts/lib/config.sh` gains `config_env_branches`, and the self-test renders one
  sample project with a block list.

- Guard: it fails closed. Without `python3`, without `scripts/lib/config.sh`, with a project folder it
  cannot enter, on input that is not a JSON object and on a crash, `scripts/guard.sh` exits 2 with the
  reason instead of letting the call through; `guard: { fail_open: true }` accepts unchecked calls when
  `python3` is missing. `/morph-doctor` says so.

- The prune counter no longer fetches at every hand-off (`PRUNE_FETCH=1` opts in), counts only date-named
  proposal files, and exits 1 when a size budget is over and no proposal is open; the Technical Lead waits
  for a background agent's completion notification instead of polling it every 10 minutes.

- Session start: the toolchain and install commands are pinned per clone. A pulled change to either
  makes `scripts/session-start.sh` run nothing and show the old and new commands; the owner confirms
  in the session and `bash scripts/session-start.sh --accept` records and runs them (an `ask` rule
  covers that command). `/morph-doctor` reports a held change.

- Guard: the secret catalogue is real. Besides `.env*`, the guard denies `.envrc`, `*.pem`, `*.key`,
  `*.p12`, `id_rsa` and its kin, `.netrc`, `.pgpass`, `.git-credentials`, `credentials.json`,
  `secrets.yml` and similar, anything under `.aws`, `.ssh`, `.gnupg`, `.azure`, `.kube`,
  `.config/gcloud` and `.config/gh`, and env-file globs like `.en?`; `.npmrc` and `.pypirc` ask.
  `.claude/settings.json` gets matching `Read` and `Edit` deny rules.

- Guard: one-command exfiltration. The `.env` check sees through `@` and `<` (`curl -d @.env`), a bare
  `env` or `printenv` and `/proc/<pid>/environ` are denied, and a new `network` group in `guard:` asks
  before `curl` or `wget` send a body or a non-GET request to a host outside `localhost` and
  `guard.allow_hosts`, and before `scp`, `sftp`, `rsync` to another machine, `nc`, `socat`, `telnet`, `ftp`.

- Session start: `scripts/session-start.sh` prints the toolchain and install commands, runs them under
  a timeout (`MORPHNESS_START_TIMEOUT`, default 300 s), prints the command and the last lines of its
  output on failure, and adds `--ignore-scripts` to npm, pnpm, bun and yarn 1 installs. `scripts/install.sh`
  and `/morph-doctor` check `git`, `python3`, `awk` and `perl` and say what stops working without each.

- Guard: it protects its own files. An Edit, Write or Bash write to `scripts/guard.sh`,
  `scripts/session-start.sh`, `scripts/lib/`, `.claude/settings.json` or `harness.config.yml` asks the
  owner; `.claude/settings.local.json` is denied; a `ConfigChange` hook blocks a mid-session change to
  the local settings.

- Supply-chain pins: the catalog lists a pinned commit for every third-party skill and installs from it,
  `project/SKILLS_AND_MCPS.md` records the commit, `/morph-doctor` diffs installed skills against their
  source, the CI scaffolds pin `actions/checkout` to a commit, and the self-test checks that every action
  is pinned and that `ci.on_drafts` renders as a boolean.

- Agent context: subagents set `omitClaudeMd: true`, the Technical Lead rule moves to
  `harness/TECHNICAL_LEAD.md` (imported by `CLAUDE.md`, so only the main chat loads it), the researcher
  agents lose the shell, and a rule says to log long command output and print only the tail.

- Changelog fragments: PRs no longer edit `CHANGELOG.md`. A change to `template/` or `skills/` adds
  `changelog.d/<slug>.md` with its entry, `scripts/check-updates.sh --since` requires one, and
  `scripts/release-changelog.sh <release>` assembles the dated section at release time. Parallel PRs no
  longer conflict on the changelog.

## 2026-10-19

- Retro wording: the retro template has a Cause column and the `cause: environment` and "why not a
  script" prompts, SETUP says the owner writes any `settings.local.json` change, two redundant prune
  sentences are gone, counts from private data are out of the "learned:" notes, and the self-test's
  security-module text check is wider (`[Ss]ecurity[ -]module`, the config file and `.github` too).
- Guard: the deploy asks now cover `vercel env add|rm|update` (vercel asks for anything but a list of
  read-only subcommands), `wrangler secret put|delete|bulk` and `netlify env:set|unset|import`, and the
  publish ask covers `pnpm --filter x publish`, `npm --workspace x publish` and `changeset publish`.
  A command with `--dry-run` passes. `guard:` in `harness.config.yml` gets `deploys`, `publishes` and
  `schema_pushes` switches (ask or off) next to `mcp_writes`, so local `prisma db push` can run without
  a prompt. CLAUDE.md, AGENTS.md and the config comment point at `scripts/guard.sh` for the list.
- `prune-counter.sh` treats an `approved` prune proposal as open too (no repeated `Prune is DUE`), matches the
  status on a whole line, and skips `prunes/README.md`; § Prune says a declined proposal is still folded and reset.
- A check recorded "not run" is not a pass at the merge gate (it runs, or the owner accepts it in
  `plan.md` § Decisions); the refused-check rule is now in the QA and Full-stack agent bodies too.
- Three process rules: a retro item that adds a sentence says why a script or check can't do the job;
  a retro item tagged `cause: environment` goes to the owner, never a rule on the Technical Lead's own
  yes; a check the environment refused is recorded "not run", never an "equivalent".
- The guard hook now asks before deploys and publishes from well-known CLIs (vercel, wrangler, fly,
  firebase, netlify, `supabase functions deploy`, `prisma db push`, `drizzle-kit push`,
  `terraform apply`, `kubectl apply`, `helm upgrade`, `npm publish`, `cargo publish`) and before `gh api`
  writes to git refs and merges. AGENTS.md says plainly that the guard stops accidents, not intent.
- Agent wrappers always read the ownership and remote-environment sections; the last copies of the old small-mode test, entry format and guard message wording point at their single source; install notes for duplicate deny lines and a refused no-clobber copy.
- The guard hook checks the allowed Morphness `curl` read: only `-f -s -S -L` and URLs under the two
  Morphness prefixes pass silently; writing a file, another method, a body, headers, a config file or
  another URL asks first.
- `prune-counter.sh` prints only `Prune proposal waiting: <path>` while a prune proposal waits for the
  owner, no `Prune is DUE` line, so a Technical Lead following the hand-off bullet writes no second
  proposal. The prune template's **Status** can be `declined`.
- Security module wording in the Technical Lead rule, `SETUP.md` and `HANDOFFS.md` is marked, so a
  project without the module doesn't load it; the self-test fails when module text is left behind.
- Small, bug and security wording lined up across the rules, plans and agent bodies (small plan QA scope
  and limit, security review on bug plans, full-mode-only sections marked, lighter agent reads and QA
  layout pass); `prune-counter.sh` shows a waiting prune proposal.
- The advised Claude Projects settings follow the Sonnet default: coordinator, feature threads and
  one-shot threads on sonnet (medium, high, medium), with opus at high advised for a review, research
  or architecture thread. `/morph-init` still advises opus in all three with the Opus preset.
- The prune proposal no longer waits for the owner: when `scripts/prune-counter.sh` prints
  `Prune is DUE`, the Technical Lead writes `_harness/prunes/<date>.md` before the hand-off, which
  says `Prune is DUE: proposal written at <path>`. The owner only decides its rows; nothing is
  applied without that, and the next feature doesn't wait. The Claude Projects coordinator posts once
  per proposal, and `/morph-doctor` names the proposal waiting for a decision.
- Updates without a clone: `/morph-update`, `/morph-doctor`, the prune's upstream check and
  `UPDATE.md` read the newest release, its update notes, lessons and template text straight from
  github.com/antarsoft/morphness with read-only requests (nothing fetched is executed, no account
  needed), and fall back to a local clone when GitHub can't be reached. New config key
  `updates.source: github | local` (default `github`). Reads use `gh api --method GET` when `gh` is
  signed in and scoped `curl -fsSL` otherwise; `/morph-init` allows exactly those reads so they don't
  prompt, and the guard hook asks before any `gh api` write to a Morphness repository. Only released
  updates are offered.
- Trials as files: `_harness/trials/<trial-slug>.md` (template `harness/templates/trial.md`) holds the
  hypothesis, the change, its length in features, the metric and the pass and revert conditions. A
  feature that runs one names it on its learnings file's **Trial** line, the prune counter prints
  `Trial <slug>: N/<length> features` in every hand-off, and the prune decides keep or revert from
  the numbers. Replaces the table in `_harness/LEARNINGS.md` § Trials.
- Prune trend line: `bash scripts/prune-counter.sh --prune` prints one summary of the window (average
  rework rounds, QA fails, total cost) for the prune proposal, plus each trial's numbers.
- Rule provenance with a date: a rule a retro adds ends with `(from <feature>, <date>)`, and
  `prune-counter.sh --prune` lists each tag with the features finished since, for the rule audit.
- Small mode, between light and full and the default for a clear request: a fully specified change
  in a few named files that alters no access, money, stored data's shape or deletion, secrets,
  dependency or flow gets a short plan (`harness/templates/small-plan.md`) instead of `feature.md`,
  the full plan and the checklist run; Full-stack and QA still run, at `medium`, and the learnings
  file replaces `retro.md`. `risk_areas` now means "changing how this behaves needs full mode".
- Closing an access gap closes every read path too (exports, search, stats), and with the owner
  away the plan closes it rather than leaving the leak open (plan checklist item 29).
- QA's layout pass: on a UI change, every page at the narrowest supported width, signed in and out.
- Sonnet in every role by default; `/morph-init` offers Opus for planning and building as a preset.
- Retro rules come from misses only, and `scripts/prune-counter.sh` gauges the plan checklists
  against the new `loop.checklist_budget_kb`.
- A bug found after a pass always gets a retro item (the rule, check or test that would have caught
  it, or why none would), and its fix closes the same gap on sibling paths.
- `scripts/prune-counter.sh` gauges `project/*.md` against the new `loop.project_docs_budget_kb`, and
  the prune can condense those docs; `PROJECT.md` keeps architecture, not full route lists.
- `/morph-init` suggests risk areas as behaviours (access, money, deletion, migrations, secrets),
  not whole layers like API routes.
- QA's layout pass fails any overflow when the request is about layout or screen size.
- README: what Morphness adds is process (plan, QA record, audit trail, rules from misses), not a
  smarter model.
- Security module (optional): features that change who can sign in or read or change data, move
  money, handle secrets or delete people's data (never small-mode changes) fill a short threat model in `plan.md` § Security, each mitigation tied to a tested acceptance criterion, and get
  the security review before QA whatever their effort. Two named checks run on every feature:
  `secrets` (secret scanning, always redacted) and `audit` (the stack's dependency audit, judged only on
  packages the branch added or upgraded). `/morph-init` asks for it (Q11b) and `/morph-doctor` checks
  the tools, the commands and accepted advisories past their review date.
- `/morph-module add|remove <name>`: adds or removes a module on an installed project. It asks the
  module's install questions, puts its marked text back from the kit (or deletes it), runs On install
  or On remove, keeps the project's own files unless the owner says otherwise, updates `modules` and
  runs `/morph-doctor`. The kit self-test now checks every module can be added back (On install and
  On remove sections, and a unique anchor line for each marked span).
- Guard hook: `scripts/guard.sh` runs before Bash, file and MCP tool calls and reads commands the way
  the shell does. It blocks pushes to environment branches in every form (a bare `git push` on one,
  `HEAD`, `--all`, inside `bash -c` or `$(…)`), force-pushes, `.env` files other than the example,
  code-host secrets and well-known remote database writes, and asks before `gh api` writes to rulesets
  and protection and before any MCP tool that isn't a read (`guard.mcp_writes`). The settings deny
  rules stay as a second layer. `/morph-init` checks it and `/morph-doctor` reports a missing guard.
- Rule size gauge: the prune counter prints `Rules: X/36 KB always loaded` for the hand-off, and a
  prune is due when the always-loaded rules pass `loop.rule_budget_kb`.
- Kit self-test: `scripts/kit-selftest.sh` (and the `selftest` CI check) renders the template for four
  sample projects and runs the install self-checks, a link check, the scripts and the guard cases.
- Bug mode, next to full, light and research: for something that worked and is broken. A short bug
  plan (`harness/templates/bug-plan.md`) replaces `feature.md` and the full plan; QA writes the
  failing regression test and the Technical Lead commits it before any fix; Full-stack writes the
  root cause in `progress.md` before the smallest fix, and stops at the plan's fix limit; QA
  re-runs with the test unchanged. The learnings file, with its **Escaped** line, replaces
  `retro.md`. A hotfix is bug mode on the production branch.

## 2026-10-16

- Script fixes: `prune-counter.sh` and `feature-cost.sh` read `harness.config.yml` in block or
  one-line style through one shared reader (`scripts/lib/config.sh`); `feature-cost.sh --since`
  without a zone means UTC, as documented; the prune counter no longer counts files a prune already
  folded; `session-start.sh` skips the dependency install when the lockfiles haven't changed.
- A plan checklist group that doesn't fit the project (UI for a CLI tool, Data for a plan that stores
  nothing) is marked n/a in one Greps line. The release QA template and the PR template take their
  check rows from `checks` instead of listing the default checks.
- ci-cd module: an automatic deploy on push runs CI on that commit first and deploys only when it
  passes. The back-merge after a release is its own step in `harness/RELEASE.md`, with a box in the
  PR template.
- Code review before QA never gets skipped: when the built-in `code-review` or `security-review`
  skill is missing, the Technical Lead runs a read-only subagent with the same brief and
  `Plan/review.md` says so. `/morph-init` and `/morph-doctor` check that both skills are present.
- Light mode has a Full-stack brief in `harness/HANDOFFS.md`, and `harness/MODES.md` says what
  record a light-mode change leaves: no QA agent, the checks it touches run scoped, and the PR (or
  commit message) lists them with their exit codes under a **Light mode** line.
- Module-only text in the kit is marked (`<!-- module:<name> -->`), so removing a module is one
  command (`harness/README.md` § Modules). `/morph-update` copies a module's marked text when you
  add it later, and `/morph-doctor` reports markers left for a module that isn't on.
- One owner per rule: rules written out in several files now live in one owner file, with links
  elsewhere (`harness/README.md` § Rule owners). `harness/CONTROLS.md` holds the only list of
  documentation paths, and changes to `.claude/settings.json`, hooks and skill scripts no longer
  count as documentation, so they get every check. Plans keep their state on the **Status** line.
- Wider deny rules in `.claude/settings.json`: more `.env.*` names can't be read or edited,
  `cat`/`head`/`tail`/`less`/`more` of any `.env*` path is denied, and pushes to an environment
  branch are caught on any remote, with trailing flags and as a `+` force refspec. A bare
  `git push` asks first.
- The researcher and legal writer get real tool limits: the researcher can't create files (it edits
  only the research file it's given, between its two `---` lines), and the legal writer only reads
  and writes its legal copy, with no shell, web or MCP tools.
- `/morph-doctor` checks `session-start.sh` with `bash -n` instead of running it.
- A check the project doesn't have (no lint yet, no browser tests) is left out of
  `project/CONTROLS.md`, `project/STACK.md` and `checks`, instead of marked "none".
- The ci-cd module asks before `gh api` calls on rulesets and branch protection instead of denying
  them, so `/morph-init` and `/morph-doctor` can apply protection once you allow the prompt.
- The Technical Lead rule is about 40% shorter (19 KB to 11 KB): every hard rule stays as one line,
  with the detail moved to the file that owns it (`harness/RELEASE.md` § Feature PRs,
  `harness/HANDOFFS.md` § Threads and § Background agents, `harness/SETUP.md`). The process is
  unchanged.

## 2026-10-15.2

- Retro action items have a soft limit: `loop.retro_max_items` is the usual number, not a cap. A
  retro has only the items its findings call for (none is normal) and may go over when each extra
  item answers a different finding, with a line saying why. Every item gets a **Why raised** column
  (the finding it answers and its evidence), and the prune uses it to check whether the problem came
  back after the item landed.
- Setup work through connectors: before handing you a console chore (create a hosting project, set a
  variable, add a domain or DNS record), the Technical Lead checks whether a connected official MCP,
  connector or plugin can do it, and if so offers to, running each action only after you approve it
  in chat. Nothing a connector writes runs automatically, and remote database changes, secret values,
  billing and people's access never go through an agent. What stays yours says why (no official MCP,
  one exists but isn't connected, or it has no tool for this). A new Service tools table records each
  service's official MCP, checked by the researcher; `/morph-init` suggests only official connectors
  and fills the table, and `/morph-doctor` keeps it current.
- Every feature now records an estimated dollar cost: `scripts/feature-cost.sh` reads Claude Code's
  own session transcripts and prices every API call at public API prices (table in
  `harness/MODEL_PRICES.md`, editable for your own rates), split by the Technical Lead and each
  subagent. The `Cost ≈ $…` line goes in the retro's run table, the learnings file and the end of
  every hand-off, light-mode tasks and research files included; the prune shows each feature's cost
  and the window's average next to the previous one. Useful on a Pro or Max plan too, as an estimate.
  `/morph-doctor` checks the script and that the price table covers your agents' models.
- Research files get a short look-back instead of a retro: when the Technical Lead records the
  decision it adds three lines (did its check confirm the findings, were the scope and researcher
  effort right, did the answer get used). The prune reads them and suggests tweaks, such as a
  default researcher effort for a kind of question. Research still never counts toward the prune.

## 2026-10-15

- Research mode: when you want an answer rather than a change (how something works, why a bug
  happens, which library fits), the Technical Lead writes the question in `_harness/research/`, a
  new read-only **researcher** subagent answers it with cited sources, and the Technical Lead checks
  it and records the decision. The researcher can also run before a plan for a wide search. Two
  variants: `researcher` (sonnet, medium) and `researcher-high` (opus, high). `/morph-init` offers it
  with the other agents.
- Projects that aren't online yet: `/morph-init` starts the git repository and the first commit when
  the folder has none, and creates the GitHub repository on the owner's yes (with plain website
  steps when it can't). Until a remote exists, agents use the local branches and merge on the
  owner's computer, and `/morph-doctor` offers to finish the code host setup once the project is
  online.
- `/morph-init` speaks plainly to owners who aren't developers: each technical term gets a few words
  of explanation the first time it comes up, and the code host and CI question is split into two
  questions in everyday words. It also warns early that GitHub's free plan can't protect branches on
  private repositories.
- When the branch protection can't be applied for the owner, they now get numbered steps for the
  GitHub website and for a terminal (including going into the project folder, or cloning it first)
  with the real names filled in, from the new `harness/RELEASE.md` § Applying it yourself.

## 2026-10-14.2

- `/morph-init` and `/morph-doctor` can apply the branch-protection ruleset with `gh api` on the
  owner's yes (and read it back), falling back to the file, import steps and command for the owner.
  New `branch_protection.delete_merged_branches` (on by default with protection) turns on automatic
  deletion of a PR's branch after it merges; `/morph-doctor` checks both.

## 2026-10-14

- `release_tags: per-package` for monorepos whose packages have their own versions (Changesets, Nx
  release, release-please): features add the tool's change files, releases are named by date, and
  the tool writes the `<package>@x.y.z` tags. `/morph-init` suggests it when it finds such a tool.
- Monorepos can list their apps in `harness.config.yml` → `apps` (folder, stack, browser spec
  folder, and how each app deploys to each environment). Plans name the apps they touch, targeted
  browser specs follow them, and the ci-cd deploy workflow gets a job per app. `/morph-init` asks when
  it finds more than one app; with `apps: []` nothing changes.
- Full-stack can narrow its pre-QA checks to what the branch changed: a docs-only diff skips them,
  and each check can run its tool's affected mode (`pnpm --filter '...[origin/dev]'`,
  `vitest --changed`, `jest --changedSince`) or only when listed paths change
  (`project/CONTROLS.md` § Check scope). Cross-cutting paths and dependency changes still run
  everything, and QA's sign-off run and CI always run the full commands. `/morph-init` suggests
  the scopes from the stack.
- The prune counter is now a script: `scripts/prune-counter.sh` prints the `Prune counter: N/<prune_every>`
  line (and `Prune is DUE`) that ends every feature hand-off, counting the integration branch's
  learnings files too. With the `claude-projects` module the thread's closing reply carries it and the
  coordinator posts once in the project chat when a prune is due. `/morph-doctor` uses the script.
- The code host's default branch is now a choice: `branches.default` in `harness.config.yml`,
  recommended to be the integration branch when it is separate (so new PRs, dependency bots and
  clones land there, and issues close when a feature merges), or production for a public library.
  `/morph-init` asks, `harness/RELEASE.md` § Default branch lists the trade-offs, and `/morph-doctor`
  checks the host matches.
- Who merges PRs is now a setting: `merge_by_agent` (`never` by default, or `integration` to let the
  Technical Lead merge ready feature PRs into the integration branch once the merge gate holds).
  The rule spells out what counts as the human asking, production merges stay the human's, and
  `.claude/settings.json` prompts on every merge command. `/morph-init` asks; `/morph-doctor` checks.

## 2026-10-13.2

- Releases can now go out more than once a day: a later one adds its number to the date
  (`2026-10-14.2`), and the plugin version becomes `YYYYMMDD.N.0` so Claude Code sees every release as
  newer. `/morph-update` orders release tags by date, then number. Rules: CONTRIBUTING.md § Releases.
- The PR template says what to fill when a draft opens and what waits for ready, and gains a
  **Merge after** line, a **Release notes** section and a **Hotfix** section. The ci-cd tag workflow
  publishes only the Release notes section instead of the whole PR body. On GitLab, `/morph-init`
  writes the template as the default merge request template.
- Feature PRs now open as a draft at the feature branch's first push and are marked ready once QA
  passes (back to draft if QA fails later); release and hotfix PRs do the same. With the
  `ci-cd` module, CI skips drafts unless `ci_cd.on_drafts` is `true`, runs when a PR is marked
  ready, and runs in a merge queue. `/morph-init` asks about CI on drafts; `/morph-doctor` checks it.
- Shared environments are now a list in `harness.config.yml` (`environments`), defaulting to two:
  `dev` on the integration branch and `production` on the production branch. `/morph-init` asks
  whether you want more (a `staging` or `uat` in between, on the integration branch or its own
  branch with promotion PRs) or fewer (production only, or none). Release QA runs on the
  environment just before production, the ci-cd deploy and migrations workflows offer exactly the
  listed environments, and `/morph-doctor` reports what is out of step after you change the list.
- Branch protection on the host: `branch_protection` in `harness.config.yml` (on by default) and a
  GitHub ruleset to import that makes every environment branch PR-only, with no force-push or
  deletion. `/morph-init` asks for it and the number of approvals; `/morph-doctor` checks it.
- Release tags are now optional (`release_tags` in `harness.config.yml`, default on), and the
  `ci-cd` module can add a tag workflow that tags each merge to the production branch from the PR
  title (`Release vX.Y.Z`, `Hotfix vX.Y.Z`) and creates its release, so nobody pushes tags by hand.
  `/morph-init` asks about both.

## 2026-10-13

- Plugin icon for the Claude plugin directory listing.
- `/morph-init` no longer downloads the Morphness source itself: it uses its own plugin folder or a
  clone the user names. `/morph-share` asks for the showcase handle instead of reading it with `gh`.
- New `/morph-update` skill, and [UPDATE.md](UPDATE.md) for agents without the plugin. It lists the
  kit updates and community lessons added upstream since a copy last synced, explains why each fits,
  and applies only what the owner accepts, merging with local edits instead of overwriting them.
  Declined updates are never offered again; deferred ones come back next time.
- Kit changes now ship with an update note in `updates/`, checked by `scripts/check-updates.sh`.
- Every prune checks upstream read-only and lists pending updates in the proposal (`SETUP.md` § Prune,
  `templates/prune.md` § 3c). `harness.config.yml` → `installed_from` gains `release` and `updates`.
- `/morph-doctor` now only counts pending upstream items and points to `/morph-update`.
- `/morph-update` works from a Morphness clone the user or their agent makes (UPDATE.md step 2) and
  never downloads the source itself, like `/morph-init`.
- New optional `ci-cd` module. `/morph-init` can now set up pipelines (CI that runs the named checks
  on pull requests, an owner-run deploy workflow, and the migrations workflow the data-access module
  refers to), each one offered separately and written only when you say yes. Agents write pipeline
  files but never run deploys or migrations. `/morph-doctor` reports CI that has drifted from
  `project/CONTROLS.md`.

## 2026-10-12

First public release.

- Kit: Technical Lead, Full-stack, QA and legal-writer roles; plan checklist; retro and prune loop;
  modules for Claude Projects, data access, browser e2e, legal wording and roadmap.
- Skills: `/morph-init` (new and existing repos, including migrating an earlier harness),
  `/morph-doctor`, `/morph-share` (now offers a showcase listing as its own PR).
- Catalog: 112 lessons from Twinpage (68 practice, 24 stack, 20 service); profile
  `web-saas-nextjs-supabase`.
- Repo: README, contributing guide, code of conduct, security policy and issue templates.

## Version map for the dated releases

The first releases were named by date. Their tags, GitHub releases and headings above keep those names;
this table says which version each one is. Everything below 1.0 is pre-1.0 (CONTRIBUTING.md § Releases).

| Release | Version | What it was |
|---|---|---|
| 2026-10-12 | v0.1.0 | First public release |
| 2026-10-13 | v0.2.0 | Upstream updates, `/morph-update` |
| 2026-10-13.2 | v0.3.0 | Environments, branch protection, draft PRs, PR template, release tags |
| 2026-10-14 | v0.4.0 | `merge_by_agent`, default branch, prune counter, apps |
| 2026-10-14.2 | v0.4.1 | Apply branch protection, delete merged branches |
| 2026-10-15 | v0.5.0 | Plain-language setup, research mode |
| 2026-10-15.2 | v0.6.0 | Feature cost, connector actions, retro soft limit |
| 2026-10-16 | v0.7.0 | Structure-review fixes |
| 2026-10-19 | v0.8.0 | Post-merge review fixes, guard, trials |
| 2026-10-19.2 | v0.9.0 | Hostile-audit fixes |
| 2026-10-19.3 | v0.9.1 | Guard batch 2, self-test, older-install update fixes |
| 2026-10-20 | v0.9.2 | Agent YAML fix, always-loaded size ceiling |
| 2026-10-20.2 | v0.10.0 | Evidence summary |
| 2026-10-20.3 | v0.10.1 | Evidence reads older records |
| 2026-10-20.4 | v0.11.0 | `/morph-share` named or anonymous |
| 2026-10-20.5 | v0.12.0 | Fewer permission prompts, `guard.pr_writes` |
