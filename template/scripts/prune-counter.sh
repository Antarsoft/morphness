#!/usr/bin/env bash
# Prints the prune counter the Technical Lead pastes at the end of every feature hand-off
# (harness/SETUP.md § Retrospective → Prune counter). The count is the feature learnings files
# (_harness/learnings/*-v*.md) on the integration branch plus the ones this branch added, so parallel
# features each count the others that merged first, and files a prune folded on the integration
# branch don't come back from a branch cut before it.
# Usage: bash scripts/prune-counter.sh   (from anywhere in the repo; read-only)

. "$(cd "$(dirname "$0")" && pwd)/lib/config.sh" || exit 1
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

threshold="$(config_get loop.prune_every)"
case "$threshold" in ''|*[!0-9]*) threshold=10 ;; esac
integration="$(config_get branches.integration)"

files="$(ls _harness/learnings/*-v*.md 2>/dev/null | sed 's|.*/||')"
if [ -n "$integration" ] && git fetch -q origin "$integration" 2>/dev/null; then
  learnings_at() {
    git ls-tree --name-only "$1" _harness/learnings/ 2>/dev/null | sed 's|.*/||' | grep -E -- '-v.*\.md$'
  }
  # A file that was already there where this branch left the integration branch belongs to the
  # integration branch: it counts only while it is still there (a prune deletes the files it folds).
  base="$(git merge-base HEAD "origin/$integration" 2>/dev/null)"
  if [ -n "$base" ]; then
    files="$(printf '%s\n' "$files" | grep -vxF -f <(learnings_at "$base"; echo /))"
  fi
  files="$(printf '%s\n%s\n' "$files" "$(learnings_at "origin/$integration")")"
else
  echo "(integration branch not fetched; counting this branch only)" >&2
fi
count="$(printf '%s\n' "$files" | grep . | sort -u | wc -l | tr -d ' ')"

echo "Prune counter: $count/$threshold"
if [ "$count" -ge "$threshold" ]; then
  echo "Prune is DUE"
elif [ -f .claude/rules/technical-lead.md ] \
  && [ "$(wc -c < .claude/rules/technical-lead.md)" -gt 20480 ]; then
  echo "Prune is DUE (.claude/rules/technical-lead.md is over 20 KB)"
fi
exit 0
