<!-- Autonomous module: the prompt scripts/auto/run.sh gives each feature session. Words in %CAPS% are filled by the driver. -->

Autonomous run, feature `%SLUG%` (%TITLE%), milestone %MILESTONE%, on branch `%BRANCH%`. You are the Technical Lead; `MORPH_AUTO=1` is set, so `harness/modules/autonomous/README.md` § Run rules replace every owner approval and owner ask. Read that section first. Nobody is watching this session.

What to build: the `%SLUG%` row of `docs/product/order.md` and what `docs/product/` says about it. Product doc approved by %OWNER% on %APPROVED_AT%.

Features it depends on, by their cards (read these, not the whole ledger): %DEP_CARDS%

Run the harness as you would for an owner request: choose the mode, write and check the plan, approve it under the run rules, delegate, run the checks and QA, then the retro and the after-QA-pass steps on this branch. When a split is the right call, write the card with `status: split` and the parts instead of a plan. Finish by writing `_harness/auto/cards/%SLUG%.md` from `harness/templates/auto/card.md` and committing it. Don't push, open a PR, merge or switch branches.
