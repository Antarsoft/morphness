---
id: 2026-11-07-contained-change
title: "A trial switch for a finer risk check: an ordering or paging edit to a risk-path file runs in small mode"
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness.config.yml
  - scripts/risk-check.sh
  - harness/MODES.md
  - harness/SETUP.md
  - harness/templates/small-plan.md
  - project/CONTROLS.md
  - AGENTS.md
removed: []
reviewed: "It adds three config keys under mode:. The default, risk_by: file, keeps the risk check as it was. With change, risk-check.sh reads the branch's diff (read-only) and can print Mode: plain for a risk-path file. A branch that turns the trial on or widens it is printed as a risk-path reason. No guard rule or settings value changes."
---

## What changed

- **`harness.config.yml`**, under `mode:`:
  - `risk_by: file` (default, unchanged behaviour) or `change` (a trial).
  - `contained_max_lines: 10`, the most lines a contained change makes in a file.
  - `risk_terms: []`, the project's own words that make a change not contained (one line, for example `[org_id]`).
- **`scripts/risk-check.sh`** with `risk_by: change`: a file on a risk path that isn't a `.sql` file prints `~ <file>: ordering or paging only (…)` and counts as plain when all of these hold:
  - Every changed line (added or removed) is one ordering or paging call (`order`, `orderBy`, `order_by`, `sort`, `sortBy`, `thenBy`, `range`, `limit`, `offset`, `take`, `skip`, `reverse`, `asc`, `desc`, nulls first or last), a blank line or a whole-line comment. Arguments are literals, names or a comparator; no other call and no `${…}`. This is an allow-list.
  - The file is on the integration branch and still there, and at most `contained_max_lines` lines change in it.
  - No risk area it matches is about sign-in, secrets, money or the database (read from the area names).
  - No line of the functions the change is in (`git diff -W`, with git's language drivers; unchanged comments skipped) has a word from the script's risk list, a secret-shaped literal or a `risk_terms` entry.

  A `Needs:` line asks for one code review before the hand-off. A risk-path file named but not changed yet is full, with a note naming the trial; a new file stays full. Anything else on a risk path, or `--force full`, makes it a risk path again. While the trial is on, a branch that changes any of the three keys, `scripts/lib/config.sh`, `.gitattributes` or `project/CONTROLS.md` § Risk paths gets a reason of its own. A `risk_by` other than `file` or `change`, or a `risk_terms` that isn't on one line, fails toward full (exit 2).
- **`harness/MODES.md`**: new § Contained change (a trial), lines in § Choosing mode steps 2 and 3, § Small mode, and § Fixing a bug. **`harness/SETUP.md`**: the small-mode table row. **`harness/templates/small-plan.md`**: § Why small and § Limit. **`project/CONTROLS.md`** § Risk paths and **`AGENTS.md`** (a `~` line is never light mode): one sentence each.

## Why

In a private benchmark a one-line tie-breaker in a risk-path notes module ran in bug mode with four agents, at about nine times a plain run, while the same fix in small mode cost about twice and passed the same hidden checks. The path-level check can't tell that change from one to the access rules in the same file. A wider version that looked for risky words near any change failed two reviews: each found many ways to remove an ownership filter or an access check that it called contained. So the trial only admits the shape the benchmark needed, ordering and paging calls, and stays behind a switch.

## How to apply

1. Add the three keys under `mode:` in `harness.config.yml`, with the kit's comments (the owner approves the edit).
2. Copy `scripts/risk-check.sh` from the kit. A change to it prints `Mode: full` on its own branch, as before.
3. Take the kit's `harness/MODES.md` § Contained change, the `mode.risk_by: change` sentences in § Choosing mode steps 2 and 3, § Small mode and § Fixing a bug, the `harness/SETUP.md` small-mode row, the `harness/templates/small-plan.md` § Why small and § Limit wording, the sentence at the end of `project/CONTROLS.md` § Risk paths' intro, and the `AGENTS.md` mode line.
4. To try it, set `risk_by: change` in a change of its own, and add any ownership or tenant column the built-in list doesn't cover to `risk_terms`.

## Skip if

Your risk paths are already narrow enough that small fixes rarely touch them.
