#!/usr/bin/env bash
# Checks one feature card (harness/templates/auto/card.md) the way the driver does and prints its header as JSON.
# Usage: bash scripts/auto/card.sh _harness/auto/cards/<slug>.md
# Exit: 0 a valid card; 2 not valid (the problems go to stderr) or a usage error.
set -u
[ $# -eq 1 ] || { echo "usage: bash scripts/auto/card.sh <card file>" >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd) || exit 2
exec python3 -I "$here/driver.py" card "$1"
