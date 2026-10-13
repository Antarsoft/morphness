# Rendering the harness into the target

Run these steps only after the user's final yes in Phase 3. `SRC` is the Morphness source folder,
`T` the target repo root.

## 1. Branch

Create `morph/install` from the integration branch (or the only branch). If the branch exists, ask
before reusing it. Never commit to the integration or production branch directly.

## 2. Copy without overwriting

Copy every file under `SRC/template/` to the same path in `T`, skipping any file that already exists.
`SRC/scripts/install.sh --no-clobber <T>` does this and prints what it skipped. For each skipped file:

| File exists | Do |
|-------------|----|
| `CLAUDE.md` | Keep the user's content. Append the template's `CLAUDE.md` body under a `## Morphness` heading, or add the line `@AGENTS.md` if the template's AGENTS.md was copied. |
| `AGENTS.md` | Keep it. Append the template's golden rules and harness table under `## Morphness`, without duplicating rules it already has. |
| `.claude/settings.json` | Merge: union `permissions.allow`, `deny`, `ask`; add the SessionStart hook if absent; keep every existing key. Show the diff. |
| `.github/pull_request_template.md` | Keep the user's. Mention the template's sections in the hand-off. |
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
   `templates/`), `.claude/rules/{technical-lead,harness,testing}.md`, the `.claude/agents/*.md` files
   the template has, `AGENTS.md` and `CLAUDE.md`, and add `harness.config.yml`. Delete kit files the
   template no longer has (a version file, a doc a module now covers) once step 3 has moved their
   project content. Every old file stays readable with `git show <integration branch>:<path>`.
3. **Move the project content.** Diff each old kit file against its new counterpart. Every line that
   names this project (a path, a command, a vendor, a value, a date, an owner decision, a feature slug
   cited as evidence) moves to the project file that holds that topic: commands and CI to
   `project/CONTROLS.md`, test rules to `project/TESTING.md`, plan checklist greps to
   `project/PLAN_CHECKLIST.md` (grouped under the kit item they sharpen, plus `P` items for the rest),
   role details to `project/agents/<role>.md` addenda, agents, effort and trials to
   `project/HARNESS_AGENTS.md`, release steps to `project/RELEASE.md`, anything else to the matching
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
`models.fullstack`, `models.fullstack_medium`, `models.qa`, `models.qa_medium`, `models.legal`, `morphness.repo`, `morphness.commit`,
and in ci-cd workflow scaffolds `ci.docs_regex` (a regex for the documentation paths in `project/CONTROLS.md`).
Model placeholders (`{{models.tl}}` etc.) take the model alias the user accepted. Check commands
(`{{cmd.<name>}}`) take the command, or the text `none (add when the project has one)`.
In `scripts/session-start.sh` the commands sit inside single quotes: write an empty string for
"none", and escape any `'` in a command as `'\''`.

`<!-- morph-init: fill … -->` comments are prose to write: fill each from the answers and the repo
scan, in the style of the surrounding file, then delete the comment. Where there's nothing to say
yet, leave a one-line "Not set yet: <what goes here>" so a later retro can fill it.

Fill `installed_from` in `harness.config.yml` with the source repo URL and commit.

## 3b. Config values

Write the answers into `harness.config.yml`, replacing the defaults that aren't placeholders:
`environment`, `branches`, `pr_host`, `roadmap`, `modules`, `checks.before_qa`,
`checks.before_signoff` (plus any extra named checks the user added), `ci_gate`, `ci_cd` (delete the
block without the ci-cd module), `risk_areas`,
`agents`, `claude_projects` (delete the block when Claude Projects isn't used) and `loop`.

A named check the project doesn't have: delete its row from `project/CONTROLS.md` § Named checks and
its name from `checks.*`, rather than writing a placeholder command. Agents then record it as
**not run** wherever the kit names it. Write real commands inside the backticks, never prose.

Add `.claude/settings.local.json` to `.gitignore` (create the file if missing).

## 4. Modules

For each module in `modules`, keep `harness/modules/<name>/` and apply its "On install" section (each
module README has one). For modules not chosen, follow that module's "On remove" section (the
files to delete and the lines to drop), then delete its folder, so agents don't read rules that don't
apply.

- `claude-projects`: keep the playbook; the hand-off prints it.
- `data-access`: add `deny` rules in `.claude/settings.json` for the write tools of any accepted
  database connector, and the project's remote-write CLI commands (`ask` for read-only ones the user
  wants to approve case by case).
- `ci-cd`: copy only the accepted scaffolds from `harness/modules/ci-cd/github/` to `.github/workflows/`
  (GitLab: write the same jobs into `.gitlab-ci.yml`), never over an existing file, and fill them.
- `browser-e2e`, `legal`, `roadmap`: follow their On install sections.

Without the roadmap module, steps files live at `_harness/features/<slug>/<version>/steps.md`.

## 5. Lessons

For each accepted lesson, add its `## Rule` text to its `target` file: in a numbered list (the plan
checklists), as the next number at the end of the group its tags fit, else at the end; in a file of
bullets, as a bullet at the end of the section that fits; with no fitting section, under a
`## Adopted lessons` heading at the end of the file. End it ending with `(lesson: <id>)`. Skip one whose rule already exists in substance.
Never offer a lesson with `status: superseded` or `in_template: true` (already in the kit).
Record accepted lesson ids in `_harness/morph-answers.yml` § accepted.

## 6. Skills and connectors

Run the accepted install commands from `catalog.md`. Create `.claude/skills` as a symlink to
`.agents/skills` when skills were installed and no `.claude/skills` exists. Add accepted project-scoped
MCP servers to `.mcp.json`. List the accepted user connectors in `project/SKILLS_AND_MCPS.md` with
the reason, so a teammate knows to add them.

## 7. Self-checks

All must pass before committing; fix and re-run on failure.

1. No `{{` placeholder remains in `T` outside code blocks that quote the placeholder syntax:
   `grep -rnE '(^|[^$]){{ *[a-z]' AGENTS.md CLAUDE.md harness.config.yml project .claude scripts .github`
   (the `[^$]` keeps CI expressions such as `${{ secrets.X }}` out of the result).
2. No fill comment remains: `grep -rn '<!-- morph-init: fill' .` returns nothing.
3. `.claude/settings.json` and `.mcp.json` parse (`jq . <file>`, or `python3 -m json.tool`).
4. Every relative link in `AGENTS.md`, `CLAUDE.md`, `harness/**` (except `harness/templates/`, whose
   links resolve where the template is copied), `project/**` and `.claude/**` (except `.claude/skills/`, which holds installed third-party skills)
   resolves to a file that exists. Links to docs a module creates (the roadmap) count once that module's On install ran.
5. `.claude/agents/*.md` frontmatter has `name`, `description` and `model`.
6. Each named check in `checks.before_qa` has a command or "none" in `project/CONTROLS.md`.
7. With the ci-cd module, each workflow it wrote parses as YAML, has no `# morph-init: fill` line
   left (`grep -rn 'morph-init: fill' .github/workflows`), and passes `actionlint` when it is installed.
   Its CI steps run the `before_qa` commands exactly as `project/CONTROLS.md` writes them.
8. `scripts/session-start.sh` is executable and parses (`bash -n scripts/session-start.sh`). Don't
   run it here: it installs dependencies.

## 8. Commit and PR

Stage only the files you created or changed, by path. Commit message:
`chore: install Morphness harness`. Ask before pushing; then push and open a PR to the integration
branch titled "Install Morphness harness", with a body listing the answers summary, accepted skills,
connectors and lessons, and the skipped files. The PR is the user's to review and merge.
