<!-- Autonomous module: the prompt scripts/auto/run.sh gives a feature session started again after a crash or by /morph-auto resume. Words in %CAPS% are filled by the driver. -->

Autonomous run, feature `%SLUG%` (%TITLE%), started again on branch `%BRANCH%` from its last commit: %WHY%. You are the Technical Lead; `MORPH_AUTO=1` is set, so `harness/modules/autonomous/README.md` § Run rules apply (Full-stack rework now runs on `auto.last_try_model`). Read that section first.

Pick up from the files, not from memory: `git log --oneline %RUN_BRANCH%..HEAD`, then the feature folder (`plan.md` **Status**, `progress.md`, the last `qa-result.md`). Carry on from the first step not done; don't redo work the records show as finished. QA rounds already used: %QA_ROUNDS% of `loop.qa_max_rounds`.

Features it depends on, by their cards: %DEP_CARDS%

Finish as the run rules say: write `_harness/auto/cards/%SLUG%.md` and commit it. Don't push, open a PR, merge or switch branches.
