# Trial: <trial-slug>

**Status:** active | kept | reverted  
**Started by:** owner | retro item `<feature-slug> v<n> #N`, YYYY-MM-DD  
**Starts with:** `<feature-slug>` (the first feature that runs it)  
**Length:** 3 features  
**Applies to:** which features qualify, for example "UI-only features" or "every feature"  
**Metric:** rework rounds · QA fails · cost (pick what the change should move)  
**Pass:** for example "rework rounds and QA fails no worse than the window, cost at least 20% lower"  
**Revert:** for example "the first second QA round from an implementation cause"

Process: `harness/MORPHING.md` § Trials. The file name is the slug each learnings file names on its **Trial** line.

## Hypothesis

One or two lines: what should change, and why we think so.

## Change

The exact rule text, or the variant (agent file, model, effort) and where it applies. A rule under trial ends with `(trial: <trial-slug>)` in its owner file.

## Escape window

A trial is decided only after one prune window (`loop.prune_every` features) has finished past its last qualifying feature. The decision reads the `Escaped` lines of fix PRs traced to its features as well as the numbers below (`harness/MORPHING.md` § Trials, step 4).

## Results

One row per feature that ran it, added by the prune when it folds that feature's learnings file (`harness/SETUP.md` § Prune, step 6). Until then the learnings file is the record.

| Feature | Date | Rework rounds | QA fails | Cost |
|---------|------|---------------|----------|------|

## Decision

Filled at the prune that decides it: keep or revert, the numbers, the owner's call, and the date.
