# Module: roadmap (versions, scope and the owner's steps)

Optional, on by default. With it, a roadmap file (`roadmap.file` in `harness.config.yml`, default `docs/ROADMAP.md`) is the source of truth for which versions exist, what each is for and where it stands, and every version has its own folder under `roadmap.versions_dir` (default `docs/versions`). The roadmap and version docs describe **what** to build; the harness describes **how**. Without the module, the steps file goes in the feature folder (`<feature>/steps.md`) and scope is decided wherever `AGENTS.md` § Product docs says.

## Layout

```
docs/
  ROADMAP.md                  # the versions table, naming, rules, where everything else lives
  versions/
    <id>/
      <id>.md                 # scope and decisions (harness/templates/version.md)
      checklist.md            # what is left, for the next or a planned version (harness/templates/version-checklist.md)
      steps/
        README.md             # what this folder is
        <feature-slug>.md     # one feature's owner-only steps (harness/templates/steps.md)
```

## The roadmap file

**Versions table**, one row per version:

| Order | Version | Goal | Status | Marker | Document | Checklist |
|-------|---------|------|--------|------|----------|-----------|

- **Status words:** `shipped` (the owner said the version is done; it is live), `next` (the version being built now; exactly one row), `planned` (scoped with the owner and queued after `next`), `idea` (bullets only, not scoped). Finer progress lives in the version doc and its checklist.
- **The next version** is the one row whose **Marker** column says **NEXT** (and whose status is `next`). Agents go by the marker and the **Order** column, and use the file stem as the version id; the label is free text.

The file also has **Naming** (a version is a shippable release with its own goal and exit criteria; a phase is a build step inside a version; a feature's `<version>` folder number is the feature's own revision, not the product version), **Rules** (below), **Where everything else lives** (a question → document table) and a **Changelog**.

## Rules

1. **Scope moves through the roadmap.** A feature goes into a version doc first (with a one-line reason), then into a harness plan. Nothing is planned for a version that its doc doesn't list.
2. **A version doc holds:** goal, exit criteria, in scope, out of scope, done, still to do (split into *code* and *owner-only*), pre-launch checks, carried over from earlier versions, open decisions.
3. **The Technical Lead updates the version doc** at each feature's QA pass (move the item to *Done*, link the feature) and when the owner decides scope. Status changes in the roadmap table happen in the same edit.
4. **Product decisions are settled with the owner first** (pricing, names, limits, copy) and recorded in the version doc's *Decisions* table, not guessed in a plan.
5. **Deferred work has a home.** Anything cut from a version goes to the next version's doc under *Carried over*, or to *Out of scope* with the reason. Code scope that belongs to a later version than `next` goes to that version's doc, never to the next checklist.
6. **Exactly one `next`, and it always has a checklist.** Every version that is `next` or `planned` has a doc and a checklist from the templates.
7. **The marker moves only when the owner says a version is shipped.** A release tag inside a version does not move it. When the owner says so, the Technical Lead marks the version `shipped`, moves **NEXT** to the first `planned` row in order (or asks the owner if there is none), and carries every unticked checklist item to the new next checklist under *Carried over* unless the owner closes it.

## Steps files

At each feature's QA pass the Technical Lead writes the feature's owner-only steps to **its own file**, `<versions_dir>/<id>/steps/<feature-slug>.md` next to the next version's checklist, never into the checklist itself, so parallel feature branches don't edit the same lines (learned: the shared checklist was the second most common merge conflict). The procedure is [harness/SETUP.md](../../SETUP.md) § After QA pass.

- **Holds:** every step only the owner can do, with its expected result; every AC `qa-result.md` marks `deferred: local`; for a Data-access feature, the migrations to apply after the merge. The block heading links `qa-result.md`. None of these means no file, and `plan.md` **Steps file** says `none`.
- **Same commit:** `plan.md` **Status** becomes `passed` and **Steps file** names the path or `none`, on the feature branch, so it merges with the PR.
- **No row marked next, or more than one:** stop and ask the owner. With `planned` rows, recommend the first in order; with none, ask for the next version and its goal. Once decided, create the version doc and checklist, set the marker, then write the file. Until then the PR waits. With **Steps file:** `none`, set `passed` at once and don't wait.
- **The next version has no checklist:** create it from the template in the same edit.
- **An item belongs to a later version** (about that version's launch, not this feature): it goes to that version's doc, § Before launch.
- **Ticked** in place by the owner when done. **Folded** into the checklist § Human-only steps from features at each release ([harness/RELEASE.md](../../RELEASE.md)) and at each prune; the folded file is deleted. Until then, what is left for the owner is the checklist plus every file in `steps/`.

## Version checklist

`checklist.md` ([harness/templates/version-checklist.md](../../templates/version-checklist.md)) lists what is left for the version: **Code items** (an optional ordered build list), **Human-only steps from features** (one block per folded steps file, heading `### <feature-slug> (<title>)` linking its `qa-result.md`), **Carried over** from earlier versions, and **Before launch** (launch-only checks no feature owns).

## Checks before the feature PR

The Technical Lead's checks ([project/CONTROLS.md](../../../project/CONTROLS.md) § Before the feature PR): the roadmap marks exactly one next version and its checklist exists (`grep -c '| \*\*NEXT\*\* |' docs/ROADMAP.md` prints `1`), and `plan.md` **Steps file** names a file with this feature's block, or says `none`.

## On install

- Create `docs/ROADMAP.md` with the sections above and one row for the first version, marked `next` and **NEXT** (ask the owner for its id and goal).
- Create `docs/versions/<id>/<id>.md` and `checklist.md` from `harness/templates/version.md` and `version-checklist.md`, and `docs/versions/<id>/steps/README.md`.
- Fill [project/CONTROLS.md](../../../project/CONTROLS.md) § Before the feature PR with the two checks above.
- Keep the roadmap lines in `AGENTS.md` § Product docs and set `roadmap.enabled: true` in `harness.config.yml`.

## On remove

When the project doesn't choose this module, morph-init deletes this folder and the items below, and creates no `docs/ROADMAP.md` or `docs/versions/`. Steps files then live in the feature folder (`_harness/features/<slug>/<version>/steps.md`). Sentences that say "with the roadmap module" or "roadmap module on/off" (the Technical Lead rule and `.claude/rules/harness.md`, `AGENTS.md`, `harness/SETUP.md` § After QA pass and § Prune, `harness/STRATEGY.md`, `harness/HANDOFFS.md`, `harness/RELEASE.md`, checklist item 2, the plan, steps and prune templates, and the "One next version" row of `harness/CONTROLS.md`) stay as they are.

**Delete these files:**

- `harness/templates/version.md`
- `harness/templates/version-checklist.md`

**Delete the marked text:** every span and line marked `module:roadmap`, with the command in [harness/README.md](../../README.md) § Modules → **Module markers**.

**Delete or reword these lines** (unmarked: always-loaded, config or code-block text):

- `harness.config.yml`: set `roadmap.enabled: false` and remove `roadmap` from `modules`.
- `AGENTS.md` § Product docs: replace the paragraph that says `docs/ROADMAP.md` "is the source of truth for versions and scope" with where scope is decided in this project (an issue tracker, a product doc), or delete it.

**Unlink:** every Markdown link left pointing into `harness/modules/roadmap/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/roadmap' --include='*.md' . | grep -v '^./harness/modules/'`.
