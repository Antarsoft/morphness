# Stability

What Morphness promises to keep the same from 1.0 on, and what it leaves free to change. Until 1.0
this is the list we are working toward: a minor release may still change anything here, and it ships
an update note with the migration steps when it does ([CONTRIBUTING.md](CONTRIBUTING.md) § Releases).

## The promise

From 1.0, within one major version:

- Nothing listed under **Stable** below is renamed, removed or given a new meaning. A change that
  would do that waits for the next major version and ships with an update note that says how to
  migrate.
- New things may be added in a minor release: a config key with a default, a field in a record, a
  module, a skill. A copy that never uses them keeps working.
- `/morph-update` takes an install from any supported release to the current one without losing its
  records or its own edits. The kit's self-test replays that update from the oldest supported release,
  with owner edits next to upstream changes, changed config values and an update put off for later.
  The replay merges with git the way the skill describes; in a real update the model does the merge,
  and that part is checked by update runs made by hand.
- Something we plan to remove is marked deprecated in the changelog and keeps working for at least
  one minor release first.

## Stable

**1. `harness.config.yml` keys.** The keys in [template/harness.config.yml](template/harness.config.yml)
and what each one means: `project`, `humans`, `environment`, `branches`, `environments`, `apps`,
`pr_host`, `branch_protection`, `merge_by_agent`, `release_tags`, `roadmap`, `modules`, `checks`,
`ci_gate`, `ci_cd`, `risk_areas`, `agents`, `claude_projects`, `cost`, `guard`, `loop`, `updates` and
`installed_from`, with the keys under each. A value the template allows keeps working. The defaults
are not part of the promise (see **May change**).

**2. `installed_from`.** The block `/morph-update` reads to know where an install came from: `repo`,
`commit`, `release`, `updates` (`applied`, `declined`, `deferred`) and `lessons` (`declined`,
`deferred`; a copy without it reads as empty lists). Updates depend on it, so it changes only with a
major version, apart from added keys like that one.

**3. `_harness/` records.** The folder layout in [template/_harness/README.md](template/_harness/README.md)
and the forms the kit's scripts read:

- `features/<feature-slug>/<version>/` and its `Plan/`, `Research/`, `Legal/`, `Development/` and `QA/`
  folders.
- `learnings/<feature-slug>-v<version>.md`: the title, the entry line and the `## Action items` table
  ([template/_harness/learnings/README.md](template/_harness/learnings/README.md)).
- `LEARNINGS.md`: the Prune status table, the folded entry line, and the action item tables with their
  columns and states (`open`, `approved`, `deferred`, `applied`, `skipped`).
- `prunes/<YYYY-MM-DD>.md` (a letter after the date when there were several that day) and
  `trials/<trial-slug>.md`.

A script that reads these records keeps reading every older form it ever read, the way
`scripts/evidence.sh` reads the entry form projects wrote before the template changed. Records a
project has written are never rewritten by an update without the owner's yes.

**4. Update notes.** The note format in [updates/README.md](updates/README.md): the front matter
(`id`, `title`, `kind`, `release`, `applies_to`, `offer_module`, `files`, `removed`) and the sections
What changed, Why, How to apply and Skip if. Installs record note ids in `installed_from.updates`, so an
id never changes once released.

**5. Skills and the plugin.** The plugin name `morphness@morphness` and the skill names `/morph-init`,
`/morph-doctor`, `/morph-update`, `/morph-module` and `/morph-share`. What a skill asks and how it
words its output may change; the name and what it is for do not.

**6. Agent roles.** Technical Lead, Full-stack engineer, QA engineer, Legal writer and Researcher,
their file names under `harness/agents/` and `.claude/agents/`, and the lifecycle between them (the
Technical Lead plans and delegates, Full-stack implements, QA validates). A project's own additions
in `project/agents/<role>.md` keep applying on top.

**7. Script entry points.** The commands owners and skills run, their options and exit codes:
`scripts/guard.sh` as the `PreToolUse` hook (exit 2 denies), `scripts/session-start.sh` (and
`--accept`), `scripts/prune-counter.sh` (and `--prune`), `scripts/feature-cost.sh`, and
`scripts/evidence.sh` (`--json`, `--out`, `--force`) with the field names of its JSON output, which
`/morph-share` publishes.

**8. Schema number.** `harness.config.yml` → `harness_schema` is `1` for this surface. It rises only
with a major version, and that version's update note migrates the copy and sets the new number.
`/morph-doctor` reports a copy without the key, or with a number other than the one it knows.

## May change in any release

These are tuned all the time, so they are not part of the promise. A change to any of them still gets
an update note when it reaches installs.

- **The guard gets stricter.** A new deny or ask rule, or a closed gap, ships in a patch or minor
  release. Safety fixes never wait for a major version. A rule that becomes looser is called out in
  the changelog.
- Rule and process text in `harness/` and the agent bodies, checklists, templates and their wording.
- Defaults: models and effort per agent, `loop` budgets and thresholds, `guard` group defaults,
  `checks` lists.
- `harness/MODEL_PRICES.md`, lessons, profiles, catalog entries and the site.
- Scripts under `scripts/lib/`, the kit's own scripts at the repo root, and anything not named above.

## Supported releases

| Release line | Updates with `/morph-update` | Fixes |
|--------------|------------------------------|-------|
| v0.13.0 and later | Yes; the self-test replays the update from v0.13.0 | Until 1.0 ships, then safety fixes only for 60 days |
| Dated releases (2026-10-12 to 2026-10-20.5) | Best effort | None; update to v0.13.0 or later, or reinstall |
| 1.x | Yes, from any 1.x and from v0.13.0 | The latest 1.x minor |

A copy installed from a dated release can still run `/morph-update`; the notes it hasn't seen are all
there. The kit just doesn't test that path. If it goes wrong, `/morph-init` on a fresh branch and a
merge of the project's `project/` and `_harness/` folders is the way back.

## Reporting a break

A release that breaks something on this list is a bug: open an issue with the release you updated
from and to. A security problem goes through [SECURITY.md](SECURITY.md) instead, and gets a reply within
a week.
