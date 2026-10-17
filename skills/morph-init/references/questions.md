# morph-init questions

Ask in this order, one at a time. Each entry: the question, when to skip it, what to suggest, and what
the answer unlocks. Keys in `backticks` are where the answer is stored in `morph-answers.yml`.

## Repo scan (ongoing projects, before Q1)

Read, without running project code:

- `README*`, `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `Gemfile` / `pom.xml` /
  `build.gradle*` / `composer.json` / `*.csproj`, lockfiles, workspace files.
- Scripts or tasks (`package.json` scripts, `Makefile`, `justfile`, `Taskfile.yml`, `tox.ini`, `noxfile.py`).
- CI files (`.github/workflows/*`, `.gitlab-ci.yml`), test folders, e2e configs, migration folders,
  `.mcp.json`, existing `CLAUDE.md` / `AGENTS.md` / `.claude/`.
- `git branch -r` and the default branch; recent `git log --oneline -20`; contributors.
- An earlier harness, if any: `.claude/agents/*.md` (model and effort per agent, extra variants),
  `.claude/rules/*.md`, `project/*.md`, the agent table and trials in its agents doc, and its
  checklists. Its values are the suggestions for Q5, Q6, Q6b, Q9 to Q13, including defaults that differ
  from the advised ones (for example QA at `medium` by default).

Look for manifests in workspace packages too (`apps/*/`, `packages/*/`, or the globs in
`pnpm-workspace.yaml`, the `workspaces` field, `go.work` and similar): in a monorepo the framework is
often a dependency of an app, not of the root.

Turn what you find into suggestions: stack summary, package manager, a command per named check,
branches, modules (migrations folder → data-access; e2e config → browser-e2e; legal pages → legal),
risk areas (auth, payments, migrations, public API, webhooks). Never ask for something the scan
settled; say "I found X, keeping it" and move on. An existing `CLAUDE.md` or `AGENTS.md` is kept:
render.md merges the harness lines into it.

## Q1. Project

"What's the project called, and what does it do in one line?" Suggest the README's title (else the repo
folder name) and its first sentence. → `project.name`, `project.description`

## Q2. Owner

"Who approves plans and merges? Name and GitHub login." Suggest `git config user.name` and the remote's
owner. Follow-up: "Anyone else who can approve?" (default no). → `humans`

## Q3. Where you'll run it

"Where will you work with the agents?"
- Claude Code CLI or desktop (default)
- Claude Code on the web
- Claude Projects with a coordinator and threads (also uses Claude Code in each thread)

Multiple allowed. Claude Projects unlocks Q12b and the claude-projects module. → `environment`

## Q4. Stack

"What's the stack?" Suggest from the scan or a matching profile; for a new project, ask for the
language/framework, the database (or none), hosting, and package manager, one line each. Offer a
profile when one matches. → `stack.summary`, `stack.package_manager`, `stack.toolchain_setup`
(e.g. a version manager line), `stack.install_cmd`

Follow-up only when the scan found more than one app (several workspace packages with their own
start, build or deploy config, such as `apps/web` and `apps/api`): "This looks like a monorepo with
these apps: <name, folder, stack, one line each>. Track them as separate apps, so plans name the apps
they touch and each app can deploy its own way?" Default yes. Shared libraries (`packages/*` that
nothing deploys) are not apps; they stay cross-cutting paths. A single app, or no: `apps: []` and
nothing else changes. → `apps` (name, path, stack; `e2e` from the browser-e2e scan; `deploy` from Q6b)

## Q5. Checks

"These are the checks agents run before QA and before sign-off. I've filled the commands I could find:"
then a table of named checks (`install`, `typecheck`, `lint`, `unit`, `build`, `e2e-targeted`,
`e2e-full`, `e2e-repeat`) with the suggested command or "none". Ask the user to correct or say "none" for a check the
project doesn't have (render.md § 3b then leaves it out). A new project with no tooling yet gets "none" for all and a note that the first
feature should add them. Also ask: "Any other checks agents should run (a migrations check, a
security scan)?" and add each as a named check. Follow-up: "Which must pass before QA, and which before sign-off?" Suggest
`before_qa`: everything but e2e; `before_signoff`: everything. → `cmd.*`, `checks.*`

Follow-up when the stack has a tool that can narrow a check to what changed (a monorepo runner such as
Turborepo, Nx or pnpm filters; a test runner's changed-files mode such as `vitest --changed`,
`jest --changedSince` or `pytest --testmon`): "Before QA, Full-stack can run only what the branch
affects; QA still runs everything at sign-off. Use these?" then one line per check with the suggested
scope (`affected` with the command on the integration branch, `paths` with globs, or `full`). Suggest
`affected` for `unit` and `lint` when the tool supports it, and keep `typecheck` and `build` at `full`
unless a monorepo runner computes affected packages. Skip the question when nothing in the stack can
narrow a check. → `check_scope`, rendered into `project/CONTROLS.md` § Check scope

## Q6. Branches and release

"How do branches work?"
- Integration + production (e.g. `dev` → `main`, releases move production) (default when both exist)
- Single branch (feature PRs go straight to `main`)

Follow-up for two branches: names, then "Make `<integration>` the repository's default branch? New PRs, dependency bots and clones then land there, and issues close when a feature merges; visitors see unreleased work in its README." Default yes; suggest the production branch instead for a public library or tool whose visitors should see what shipped. Say what the scan found (the current default branch) and that only the owner can change it on the host. A single-branch flow: that branch, no question. Follow-up for both: "Who runs production steps (deploys, prod
migrations)?" (default: the owner only). Then: "Tag each release with its version (`v1.4.0`)? Tags
mark what shipped and help with rollbacks and hotfixes; nothing in the harness needs them." Default
yes; for an ongoing project, suggest whatever its existing tags show (`git tag --sort=-creatordate |
head`), and note any other version scheme for `project/RELEASE.md`. When the scan finds a per-package
versioning tool (`.changeset/`, `release` in `nx.json`, `release-please-config.json`, `lerna.json`) or
tags like `<name>@1.2.0`, suggest `per-package` instead: "Your packages carry their own versions
through <tool>. Keep that: each feature adds a change file, releases are named by date, and <tool>
writes the tags?" → `branches.*`,
`release.prod_steps_by`, `release_tags`, `branches.default`

## Q6b. Environments

"Which shared environments does the code go through? I'd keep two: `dev`, running `<integration>`,
and `production`, running `<production>`. Want more or fewer?" Say what the scan found first (host
config files such as `vercel.json`, `netlify.toml`, `fly.toml` or `render.yaml`, `environment:` keys in
workflows, a `staging` or `uat` branch, env files named after environments), and suggest that set
instead of the default when it differs.
- Keep two: `dev` and `production` (default with two branches)
- More: add one between them (for example `staging` or `uat`). Follow-up: "Does it run `<integration>`
  too, or its own branch that a promotion PR moves code into?" (default: `<integration>`)
- Fewer: production only (default with a single-branch flow), or none when nothing is deployed (a
  library, a CLI tool)

Then, for each environment, one line: "How does `<name>` get deployed (the host on push / a workflow /
by hand), and does it hold real people's data?" Suggest `host` when the scan found a host that
deploys on push, `real_data: true` for production and `false` for the rest. Say plainly that the list
can change later: edit `harness.config.yml` → `environments` and run `/morph-doctor`. → `environments`

With `apps`, ask the deploy line per app instead: "How does `<app>` reach each environment (host on
push / workflow / by hand / not deployed there)?" Suggest from each app's own host config
(`apps/web/vercel.json`, `apps/api/fly.toml`). → `apps[].deploy`

## Q7. Code host and CI

Ask as two questions, in the owner's terms (SKILL.md § Plain language).

**Where the code lives.** "Where should the code live online? That's the shared copy (a repository)
that you and the agents both work from. I'd use GitHub, as a private repository under `<owner>`: only
people you invite can see it." Options: GitHub (suggested), GitLab, or nowhere for now (it stays on
this computer). → `pr_host`

When there's no remote yet (`git remote` prints nothing), ask one more: "The project isn't online yet.
Want me to create the repository on GitHub as part of the install (private, under `<owner>`)? Or you
can do it later; everything works on this computer meanwhile, and `/morph-doctor` finishes the setup
once it's online." Suggest creating it. Yes → `create_remote` (`owner/name`, private or public); later
→ `pr_host: none` for now, and say the code host questions below are skipped until then.

**Whether the automatic checks must pass.** Skipped when `pr_host` is `none`. "Should the automatic
checks have to pass before a change can go in? CI is a robot on the code host that runs the tests on
every proposed change (a pull request); required means the host blocks the change until it passes."
Suggest yes only when CI runs the full checks. Otherwise suggest no, and say why: "There's no CI yet, so
QA's check of the final version is the gate. You can turn this on once CI has passed once." → `ci_gate`

Follow-up, skipped when `pr_host` is `none`: "Lock the main branches (`<branches from Q6b>`) so
changes only get in through an approved pull request, never by pushing straight to them or deleting
them? I'll write the rules, and at the end I can switch them on for you if your account is allowed to
(it needs admin rights), or show you how." Default yes. When the repository is private (or will be) and
the owner's GitHub plan is free (`gh api user --jq .plan.name`, or `gh api orgs/<org> --jq .plan.name`
for an organization, when `gh` can read it), add: "GitHub only enforces these rules on private
repositories with a paid plan (Pro, or Team for an organization). I'll still write them, so they're
ready if you upgrade or make the repository public; the agents' own rules keep them off these branches
meanwhile." Then: "How many people must approve a pull request before it goes in?" Suggest 0 with one
human ("you can't approve your own pull request on GitHub") and 1 with more. When the scan or `gh`
shows protection already on, say so and suggest keeping it. With protection on: "Tidy up
automatically: delete a pull request's working branch once it's merged? The main branches are locked,
so they're never deleted." Default yes; say what the host has now (`gh repo view --json
deleteBranchOnMerge`). With protection off, don't ask and record `false`. → `branch_protection.*`

Then: "Who merges PRs? By default you do, or I merge one when you ask for it by name. Or I can merge
a feature PR into `<integration branch>` by myself once QA and CI pass. Merges into production are
always yours." Suggest `never`; offer `integration` only when the integration branch differs from
the production branch. → `merge_by_agent`

## Q8. Roadmap

"Do you plan in versions with a roadmap doc?" Default yes for products, no for libraries and internal
tools. Yes unlocks the roadmap module and two follow-ups: the file paths (suggest `docs/ROADMAP.md`
and `docs/versions/`), and the first version's id and goal (suggest `v1` and the project description;
for an ongoing project, the next release the README or tags point to). → `roadmap.*`

## Q9. Data

Skip when the stack has no database. "Agents never write to shared remote databases. Do you want the
data-access module (local-stack tests for migrations and access rules, remote checks read-only)?"
Default yes when there's a migrations folder. Follow-up: "How do migrations reach the environments
from Q6b (a CI workflow, or you by hand)?" → `modules`, `data.*`

## Q9b. Pipelines (CI and deploys)

Skip when `pr_host` is `none`. Say what the scan found first ("I found `.github/workflows/ci.yml`
running lint and unit; no deploy or migrations workflow"). Then: "Want the ci-cd module? I can add
the pipelines you don't have yet. Each one only on your yes:"

1. **CI on pull requests**, running the `before_qa` checks with the commands from Q5. Suggest yes
   when there's no CI. When CI exists, offer only to keep it in step with `project/CONTROLS.md`.
   Then ask whether CI also runs on draft PRs (the TL opens a feature's PR as a draft at its first
   push and marks it ready after QA passes). Suggest no for a private repo (each push to a draft
   costs minutes; CI runs when the PR is marked ready) and yes for a public one (Actions are free).
   → `ci_cd.on_drafts`
2. **Deploy workflow.** Only when an environment from Q6b deploys by `workflow` and the repo has no
   deploy workflow. It offers exactly the Q6b environments, each deployable only from its own branch;
   `host` and `manual` environments add no file.
3. **Migrations workflow**, only with the data-access module and when Q9's answer was "CI
   workflow" with none in the repo.
4. **Tag workflow**, only with `release_tags: true` (not `per-package`) and on GitHub or GitLab. Suggest yes: it tags each
   merge to the production branch from the PR title, so nobody pushes tags by hand (cloud sessions
   can't). With a single-branch flow, say the owner runs it by hand with the version for a release.

Say plainly: agents write these files but never run deploys or migrations; the owner sets the
secrets, the protected environments and the required check (the module's § Owner steps). For each
new pipeline, time its main command locally and say the estimated minutes per run; mention that
public repos run GitHub Actions for free. Suggest keeping `ci_gate: false` until CI has passed once
and is a required check. No to all: drop the module; nothing is written. → `modules`, `ci_cd.*`

## Q10. Browser tests

Skip when there's no UI. "Use the browser-e2e module (e2e and accessibility rules for new pages)?"
Default yes for web apps. → `modules`

## Q11. Legal wording

Skip for internal tools. "Does the product have legal pages, consent or data-handling promises that
the agents might change?" Yes unlocks the legal module and the legal-writer agent's sources (suggest
`docs/LEGAL.md`). → `modules`, `legal.*`

## Q11b. Security

Skip for a tool with no sign-in, no payments and no data about people. "Does the product have
sign-in, take payments or keep data about people? The security module adds a short threat model to
the plan of every feature that touches those, a security review before testing, and two automatic
checks on every feature: one looks for passwords and keys left in the code (secret scanning), one
for libraries with known security holes (dependency audit)." Default yes when the scan finds auth,
payment or user-data code. Yes unlocks the commands for the two checks: suggest gitleaks for secrets
and the stack's own audit tool (`npm audit`, `pnpm audit`, `pip-audit`, `govulncheck`, `cargo audit`,
`bundle-audit`), check whether each is installed (its version command), and say that a missing tool is
the owner's install; the check is recorded as not run until then. → `modules`, `cmd.secrets`,
`cmd.audit`, `checks.*`

## Q12. Models and effort

"Here's the advised setup. Keep it?"

| Role | Model | Effort |
|------|-------|--------|
| Technical Lead (main chat) | opus | high |
| Full-stack | opus (sonnet for the medium variant) | high by default; medium for small low-risk work; xhigh for risky cores |
| QA | sonnet | high by default; medium for small low-risk work |
| Researcher (read-only, research mode) | sonnet (opus for the high variant) | medium by default; high for architecture or risk areas |
| Legal writer | fable (opus if fable isn't available) | high |

12a. "Which areas are risky enough to never get medium effort?" Suggest from the scan (auth, payments,
migrations, public API). → `risk_areas`

For a migration, show the earlier harness's agents table instead of the advised one, with the
differences marked, and keep its extra variants (a trial variant stays, with its trial).

12b. Only with Claude Projects: "Advised Claude Projects settings: coordinator opus at medium effort,
feature threads opus at high, one-shot threads opus at medium. Keep?" Note these are set in the Claude
Projects UI, not the repo. → `claude_projects.*`

Leave out the Legal writer row when the legal module is off. Accept any model or effort the user
names. → `agents.*`

## Q13. Loop settings

"The harness improves itself: a retro after each feature (usually up to 3 action items, more only
with a reason), and a prune every 10 learnings files. QA gets 2 rework rounds before it escalates
to you. Keep these?" → `loop.*`

## Answers file

The same keys, as YAML. A user can fill this by hand and point morph-init at it.

```yaml
project: { name: "", description: "" }
humans: [{ name: "", github: "", role: owner }]
environment: [claude-code-cli]
stack: { summary: "", package_manager: "", toolchain_setup: "", install_cmd: "" }
cmd: { install: "", typecheck: "", lint: "", unit: "", build: "", e2e-targeted: "", e2e-full: "", e2e-repeat: "", secrets: "", audit: "" }  # plus any extra named checks; secrets and audit with the security module
checks: { before_qa: [], before_signoff: [] }
check_scope:   # Q5 follow-up; one entry per check Full-stack may narrow; [] = every check runs in full
  - { check: unit, scope: affected, command: "" }   # scope: full | affected (command) | paths (paths: [globs])
apps: []        # Q4 follow-up, monorepos only; deploy keys are environment names (Q6b)
#  - { name: web, path: apps/web, stack: "", e2e: none, deploy: { dev: host, production: host } }
branches: { integration: dev, production: main, default: dev }
environments:   # in the order code moves through them; [] when nothing is deployed
  - { name: dev, branch: dev, deploy: host, real_data: false }
  - { name: production, branch: main, deploy: host, real_data: true }
release: { prod_steps_by: owner }
pr_host: github
create_remote: { repo: "", visibility: private }   # only when there's no remote yet and the owner said create it
ci_gate: false
merge_by_agent: never
branch_protection: { enabled: true, required_approvals: 0, delete_merged_branches: true }
release_tags: true                # true | false | per-package
ci_cd: { ci: none, on_drafts: false, deploy: host, migrations: none, tags: none, docs_regex: "" }   # ci-cd module; paths of accepted workflows
roadmap: { enabled: true, file: docs/ROADMAP.md, versions_dir: docs/versions, first_version: { id: v1, goal: "" } }
modules: []
data: { migrations_reach_remote_by: "" }
legal: { sources: [docs/LEGAL.md] }
risk_areas: []
agents: { technical_lead: { model: opus, effort: high },
          fullstack: { model: opus, medium_model: sonnet, default: high },
          qa: { model: sonnet, medium_model: sonnet, default: high },
          researcher: { model: sonnet, high_model: opus, default: medium },
          legal_writer: { model: fable, effort: high } }
claude_projects: { coordinator: { model: opus, effort: medium }, feature_threads: { model: opus, effort: high },
                   one_shot_threads: { model: opus, effort: medium } }
loop: { retro_max_items: 3, prune_every: 10, qa_max_rounds: 2 }
accepted: { skills: [], connectors: [], lessons: [] }
```
