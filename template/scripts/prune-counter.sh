#!/usr/bin/env bash
# Prints the prune counter and the rule size gauge the Technical Lead pastes at the end of every
# feature hand-off (harness/SETUP.md § Retrospective → Prune counter). The count is the feature learnings files
# (_harness/learnings/*-v*.md) on the integration branch plus the ones this branch added, so parallel
# features each count the others that merged first, and files a prune folded on the integration
# branch don't come back from a branch cut before it. The gauge adds up the files Claude Code loads
# into every session (CLAUDE.md, the files it imports with `@`, and each .claude/rules/*.md without a
# `paths:` line) against loop.rule_budget_kb, and the plan checklists and project/*.md against theirs.
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

# Always-loaded rule files and their size.
budget="$(config_get loop.rule_budget_kb)"
case "$budget" in ''|*[!0-9]*) budget=36 ;; esac
loaded="$(
  { [ -f CLAUDE.md ] && echo CLAUDE.md && sed -n 's/^@\([^ ]*\).*/\1/p' CLAUDE.md
    for f in .claude/rules/*.md; do
      # A rule with `paths:` in its frontmatter loads only for matching files.
      [ -f "$f" ] && ! awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit }
        NR > 1 && /^paths:/ { found = 1 } END { exit !found }' "$f" && echo "$f"
    done
  } 2>/dev/null | while read -r f; do [ -f "$f" ] && printf '%s %s\n' "$(wc -c < "$f" | tr -d ' ')" "$f"; done \
    | sort -u | sort -rn
)"
bytes="$(printf '%s\n' "$loaded" | awk '{ s += $1 } END { print s + 0 }')"
kb() { awk -v b="$1" 'BEGIN { printf "%.1f", b / 1024 }'; }

# The plan checklists, read before every full-mode approval: retros grow them fastest.
cbudget="$(config_get loop.checklist_budget_kb)"
case "$cbudget" in ''|*[!0-9]*) cbudget=36 ;; esac
cbytes="$(cat harness/PLAN_CHECKLIST.md project/PLAN_CHECKLIST.md 2>/dev/null | wc -c | tr -d ' ')"

# The project fact docs (project/*.md), read before planning: they grow as features add facts.
dbudget="$(config_get loop.project_docs_budget_kb)"
case "$dbudget" in ''|*[!0-9]*) dbudget=48 ;; esac
dbytes="$(cat project/*.md 2>/dev/null | wc -c | tr -d ' ')"

echo "Prune counter: $count/$threshold"
echo "Rules: $(kb "$bytes")/$budget KB always loaded"
echo "Checklists: $(kb "$cbytes")/$cbudget KB"
echo "Project docs: $(kb "$dbytes")/$dbudget KB"
if [ "$count" -ge "$threshold" ]; then
  echo "Prune is DUE"
elif [ "$bytes" -gt $((budget * 1024)) ]; then
  largest="$(printf '%s\n' "$loaded" | head -n 3 | while read -r b f; do printf '%s %s KB, ' "$f" "$(kb "$b")"; done)"
  echo "Prune is DUE (always-loaded rules are over loop.rule_budget_kb; largest: ${largest%, })"
elif [ "$cbytes" -gt $((cbudget * 1024)) ]; then
  echo "Prune is DUE (the plan checklists are over loop.checklist_budget_kb)"
elif [ "$dbytes" -gt $((dbudget * 1024)) ]; then
  largest="$(for f in project/*.md; do [ -f "$f" ] && printf '%s %s\n' "$(wc -c < "$f" | tr -d ' ')" "$f"; done \
    | sort -rn | head -n 2 | while read -r b f; do printf '%s %s KB, ' "$f" "$(kb "$b")"; done)"
  echo "Prune is DUE (the project docs are over loop.project_docs_budget_kb; largest: ${largest%, })"
elif [ -f .claude/rules/technical-lead.md ] \
  && [ "$(wc -c < .claude/rules/technical-lead.md)" -gt 20480 ]; then
  echo "Prune is DUE (.claude/rules/technical-lead.md is over 20 KB)"
fi
exit 0
