# <label> checklist

The working checklist for [<label>](./<id>.md). The version doc stays the source for scope and decisions; this file tracks what is left to do, above all the steps only a human can do.

**Roadmap:** id `<id>`. **Created:** YYYY-MM-DD (when the version became `next` or `planned`).

<!-- Roadmap module. Create from harness/templates/version-checklist.md together with the version doc. Features never edit this file: each writes its block to `<id>/steps/<feature-slug>.md` (format: harness/templates/steps.md), and the release and the prune fold those files in under § Human-only steps from features (harness/SETUP.md § After QA pass, step 4). -->

## Code items

Optional ordered build list (plans, sizes, dependencies). Tick and link the feature at its QA pass.

- [ ] **<item id> <title>.** Size. Needs: <items>.

## Human-only steps from features

Each feature's block is written at its QA pass, before its PR, to its own file `<id>/steps/<feature-slug>.md`; the release and the prune fold those files in here, one heading per feature, in the order they merged, keeping each item's tick. Until then, what is left for the human is this file plus every file in `steps/` next to it. Tick an item in place when it is done.

## Carried over

Unticked items from the previous version's checklist, moved here at its release (the human closed the rest). Keep the original id and link.

## Before launch

Launch-only checks no feature owns.
