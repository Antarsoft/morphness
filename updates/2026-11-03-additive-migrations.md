---
id: 2026-11-03-additive-migrations
title: A new migration that only adds runs in small mode, with the database tests and one code review
kind: template
release: unreleased
applies_to: { modules: [] }
files:
  - harness/MODES.md
  - harness/templates/small-plan.md
  - project/CONTROLS.md
  - scripts/risk-check.sh
removed: []
reviewed: "It changes scripts/risk-check.sh, which picks the mode. A new .sql migration in a risk area named for the database now prints Mode: plain, with + lines and a Needs: line, when every statement fits a strict allow-list in the public schema: a new table with row-level security on, added columns with plain-value defaults, checks, unique and foreign keys, indexes, policies for named roles and grants on the new tables, stable or immutable SQL functions that only select and whose names no .sql file of the integration branch uses yet, and comments. A .sql database test in a test folder counts too. Tables and columns named for sign-in, secrets, money or permissions, anything it cannot read safely (a doubled quote in a name, a backslash in a string, another schema), row-level security changes on existing tables, a failed read of the integration branch, edits to merged migrations, unwritten migrations, the owner forcing full and any other risk path stay full. No guard rule, permission or config value changes."
---

## What changed

- **`scripts/risk-check.sh`** reads a database file on a risk path before it calls the change full.
  - It counts as plain when the file matches only risk areas named for the database, and it is either:
    - a new `.sql` migration whose every statement only adds, or
    - a `.sql` database test in a test folder, outside the migrations.
  - "Only adds" is a strict allow-list, in the `public` schema:
    - a new table, with no `if not exists` and no copy of another table, with row-level security turned on (turning it on or forcing it counts only for the new tables);
    - columns with plain-value defaults, checks, unique keys and foreign keys added to a table;
    - indexes;
    - policies for named roles, and grants, on the new tables (never to `anon` or `public`, never a condition that lets every row through, never `with grant option`);
    - `stable` or `immutable` SQL functions whose body only selects, and whose name no `.sql` file of the integration branch uses yet (a new overload can take over an existing call; functions that live only in the database are left to the code review);
    - comments.

    Expressions may call only plain value functions and the functions the file creates. Anything it can't read safely is full: a prefixed string, a backslash in a string, a doubled quote in a name, a `$` outside a `$$` body, another schema, or an integration branch it can't read.
  - The output keeps `Mode: plain` on the first line, adds one `+ <file>: …` line per such file, and ends with a `Needs:` line asking for the database tests and one code review.
  - These stay full:
    - tables or columns named for sign-in, secrets, money or permissions;
    - an edit to a migration the integration branch already has;
    - a migration that is named but not written yet (with a `Note:` line);
    - any change that is full for another reason, or that the owner forces full. Then the database files are risk paths again.
- **`harness/MODES.md` § Additive migration** (new, under § Small mode): the change runs in small mode, with three additions:
  - the database tests in the acceptance criteria and in § Check;
  - `/code-review medium` before the hand-off;
  - the owner applying the migration, through the steps file.

  It also says how to handle a migration not written yet. A `+` line always means small mode with a plan, even for a bug fix or a change that alters no behaviour, and § Choosing mode says so.
- **`harness/templates/small-plan.md` § Limit** allows the additive migration the risk check named.
- **`project/CONTROLS.md` § Risk paths** names the exception.

## Why

Every migration was a risk path, so a feature that only added a column ran the full process with its agents, and that cost more than the work. The risk the script can't rule out is in the code that uses the new column, which the review reads.

## How to apply

1. Replace `scripts/risk-check.sh` with the kit's version. It has no project-specific lines.
2. Add § Additive migration to `harness/MODES.md`, before § Fixing a bug, and merge the § Small mode sentence that names it.
3. Merge the § Limit sentence in `harness/templates/small-plan.md` and the § Risk paths sentence in `project/CONTROLS.md`. Keep this project's paths and area names. The exception only applies to areas whose name says database, schema, migration or sql.

## Skip if

The project has no SQL migrations: the change does nothing there, but apply it anyway so the risk check stays the kit's.
