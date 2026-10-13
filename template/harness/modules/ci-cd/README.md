# Module: ci-cd (pipelines for checks, deploys and migrations)

Optional. Enable it in `harness.config.yml` → `modules` when the project wants the harness to set up and look after its pipelines. Without it, the harness still reads a pipeline the project already has (`ci_gate`, `project/CONTROLS.md` § CI, `project/RELEASE.md`); it just doesn't write or check one.

The module covers three pipelines. `/morph-init` offers each one on its own and writes only the ones the owner accepts. Which ones exist is recorded in `harness.config.yml` → `ci_cd`.

| Pipeline | What it does | Who starts it | Scaffold (GitHub Actions) |
|----------|--------------|---------------|---------------------------|
| **CI** | Runs the `before_qa` named checks on every pull request into the integration or production branch | Every PR, automatically | [github/ci.yml](./github/ci.yml) |
| **Deploy** | Deploys a branch to an environment, for hosts that don't deploy on push themselves | The owner (manual run), or a push to the integration branch for staging | [github/deploy.yml](./github/deploy.yml) |
| **Migrations** | Applies database migrations to a shared environment, the workflow the `data-access` module and `project/RELEASE.md` refer to | The owner (manual run) only | [github/migrations.yml](./github/migrations.yml) |

On GitLab, morph-init writes the same jobs into `.gitlab-ci.yml`: CI as a merge-request pipeline, deploy and migrations as `when: manual` jobs on protected environments. Other hosts: describe the pipelines in `project/CONTROLS.md` § CI and `project/RELEASE.md`, and keep the rules below.

## Rules

- **Agents write pipelines; they never run deploys or migrations.** A pipeline file is code: Full-stack changes it in a planned feature, and QA reviews it like any other diff. No agent starts, re-runs or approves a deploy or migrations run, or edits environments, secrets, variables or branch rules (`AGENTS.md` § Shared remote environments). CI runs on its own.
- **The real guard is the host, not the deny list.** Deploy and migration credentials live only as **environment secrets** on environments that require the owner's approval (GitHub: Settings → Environments → Required reviewers). They are never repository secrets, so a pull-request job can't read them, and a run that reaches the environment waits for the owner. The `.claude/settings.json` denies only catch mistakes; a deny rule matches command text, not intent.
- **CI uses the commands in `project/CONTROLS.md`, word for word.** One step per `before_qa` check, in the same order. When a command changes there, the same PR changes CI (plan checklist item 6, every affected file). `/morph-doctor` reports CI that has drifted.
- **CI runs on `pull_request`, never `pull_request_target`,** with `permissions: contents: read`. A PR from a fork then runs with no secrets and a read-only token.
- **A docs-only PR still gets a green check.** The CI job works out from the changed files whether only documentation changed (`project/CONTROLS.md` § Documentation paths) and then skips its steps and succeeds. Don't use workflow-level `paths-ignore`: a required check that never starts blocks the merge.
- **Pin the runner image** (for example `ubuntu-24.04`, not `ubuntu-latest`) and each action to a major version. Bump either in its own PR.
- **Cost before adding a step.** A plan that adds a CI job or a long step times it locally and states the billed minutes (plan checklist item 37). Public repositories on GitHub run Actions for free; private ones use the account's minutes, and when those run out jobs don't start. With `ci_gate: false`, QA's local record stays the gate, so a stalled CI doesn't block work.
- **`ci_gate: true` only once CI is a real gate:** CI runs every `before_qa` check, has passed on the integration branch at least once, and the owner has made it a required status check (GitHub: a ruleset or branch protection on the integration and production branches). Until then keep `ci_gate: false`.
- **Deploys keep the release order.** Production deploys only from the production branch, after the owner's production steps (`harness/RELEASE.md` step 4). Migrations are additive and are applied before the code that needs them is merged.

## Owner steps

Agents can't do these; they go in `project/RELEASE.md` § Manual steps, and morph-init lists them in its hand-off:

- [ ] Create the environments (for example `staging`, `production`) and set yourself as a required reviewer on `production` (and on `staging` when it holds real data).
- [ ] Add the deploy and migration secrets as environment secrets, never repository secrets.
- [ ] After CI has passed once on the integration branch, require its `checks` job before merging into the integration and production branches, then set `ci_gate: true`.
- [ ] When the deploy workflow replaces the host's own deploy on push, turn the host's automatic deploys off (or the two will race).

## Technical Lead

- A plan that changes a pipeline file names it in the plan and puts the pipeline in **Cross-cutting paths**. A change to the deploy or migrations workflow is a `risk_areas` entry (`CI/CD`), so it never runs at `medium` effort.
- When a feature adds or renames a named check, the plan's steps include the CI step.
- In the steps file, list any secret, environment or required check the feature needs from the owner.

## On install

- Copy the accepted scaffolds to `.github/workflows/` without overwriting (a project's existing workflow is kept and described instead), fill their `{{…}}` keys and `# morph-init: fill` lines, and record the paths in `harness.config.yml` → `ci_cd`. A pipeline the owner declined is `none` there and has no file.
- Fill [project/CONTROLS.md](../../../project/CONTROLS.md) § CI (each workflow, its trigger, its jobs, and whether it is a required gate) and [project/RELEASE.md](../../../project/RELEASE.md) § Where things deploy, § Manual steps (the owner steps above), § Production migrations and § Rollback from the chosen pipelines.
- Add `.github/workflows/` (or `.gitlab-ci.yml`) to [project/CONTROLS.md](../../../project/CONTROLS.md) § Cross-cutting paths, and `CI/CD` to `harness.config.yml` → `risk_areas` when a deploy or migrations workflow was added.
- Add to `.claude/settings.json` → `deny`: `Bash(gh workflow run*)`, `Bash(gh run rerun*)`, `Bash(gh secret*)`, `Bash(gh variable*)`, `Bash(gh api*environments*)`, `Bash(gh api*rulesets*)`, `Bash(gh api*protection*)` (GitLab: `Bash(glab ci run*)`, `Bash(glab variable*)`), plus the write tools of any hosting connector that deploys. List them in `project/SKILLS_AND_MCPS.md` § Permission rules added for this project.

## On remove

When the project doesn't choose this module, morph-init deletes this folder and the items below. `ci_gate`, `project/CONTROLS.md` § CI and the release rules are core and stay: they describe a pipeline the project already has, or say there is none.

**Delete these files:** none outside this folder.

**Delete or reword these lines:**

- `harness.config.yml`: the `ci_cd` block and its comment.
- `harness/README.md` § Modules: the `ci-cd` row.

**Unlink:** every Markdown link left pointing into `harness/modules/ci-cd/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/ci-cd' --include='*.md' . | grep -v '^./harness/modules/'`.
