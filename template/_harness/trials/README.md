# Trials

One file per change under trial, `<trial-slug>.md`, from [harness/templates/trial.md](../../harness/templates/trial.md). How trials start, run and get decided: [harness/MORPHING.md](../../harness/MORPHING.md) § Trials.

A feature that runs a trial names it on its learnings file's **Trial** line; that line is the result, so a retro never edits a trial file. `bash scripts/prune-counter.sh` prints `Trial <slug>: N/<length> features` for every active trial, and `--prune` adds its numbers. A decided trial keeps its file with **Status** `kept` or `reverted`.

None yet.
