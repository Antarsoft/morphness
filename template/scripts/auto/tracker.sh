#!/usr/bin/env bash
# Redraws _harness/auto/tracker.md (a table and a Mermaid flowchart coloured by status) from the run state.
# The driver does this after every feature; run it by hand only to redraw it. Usage: bash scripts/auto/tracker.sh
set -u
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "auto: run this inside the repository" >&2; exit 2; }
cd "$root" || exit 2
exec python3 -I scripts/auto/driver.py tracker
