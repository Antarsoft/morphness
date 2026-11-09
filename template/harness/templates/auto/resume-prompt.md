<!-- Autonomous module: the prompt scripts/auto/run.sh gives a feature session started again after a crash or by /morph-auto resume. Words in %CAPS% are filled by the driver. After failed-escalated, %NEW_VERSION% says: the owner's direction from exit.md opens the feature's next version folder (harness/SETUP.md § QA iteration), and QA rounds start again there. -->

Autonomous run, feature `%SLUG%` (%TITLE%), started again on branch `%BRANCH%` from its last commit: %WHY%. Its records are in `_harness/features/%SLUG%/<version>/` (this exact slug). You are the Technical Lead; `MORPH_AUTO=1` is set, so `harness/modules/autonomous/README.md` § Run rules apply (Full-stack rework now runs on `auto.last_try_model`). Read that section first.

Pick up from the files, not from memory: `git log --oneline %RUN_BRANCH%..HEAD`, then the feature folder (`plan.md` **Status**, `progress.md`, the last `qa-result.md`). Carry on from the first step not done; don't redo work the records show as finished. QA rounds already used on this version: %QA_ROUNDS% of `loop.qa_max_rounds`. %NEW_VERSION%

What to build: %WHAT%

Features it depends on, by their cards: %DEP_CARDS%

%OWNER_ANSWERS%

%NOTES%

Shell commands get no prompt in this session: one outside the allow rules in `.claude/settings.json` is denied at once. So run one command per Bash call (no chains, loops or commands built from a variable), the named checks with `bash scripts/checks.sh run <check> ...`, project scripts by their relative path from the repo root (`bash scripts/<name>.sh`, never an absolute path), and use the Read, Grep, Glob, Edit and Write tools for files instead of `cat`, here-documents or `sed`. A denied chain doesn’t mean its commands are denied: try them one at a time before making any an owner item (run rule 5).

Finish as the run rules say: write `_harness/auto/cards/%SLUG%.md` and commit it. Don't push, open a PR, merge or switch branches.
