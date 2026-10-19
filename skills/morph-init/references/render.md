# Rendering the harness into the target

Run these steps only after the user's final yes in Phase 3. `SRC` is the Morphness source folder,
`T` the target repo root.

## 1. Branch

Create `morph/install` from the integration branch (or the only branch). If the branch exists, ask
before reusing it. Never commit to the integration or production branch directly, apart from the first
commit below.

**No repository or no commits yet.** Without a repository, run `git init -b <integration>`. With no
commits, first save the folder as it is, so the install PR shows only the harness:
1. If there's no `.gitignore`, write one for the stack (dependencies, build output, `.env*` and other
   secret files, OS files). Never stage a file that looks like it holds secrets.
2. Show the owner the list of files about to be saved, and on their yes commit them on the integration
   branch as `chore: start repository` (authored as the owner, from `git config`).
3. With two branches, create the production branch from that same commit (`git branch <production>`).

**No remote yet, and the owner asked to create it** (`create_remote`). Do it now, before any harness
file exists, so the agents' push rules don't apply yet: `gh repo create <owner>/<name> --private
--source . --remote origin` (`--public` if they chose it; GitLab: `glab repo create`), then
`git push -u origin <integration>` and the production branch. If `gh` is missing, not signed in or
refused, don't try another way: give the owner the plain steps (on github.com: the **+** menu → **New
repository**, the name, **Private**, leave every "Initialize" box unticked, **Create repository**; then
in a terminal opened in the project folder, `git remote add origin <the URL GitHub shows>` and
`git push -u origin <integration> <production>`), and carry on with the install locally; § 8 then ends
without a push, and `/morph-doctor` finishes the setup once the project is online.

## 2. Copy without overwriting

Copy every file under `SRC/template/` to the same path in `T`, skipping any file that already exists.
`SRC/scripts/install.sh --no-clobber <T>` does this and prints what it skipped. If the permission layer refuses the script or `cp -n` (a project allowlist without `Bash(bash:*)`), ask the owner to allow it once, or copy file by file and skip what exists. For each skipped file:

| File exists | Do |
|-------------|----|
| `CLAUDE.md` | Keep the user's content. Append the template's `CLAUDE.md` body under a `## Morphness` heading, or add the line `@AGENTS.md` if the template's AGENTS.md was copied. |
| `AGENTS.md` | Keep it. Append the template's golden rules and harness table under `## Morphness`, without duplicating rules it already has. |
| `.claude/settings.json` | Merge: union `permissions.allow`, `deny`, `ask`; add the SessionStart and PreToolUse (guard) hooks if absent; an existing PreToolUse hook stays, with the guard added as one more entry; keep every existing key. Show the diff. |
| `.github/pull_request_template.md` (GitLab: `.gitlab/merge_request_templates/Default.md`) | Keep the user's. Mention the template's sections in the hand-off, and that the tag workflow reads a `## Release notes` section. |
| `.mcp.json` | Merge `mcpServers`; never remove one. |
| Anything else | Keep the user's file; list it in the hand-off. |

## 2b. Migrating an earlier harness

Use this instead of step 2 when Phase 0 found an earlier harness of the same shape (`harness/`,
`_harness/`, `project/`, `.claude/rules/`, `.claude/agents/`) and no `harness.config.yml`. The project
keeps everything it learned; it moves into the places Morphness reads it from.

1. **Keep the runtime history.** Leave `_harness/` alone (features, learnings, prunes, releases,
   `LEARNINGS.md`, the backlog and any archive). Copy only `_harness/` template files that don't exist,
   and refresh `_harness/README.md`'s layout block if it lacks folders the kit uses.
2. **Replace the kit files.** Copy over, overwriting: `harness/**` (kit docs, `agents/`, `modules/`,
   `templates/`), `.claude/rules/{harness,testing}.md`, the `.claude/agents/*.md` files
   the template has, `AGENTS.md` and `CLAUDE.md`, and add `harness.config.yml`. Delete kit files the
   template no longer has (a version file, a doc a module now covers) once step 3 has moved their
   project content. Every old file stays readable with `git show <integration branch>:<path>`.
3. **Move the project content.** Diff each old kit file against its new counterpart. Every line that
   names this project (a path, a command, a vendor, a value, a date, an owner decision, a feature slug
   cited as evidence) moves to the project file that holds that topic: commands and CI to
   `project/CONTROLS.md`, test rules to `project/TESTING.md`, plan checklist greps to
   `project/PLAN_CHECKLIST.md` (grouped under the kit item they sharpen, plus `P` items for the rest),
   role details to `project/agents/<role>.md` addenda, agents and effort to
   `project/HARNESS_AGENTS.md`, trials to `_harness/trials/<slug>.md` (from `harness/templates/trial.md`), release steps to `project/RELEASE.md`, anything else to the matching
   `project/` file or a new `project/PROCESS.md`. A generic line the kit already says in substance can
   go; when in doubt, keep it. Project files that already exist keep their content and get the kit's
   vocabulary (step 5).
4. **Keep what the template doesn't cover.** Extra agent variants (a trial variant keeps its trial),
   project-only rule files in `.claude/rules/`, a custom `scripts/session-start.sh`, a richer
   `.claude/settings.json` (merge per step 2's table), the PR template and `.mcp.json`: keep them and
   point the new docs at them.
5. **Map old names.** When the kit renamed a field or file (a plan field, a QA section, a checklist
   numbering), add a short table to the project file that owns it ("old item 4 → kit item 21 and
   P3"), so retros and prunes in `_harness/` still resolve. Never rewrite history files to the new names.
6. **Prove nothing was lost.** For each replaced or deleted file, list in the PR body where its
   project-specific lines went, and the lines dropped because the kit already says them.

Then continue with step 3 below; most placeholders are filled from the old files.

## 3. Fill placeholders

Replace every `{{key}}` in the copied files with its answer. Keys: `project.name`, `project.description`,
`human.name`, `human.github` (the owner), `branches.integration`, `branches.production`, `stack.summary`,
`stack.package_manager`, `stack.toolchain_setup`, `stack.install_cmd`, `cmd.<check-name>`, `models.tl`,
`models.fullstack`, `models.fullstack_medium`, `models.qa`, `models.qa_medium`, `models.researcher`, `models.researcher_high`, `models.legal`, `morphness.repo`, `morphness.commit`, `morphness.release`,
and in ci-cd workflow scaffolds `ci.docs_regex` (a regex for the documentation paths in `harness/CONTROLS.md` § Documentation paths with `project/CONTROLS.md`'s changes; it must not match `.claude/settings.json`, hook or skill scripts),
`ci.on_drafts` (`ci_cd.on_drafts`, exactly `true` or `false`: it lands inside an Actions expression, so any other text breaks the workflow),
`environments.names` (the names in `environments`, comma-separated, in order) and `environments.first`
(the first name), and in `.github/rulesets/environment-branches.json` `branch_protection.refs` (each
distinct environment branch as `"refs/heads/<branch>"`, comma-separated) and
`branch_protection.required_approvals` (a number).
Model placeholders (`{{models.tl}}` etc.) take the model alias the user accepted. Check commands
(`{{cmd.<name>}}`) take the command. A check the project doesn't have gets no placeholder text: its
rows go, per § 3b.
In `scripts/session-start.sh` the commands sit inside single quotes: write an empty string when there
is no toolchain setup or install command, and escape any `'` in a command as `'\''`.

`<!-- morph-init: fill … -->` comments are prose to write: fill each from the answers and the repo
scan, in the style of the surrounding file, then delete the comment. Where there's nothing to say
yet, leave a one-line "Not set yet: <what goes here>" so a later retro can fill it.

Fill `installed_from` in `harness.config.yml` with the source repo URL, commit and release, and leave
`updates` empty: every update note up to that commit is already in the template.

## 3b. Config values

Write the answers into `harness.config.yml`, replacing the defaults that aren't placeholders:
`environment`, `branches`, `environments`, `pr_host`, `roadmap`, `modules`, `checks.before_qa`,
`checks.before_signoff` (plus any extra named checks the user added), `apps`, `ci_gate`, `merge_by_agent`, `branch_protection`, `release_tags`, `ci_cd` (delete the
block without the ci-cd module), `risk_areas`,
`agents`, `claude_projects` (delete the block when Claude Projects isn't used) and `loop`.

`environments`: the first entry's branch is `branches.integration` and the last one's is
`branches.production`; with a single-branch flow and one environment, both are that branch. Write
`environments: []` when nothing is deployed. `project/RELEASE.md` § Where things deploy gets one row
per entry, in the same order.

`apps`: write `apps: []` when the user kept one app (or the scan found one). Otherwise one entry per
accepted app; each `deploy` key is an `environments` name. Fill `project/STACK.md` § Apps, add the
App column to `project/RELEASE.md` § Where things deploy, and add each shared package folder the apps
depend on to `project/CONTROLS.md` § Cross-cutting paths. With the ci-cd module, write one deploy job
per app that has `workflow` for some environment (the deploy scaffold's fill comment).

`check_scope` (answers file only, not a config key): one row per entry in `project/CONTROLS.md`
§ Check scope (`paths` entries list their globs in the last column); an empty list writes the "None:
every check runs in full." line.

`branches.default`: when the host's current default branch differs (the scan, or `git remote show origin`), add the owner step from `project/RELEASE.md`'s fill comment to § Manual steps and to the hand-off. For dependency bots already configured (`.github/dependabot.yml`, `renovate.json`) with a default branch that isn't the integration branch, set their target branch to the integration branch.

`branch_protection`: with `enabled: true` on GitHub, keep `.github/rulesets/environment-branches.json`;
with `ci_gate: true`, add a `required_status_checks` rule naming the CI job. Otherwise (GitLab, no
host, or `enabled: false`) delete the file, its link in `harness/RELEASE.md` § Branch protection and
that file's § Applying it yourself (GitLab: replace it with the protected-branch steps).
Whatever § 7b can't apply goes in `project/RELEASE.md` § Manual steps and the hand-off: importing the
ruleset (or setting GitLab's protected branches) and turning on branch deletion after merge. In `.claude/settings.json`, add the same four `git push` deny lines the
template has for the integration branch for every other environment branch (a middle branch). When integration and production are the same branch, write each pattern once.

`release_tags: per-package`: fill `project/RELEASE.md` § Versions from the tool's config, and in the
PR template replace `vX.Y.Z` in the Release and Hotfix comments with `YYYY-MM-DD` (a date). With
`true` or `false`, keep the package-versions line out of the PR template.

`pr_host`: on GitLab, move `.github/pull_request_template.md` to
`.gitlab/merge_request_templates/Default.md` (the default merge request template) and, when nothing
else is left in `.github/`, delete that folder; with `none`, delete the template. Kit text that names
`.github/pull_request_template.md` then means that file.

`merge_by_agent`: with `never`, keep the merge `ask` rules in `.claude/settings.json`, and add the
merge tool of any other code-host connector the project uses. With `integration`, delete them (the
Technical Lead merges into the integration branch without a prompt) and say in the hand-off that
production merges stay the owner's by rule and by branch protection.

A named check the project doesn't have (the user said "none" in Q5): delete its row from
`project/CONTROLS.md` § Named checks and § Check scope, its row from `project/STACK.md` § Commands,
and its name from `checks.*`. Never write a placeholder such as "none" or "not configured" instead.
Agents then record it as **not run** wherever the kit names it, and the feature that adds the check
adds its row and name back. A new project with no tooling yet can end with empty `checks` lists.
Write real commands inside the backticks, never prose.

Add `.claude/settings.local.json` to `.gitignore` (create the file if missing).

## 4. Modules

For each module in `modules`, keep `harness/modules/<name>/` and apply its "On install" section (each
module README has one). For modules not chosen, follow that module's "On remove" section (the
files to delete, the marked text, the lines to drop), then delete its folder, so agents don't read
rules that don't apply. Marked text goes with the command in `harness/README.md` § Modules → **Module
markers**; markers of chosen modules stay, so a later removal is just as mechanical.

- `claude-projects`: keep the playbook; the hand-off prints it.
- `data-access`: add `deny` rules in `.claude/settings.json` for the write tools of any accepted
  database connector, and the project's remote-write CLI commands (`ask` for read-only ones the user
  wants to approve case by case).
- `ci-cd`: copy only the accepted scaffolds from `harness/modules/ci-cd/github/` to `.github/workflows/`
  (GitLab: write the same jobs into `.gitlab-ci.yml`), never over an existing file, and fill them.
- `browser-e2e`, `legal`, `roadmap`, `security`: follow their On install sections.

Without the roadmap module, steps files live at `_harness/features/<slug>/<version>/steps.md`.

## 5. Lessons

For each accepted lesson, add its `## Rule` text to its `target` file: in a numbered list (the plan
checklists), as the next number at the end of the group its tags fit, else at the end; in a file of
bullets, as a bullet at the end of the section that fits; with no fitting section, under a
`## Adopted lessons` heading at the end of the file. End it with `(lesson: <id>)`. Skip one whose rule already exists in substance.
Never offer a lesson with `status: superseded` or `in_template: true` (already in the kit).
Record accepted lesson ids in `_harness/morph-answers.yml` § accepted.

## 6. Skills and connectors

Run the accepted install commands from `catalog.md`. Create `.claude/skills` as a symlink to
`.agents/skills` when skills were installed and no `.claude/skills` exists. Add accepted project-scoped
MCP servers to `.mcp.json`. List the accepted user connectors in `project/SKILLS_AND_MCPS.md` with
the reason, so a teammate knows to add them.

Fill `project/SKILLS_AND_MCPS.md` § Service tools: one row per external service in the answers, with
the official MCP found in Phase 2 (source and date) or "none found (<date>)", how it's connected (or
"not connected" when declined), and what setup work it can and can't do, from its tool list when the
session has it, else from the vendor's page. For every accepted connector that can write, add `ask`
rules in `.claude/settings.json` for each tool that creates, changes or deletes something (by name,
for example `mcp__<server>__create_project`), and `deny` for tools that write a remote database
(migrations, SQL that writes, database branches). List them in § Permission rules added for this
project.

## 7. Self-checks

All must pass before committing; fix and re-run on failure.

1. No `{{` placeholder remains in `T` outside code blocks that quote the placeholder syntax:
   `grep -rnE '(^|[^$]){{ *[a-z]' AGENTS.md CLAUDE.md harness.config.yml project .claude scripts .github`
   (the `[^$]` keeps CI expressions such as `${{ secrets.X }}` out of the result).
2. No fill comment remains: `grep -rn '<!-- morph-init: fill' .` returns nothing.
3. `.claude/settings.json`, `.mcp.json` and `.github/rulesets/*.json` parse (`jq . <file>`, or `python3 -m json.tool`), and
   `.claude/settings.json` → `hooks.PreToolUse` runs `scripts/guard.sh`.
4. Every relative link in `AGENTS.md`, `CLAUDE.md`, `harness/**` (except `harness/templates/`, whose
   links resolve where the template is copied), `project/**` and `.claude/**` (except `.claude/skills/`, which holds installed third-party skills)
   resolves to a file that exists. Links to docs a module creates (the roadmap) count once that module's On install ran.
5. `.claude/agents/*.md` frontmatter has `name`, `description` and `model`.
6. Each named check in `checks.*` has a row with a real command in `project/CONTROLS.md` § Named
   checks, and no row there names a check missing from `checks.*` or has "none" or "not configured"
   as its command.
7. With the ci-cd module, each workflow it wrote parses as YAML, has no `# morph-init: fill` line
   left (`grep -rn 'morph-init: fill' .github/workflows`), and passes `actionlint` when it is installed.
   Its CI steps run the `before_qa` commands exactly as `project/CONTROLS.md` writes them.
8. `environments` matches the branches (first entry on `branches.integration`, last on
   `branches.production`, names unique), and `project/RELEASE.md` § Where things deploy has one row
   per entry. With the ci-cd module, the deploy and migrations workflows offer exactly those names
   and their branch guards have one `case` line per name.
   Each `apps` entry's `path` exists, and its `deploy` keys are names in `environments`.
9. `scripts/session-start.sh` is executable and parses (`bash -n scripts/session-start.sh`). Don't
   run it here: it installs dependencies. `scripts/prune-counter.sh` runs and prints
   `Prune counter: 0/<loop.prune_every>`. `scripts/feature-cost.sh` is executable and runs without a
   Python error (it may print `Cost: not measured`, or this session's cost). Both read
   `harness.config.yml` through `scripts/lib/config.sh`: `bash -c '. scripts/lib/config.sh;
   config_get branches.integration'` prints the integration branch. The prune counter prints
   the `Rules:`, `Checklists:` and `Project docs:` gauge lines after the counter, with no `Prune is DUE`.
   `scripts/guard.sh` parses and blocks a push to the integration branch:
   `echo '{"tool_name":"Bash","tool_input":{"command":"git push origin <integration>"}}' | bash scripts/guard.sh`
   exits 2 (python3 must be installed; without it the guard lets everything through, so say so in the
   hand-off).

## 7b. Apply host settings (owner's yes)

Skip on GitLab without `glab`, on `pr_host: none`, with no remote (the owner creates it later and
`/morph-doctor` applies this then), and when `branch_protection.enabled` is `false`.
Otherwise ask once: "Apply the branch protection now with `gh api`? It needs admin rights on the
repo." Only on a yes, for this repo (`<owner>/<repo>` from `gh repo view --json nameWithOwner`).
With the ci-cd module, `gh api` calls on rulesets and protection are `ask` rules, so each one shows
a permission prompt: tell the owner to allow it there.

1. **Ruleset.** `gh api repos/<owner>/<repo>/rulesets` and look for one named like the file's
   `name`. None: `gh api -X POST repos/<owner>/<repo>/rulesets --input .github/rulesets/environment-branches.json`.
   One: show the owner how it differs, and on a yes `gh api -X PUT repos/<owner>/<repo>/rulesets/<id> --input <the file>`.
2. **Branch deletion** with `delete_merged_branches: true`:
   `gh api -X PATCH repos/<owner>/<repo> -F delete_branch_on_merge=true`.
3. **Read back:** `gh api repos/<owner>/<repo>/rules/branches/<branch>` for each environment branch
   shows `pull_request`, `non_fast_forward` and `deletion`; `gh repo view --json deleteBranchOnMerge`
   shows `true`.

On any failure (403 or 404 without admin rights, no `gh`, a denied command, a proxy refusal), stop
and don't retry another way. Hand the owner `harness/RELEASE.md` § Applying it yourself, with every
placeholder filled in: `<owner>/<repo>`, the branch that holds the ruleset file (the install branch
until its PR merges, then the integration branch) and the file's link on the host, and the project
folder's path when this session runs on the owner's computer. Give both ways, website first, each step
on its own line, never a bare command. When the error says the plan doesn't allow it (a 403 that
mentions GitHub Pro or upgrading), lead with that in plain words: neither way works until the
repository is public or on a paid plan, the agents' own rules keep them off those branches meanwhile,
and `/morph-doctor` offers it again later. Add one row to `project/RELEASE.md` § Manual steps pointing
to that section, and say which steps were applied and which are the owner's.

## 8. Commit and PR

Stage only the files you created or changed, by path. Commit message:
`chore: install Morphness harness`. Then:

- **With a remote:** ask before pushing; then push and open a PR to the integration branch titled
  "Install Morphness harness", with a body listing the answers summary, accepted skills, connectors
  and lessons, and the skipped files. The PR is the user's to review and merge.
- **No remote:** nothing is pushed. Tell the owner the harness is on the `morph/install` branch on
  this computer, and offer to merge it into the integration branch on their yes
  (`git switch <integration> && git merge --no-ff morph/install`). Say that until the project is
  online, the agents work and merge on this computer, and that `/morph-doctor` finishes the code host
  setup (pull requests, CI, branch protection) once it is.
