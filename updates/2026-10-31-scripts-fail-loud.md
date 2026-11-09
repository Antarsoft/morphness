---
id: 2026-10-31-scripts-fail-loud
title: prune-counter, evidence and learned-rules stop with a message instead of passing silently
kind: fix
release: v0.15.0
applies_to: { modules: [] }
files:
  - scripts/prune-counter.sh
  - scripts/evidence.sh
  - scripts/learned-rules.sh
  - harness/SETUP.md
removed: []
---

## What changed

- `scripts/prune-counter.sh` exits 2 with a `Prune counter: not measured (missing: …)` line when a tool it needs (awk, git, grep, sed, sort, tr, wc and the like) is missing, instead of printing blank gauges, skipping the size budget check and exiting 0. Without python3, or when a record it reads (a learnings or trial file, `_harness/LEARNINGS.md`, or under `--prune` a rule file) isn't UTF-8, it prints the gauges and then `Prune counter: trials and rule tags not measured (…)` naming the cause, and exits 2; before, it left the trial lines out silently, or printed a traceback. When a size budget is over as well, it still exits 1: the prune proposal waits either way. A budget or threshold written with a leading zero (`rule_budget_kb: 09`) is read as decimal, a prune file whose name has spaces is found, and an unknown option exits 2 with the usage on stderr.
- `scripts/evidence.sh` and `scripts/learned-rules.sh` name the file that isn't UTF-8 instead of printing a traceback (evidence exits 3 and writes nothing; learned-rules exits 1), and reject an unknown option with exit 2 (they used to ignore it). evidence.sh exits 1 when python3 or awk is missing (it exited 0 without python3); learned-rules.sh exits 1 without git (it read the wrong folder when run from a subfolder).
- `harness/SETUP.md` § Retrospective → Hand-off message: when the prune counter prints a `not measured` line, paste it and ask the owner to fix the cause.

## Why

Without awk the prune counter printed `Rules: /36 KB`, skipped the size check and exited 0, so the gate that holds a hand-off until a prune proposal is written was gone with no sign. `rule_budget_kb: 09` failed the same way (`value too great for base`), and a prune proposal named with spaces was missed, so a second one got written.

## How to apply

1. Copy the three scripts from the kit. If you edited one, keep your edits and take the option check and tool check at the top, the `$((10#…))` lines after each budget, the glob loop over `_harness/prunes/`, the python3 check before the trials, the `not_utf8`/`UnicodeDecodeError` handling and the exit code lines at the end.
2. In `harness/SETUP.md` § Retrospective → Hand-off message, add after "asking the owner to decide its rows.": "When it prints a `not measured` line it could not measure all of it (exit 2, or exit 1 when a budget is over too): paste that line (a missing tool, a record that isn't UTF-8) and ask the owner to fix that; never count by hand."
