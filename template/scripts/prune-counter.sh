#!/usr/bin/env bash
# Prints the prune counter the Technical Lead pastes at the end of every feature hand-off
# (harness/SETUP.md § Retrospective → Prune counter). The count is the feature learnings files
# (_harness/learnings/*-v*.md) on this branch plus those already on the integration branch,
# so parallel features each count the others that merged first.
# Usage: bash scripts/prune-counter.sh   (from anywhere in the repo; read-only)

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

config_value() {
  # First `<key>: value` in harness.config.yml, with the comment and quotes stripped.
  sed -n "s/^[[:space:]]*$1:[[:space:]]*\([^#]*\).*/\1/p" harness.config.yml 2>/dev/null \
    | head -n 1 | tr -d "\"' "
}

threshold="$(config_value prune_every)"
case "$threshold" in ''|*[!0-9]*) threshold=10 ;; esac
integration="$(config_value integration)"

files="$(ls _harness/learnings/*-v*.md 2>/dev/null | sed 's|.*/||')"
if [ -n "$integration" ] && git fetch -q origin "$integration" 2>/dev/null; then
  merged="$(git ls-tree --name-only "origin/$integration" _harness/learnings/ 2>/dev/null \
    | sed 's|.*/||' | grep -E -- '-v.*\.md$')"
  files="$(printf '%s\n%s\n' "$files" "$merged")"
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
