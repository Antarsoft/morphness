# Controls: checks before handover

This is the only file that says which checks run at each handover and which are required; other docs link here. The checks are **named** (`checks` in `harness.config.yml`); the command for each name lives in `project/CONTROLS.md`, the only place commands are spelled out.

## Named checks

| Name | What it proves |
|------|----------------|
| `install` | Dependencies install from the lockfile |
| `typecheck` | Static types (or the language's equivalent compile check) pass |
| `lint` | Linters and formatters pass |
| `unit` | Unit tests pass (and integration tests, unless the project names a separate `integration` check) |
| `build` | A production build succeeds |
| `e2e-targeted` | The end-to-end tests that cover what the plan changed (browser-e2e module) |
| `e2e-full` | The whole end-to-end suite (browser-e2e module) |
| `e2e-repeat` | A new or changed timing-sensitive end-to-end test passes five runs in a row (browser-e2e module) |
| `secrets` | No secret is in the branch's commits or working tree (security module) | <!-- module:security -->
| `audit` | No dependency with a known high or critical advisory is added or upgraded (security module) | <!-- module:security -->

A project may add its own names (for example a schema-drift check or an integration suite) in `harness.config.yml` → `checks` and give each a command in `project/CONTROLS.md`. A named check with no command in this project is recorded as **not run**, never as passed.

## Merge gate

`ci_gate` in `harness.config.yml` decides what gates a merge:

- **`ci_gate: false`** (QA is the gate): QA's local run is the only gate before a merge, so `qa-result.md` must record the exit code of every `before_signoff` check, including, with the `browser-e2e` module, the full end-to-end run on the final commit (or its reuse under § After merging the integration branch). The Technical Lead does not recommend a merge, mark a PR ready, or sign off without that record, checked against `git rev-parse HEAD`. A stale or missing record goes back to QA.
- **`ci_gate: true`** (CI is also a gate): the same `qa-result.md` record is still required, and the PR's CI checks must be green on the final commit before the TL recommends a merge. CI does not replace QA's acceptance testing. Where the pipeline lives and what it runs: `project/CONTROLS.md` § CI.

After merging the integration branch into a feature branch, the TL hands to QA with § After merging the integration branch named: when only documentation was combined, QA re-runs the fast checks and keeps its browser-suite result.

## Before Full-stack → QA handoff

The Full-stack engineer **must** run every check in `checks.before_qa` from the repo root, confirm **exit 0**, and record results in `Development/progress.md` § **Validation (required before handoff)** before marking ready for QA.

| Check | Required |
|-------|----------|
| `install` | yes, when dependencies changed |
| `typecheck` | yes |
| `unit` | yes |
| `build` | yes |
| `lint` | yes |
| `e2e-targeted` (browser-e2e module) | yes, for features touching screens, auth or a public API: the specs in `plan.md` § QA scope → **Targeted e2e specs**, the project's always-run specs, and every spec the diff adds or edits. When the plan says `full`, or the diff touches a path in § Cross-cutting paths, run `e2e-full` instead. Record the specs run with the exit code. Details: [modules/browser-e2e/](./modules/browser-e2e/README.md) |
| `e2e-repeat` (browser-e2e module) | yes, when a new or changed end-to-end test uses a fake clock, hover or focus timing: run it five times and record the pass count (learned: a timing test passed once at handoff and failed most repeats later) |

Any check the project marks as by hand only (for example a performance audit) is not a handoff check; run it only when a plan asks.

### Scoping by what changed

Full-stack's `before_qa` run may be narrowed to what the branch changed, so a small change doesn't pay for the whole repo on every handoff. QA's `before_signoff` run is never narrowed (§ Before QA pass → human handoff): it runs each check's full command on the final commit, so scoping speeds up the build loop without weakening the merge gate.

1. **The diff:** `git diff --name-only $(git merge-base origin/<integration> HEAD)` (it includes uncommitted changes) plus untracked files from `git status --porcelain`. Paste the command into `progress.md`.
2. **Full when in doubt.** Run every `before_qa` check with its full command when the diff touches a path in § Cross-cutting paths or a dependency manifest or lockfile, when the plan says **Checks: full**, when the merge base can't be found, or when a scoped command fails before any test runs (it can't work out what is affected).
3. **Documentation only:** when every path in the diff is documentation (§ Documentation paths), record each `before_qa` check as `skipped: docs only` and stop<!-- module:security --> (except `secrets`, which still runs: a key pasted into a document is a leak)<!-- /module:security -->. CI and QA treat the same diff the same way.
4. **Otherwise, per check,** follow its row in `project/CONTROLS.md` § Check scope:
   - `full` (or no row): the full command.
   - `affected`: the scoped command there (the tool's own affected or related-tests mode, for example a monorepo filter on the merge base or a test runner's changed-files option).
   - `paths`: the full command when the diff touches one of the listed paths; otherwise record `skipped: no listed path changed`.
5. **Record the scope** of each check in `progress.md` § Validation: `full`, `affected` or `skipped: <reason>`. A skipped check is never written as passed.

`install` keeps its own rule (when dependencies changed), and `e2e-targeted` / `e2e-full` keep the browser rule in the table above; § Check scope doesn't list them.

### Command output

Every check writes its full output to a log file and prints only the exit code and the end of the log. Everything a command prints stays in the agent's context and is re-read on every later turn, so one full test or build log costs far more than the run itself.

```bash
LOGS="<scratchpad>/logs"; mkdir -p "$LOGS"
rm -f "$LOGS/unit.exit"
<unit command from project/CONTROLS.md> > "$LOGS/unit.log" 2>&1; echo "exit $?" | tee "$LOGS/unit.exit"
tail -n 30 "$LOGS/unit.log"
```

- Take the exit code from the command itself (`$?` right after it), never from a pipe (`<cmd> | tail` reports `tail`'s exit code) and never from the log's last line.
- Remove the check's old `.exit` file before the run (the logs folder may be shared with earlier runs in the same container), and report a run only once its new `.exit` file exists; a run still going in the background has no result yet (learned: QA once reported an earlier targeted exit file and a partial log as its full run).
- On a failure, read only the failing parts: `grep -nE 'Error|FAIL|failed' "$LOGS/<check>.log" | head -n 40`, then `sed -n` around those lines. Don't `cat` the whole log.
- One log per check.

### Cross-cutting paths

Some paths can break pages or features they don't name: shared packages, the database schema and migrations, auth and session code, request middleware, the root layout or app shell, server-side API routes, build and test configuration, the test fixtures and support files, and the dependency manifests and lockfile. A change to any of them gets `e2e-full` from Full-stack and a full QA round 2. This project's list is in `project/CONTROLS.md` § Cross-cutting paths.

### Documentation paths

Several rules below treat a documentation-only change differently, and CI skips its checks on one. This is the only list; `project/CONTROLS.md` § Documentation paths holds only this project's additions and removals. Documentation means `_harness/`, `docs/`, `harness/`, `project/`, `.claude/agents/`, `.claude/rules/`, the root `README` and `LICENSE`, and any `*.md` outside CI configuration. Files that run or set permissions are never documentation, even under those folders: `.claude/settings.json`, hook scripts, and skill scripts under `.claude/skills/` or `.agents/` (a change there gets every check). A path with a `..` segment never counts.

<!-- module:data-access -->
### Data-access features (`plan.md` → **Data-access feature: yes**)

With the `data-access` module, QA **must** run [modules/data-access/](./modules/data-access/README.md):

- **Stage A** on the local stack, as part of the QA pass.
- **Stage B**, a read-only check of the integration environment, after the migrations reach it (after the feature PR merges).

Record results in `qa-result.md`. Agents never change a shared remote environment.
<!-- /module:data-access -->

<!-- module:security -->
### Security checks and features

With the `security` module, `secrets` and `audit` run like any named check, and [modules/security/](./modules/security/README.md) § Named checks says how their results are judged: a secret is never printed, and an `audit` advisory on a dependency the branch didn't add or upgrade is recorded as **pre-existing**, not a fail. A plan with **Security feature: yes** also gets the security review before QA ([SETUP.md](./SETUP.md) § Code review before QA), whatever its effort.
<!-- /module:security -->

### Grep as evidence

A `git grep` quoted as acceptance-criterion evidence must run with `--untracked` (or after the WIP commit); plain `git grep` ignores untracked files, so before a commit it checks nothing.

## Before QA pass → human handoff

QA runs every check in `checks.before_signoff` on the final commit, each with its full command: § Scoping by what changed never applies here.

| Check | Required |
|-------|----------|
| Every `before_qa` check | yes |
| `e2e-full` (browser-e2e module) | yes, for features touching screens, auth or a public API: the whole suite, once on the final commit (Full-stack ran only targeted specs, so this is the suite's only full run). On a failure re-run once to tell a flaky test from a real failure (a second failure is real). QA may reuse its own earlier full-suite exit code instead of repeating the run when `git diff --name-only <the commit that run used>..HEAD` lists only documentation paths; `qa-result.md` then names that commit and the diff check. After merging the integration branch in, reuse follows § After merging the integration branch |
| Manual smoke | if UI changed: the project's smoke steps that apply (`project/CONTROLS.md` § Manual smoke) |

### After merging the integration branch

When another PR lands on the integration branch first, the feature branch merges it in, and the plain documentation-only diff check above always fails because it also sees the other PR's code. That code already passed its own QA, so judge the merge by what it **combined**, not by the whole diff. QA keeps its earlier full-suite exit code when all of these hold:

1. `git log --first-parent --format='%h %s' <commit the full run used>..HEAD` lists only merges of the integration branch and commits that change documentation paths only (`git show --name-only` for each).
2. For each of those merges, `git diff-tree --cc --name-only <merge commit>` (the files both sides changed, including every conflict the merge resolved) lists nothing or only documentation paths.
3. Every PR that reached the integration branch since that run passed QA with a full suite on its final commit (or this rule), or changed documentation paths only.

QA still runs `typecheck`, `lint`, `unit` and `build` on the merged head, and `qa-result.md` records the reused run's commit, each merge commit and its `diff-tree` output, and the PRs checked for condition 3. If any condition fails, run the full suite as usual.

This leaves the same gap a conflict-free PR has (the host merges it without testing the two features together), so release QA's full run on the integration branch stays the check for features that break each other ([RELEASE.md](./RELEASE.md) step 3).

**Merge order:** when a PR is ready for the human and another open PR into the integration branch (a draft included) shares a non-documentation file with it (`git diff --name-only origin/<integration>...<branch>` for each), the hand-off says which to merge first: the one whose re-test would cost more (code in § Cross-cutting paths, the larger end-to-end scope) goes first, so the re-test after the merge falls on the smaller PR. Overlap in documentation only needs no order.

## Before the feature PR (Technical Lead)

| Check | What | Required |
|-------|------|----------|
| Steps file | `plan.md` **Steps file** names the steps file and that file has this feature's block, or says `none` | yes |
| One next version (roadmap module) | The roadmap marks exactly one next version and its checklist exists ([modules/roadmap/](./modules/roadmap/README.md)) | yes, with the roadmap module |
| PR description | Filled from the feature folder (`plan.md`, `qa-result.md`, the steps file) using the PR template, when `pr_host` is not `none`: Summary, Harness and Changes at draft, the rest at ready, as its comments say. **Merge after** names the PR to merge first, or `none` | yes |

## Notes

- QA records the checks run, with commands and exit codes, in `qa-result.md`.
- If a check has no command or a script is missing, mark it **not run**; do not claim coverage. A check the environment refused to run (a denied command, no permission) is **not run** too, with the refusal recorded; never swap in a different command and count it as a pass (learned: two agents counted an "equivalent" for a refused lint command).
