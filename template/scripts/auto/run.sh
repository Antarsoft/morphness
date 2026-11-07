#!/usr/bin/env bash
# The autonomous module's driver (harness/modules/autonomous/README.md). Run it from a terminal at the repo root,
# never from inside a Claude Code session: it starts one headless `claude -p` session per step.
#
# Usage: bash scripts/auto/run.sh start     check the brief and budgets, make the run branch, write the product docs
#        bash scripts/auto/run.sh approve   after you read and edit docs/product/: record your approval
#        bash scripts/auto/run.sh run       build the features one at a time until the run ends or exits
#        bash scripts/auto/run.sh resume    after an exit: fresh tries for the stopped feature, then run
#        bash scripts/auto/run.sh status    the tracker and the spend
#        bash scripts/auto/run.sh stop      exit after the current feature (from a second terminal)
# Exit: 0 done or waiting for your next step; 1 the run exited (_harness/auto/exit.md says why); 2 refused to start.
# MORPH_AUTO_CLAUDE names another claude binary (the kit self-test uses a stub).
set -u
command -v python3 >/dev/null 2>&1 || { echo "auto: python3 is needed" >&2; exit 2; }
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "auto: run this inside the repository" >&2; exit 2; }
cd "$root" || exit 2
exec python3 -I -B scripts/auto/driver.py "$@"
