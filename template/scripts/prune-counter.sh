#!/usr/bin/env bash
# Prints the prune counter and the rule size gauge the Technical Lead pastes at the end of every
# feature hand-off (harness/SETUP.md § Retrospective → Prune counter). The count is the feature learnings files
# (_harness/learnings/*-v*.md) on the integration branch plus the ones this branch added, so parallel
# features each count the others that merged first, and files a prune folded on the integration
# branch don't come back from a branch cut before it. The gauge adds up the files Claude Code loads
# into every session (CLAUDE.md, the files it imports with `@`, and each .claude/rules/*.md without a
# `paths:` line) against loop.rule_budget_kb, and the plan checklists and project/*.md against theirs.
# Each active trial (_harness/trials/*.md) gets a line with how many of its features have run.
# Exits 1 when a size budget is over and no prune proposal is open: the hand-off waits for the
# proposal (harness/SETUP.md § Prune). Every other case exits 0.
# Usage: bash scripts/prune-counter.sh [--prune]   (from anywhere in the repo; read-only)
#   --prune  also print what a prune reads (harness/SETUP.md § Prune): one trend line for the window
#            (rework rounds, QA fails, cost), each trial's numbers, and every rule tagged
#            `(from <slug>, <date>)` with the features finished since it landed

. "$(cd "$(dirname "$0")" && pwd)/lib/config.sh" || exit 1
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

threshold="$(config_get loop.prune_every)"
case "$threshold" in ''|*[!0-9]*) threshold=10 ;; esac
integration="$(config_get branches.integration)"
# The integration branch is fetched only when asked for (PRUNE_FETCH=1), so a hand-off never waits on
# the network; otherwise the last fetched origin/<integration> is used when it exists.

files="$(ls _harness/learnings/*-v*.md 2>/dev/null | sed 's|.*/||')"
if [ -n "$integration" ] && { [ "${PRUNE_FETCH:-}" != 1 ] || git fetch -q origin "$integration" 2>/dev/null; } \
  && git rev-parse -q --verify "origin/$integration" >/dev/null 2>&1; then
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
  echo "(origin/$integration not fetched; counting this branch only. PRUNE_FETCH=1 fetches it)" >&2
  integration=""
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
# A proposal still open (proposed: the owner hasn't decided; approved: decided, cuts not applied yet):
# the hand-off names it instead of writing another. A declined one is closed by prune step 6 (fold, reset).
waiting=""
for f in $(ls _harness/prunes/*.md 2>/dev/null | grep -E '/[0-9]{4}-[0-9]{2}-[0-9]{2}[^/]*\.md$' | sort); do
  if grep -q -E '^\*\*Status:\*\*[[:space:]]*proposed[[:space:]]*$' "$f"; then waiting="$f"
  elif grep -q -E '^\*\*Status:\*\*[[:space:]]*approved[[:space:]]*$' "$f"; then waiting="$f (approved, cuts not applied yet)"
  fi
done
due=""
over=0
if [ "$bytes" -gt $((budget * 1024)) ] || [ "$cbytes" -gt $((cbudget * 1024)) ] || [ "$dbytes" -gt $((dbudget * 1024)) ]; then over=1; fi
if [ -f .claude/rules/technical-lead.md ] && [ "$(wc -c < .claude/rules/technical-lead.md)" -gt 20480 ]; then over=1; fi
if [ "$count" -ge "$threshold" ]; then
  due="Prune is DUE"
elif [ "$bytes" -gt $((budget * 1024)) ]; then
  largest="$(printf '%s\n' "$loaded" | head -n 3 | while read -r b f; do printf '%s %s KB, ' "$f" "$(kb "$b")"; done)"
  due="Prune is DUE (always-loaded rules are over loop.rule_budget_kb; largest: ${largest%, })"
elif [ "$cbytes" -gt $((cbudget * 1024)) ]; then
  due="Prune is DUE (the plan checklists are over loop.checklist_budget_kb)"
elif [ "$dbytes" -gt $((dbudget * 1024)) ]; then
  largest="$(for f in project/*.md; do [ -f "$f" ] && printf '%s %s\n' "$(wc -c < "$f" | tr -d ' ')" "$f"; done \
    | sort -rn | head -n 2 | while read -r b f; do printf '%s %s KB, ' "$f" "$(kb "$b")"; done)"
  due="Prune is DUE (the project docs are over loop.project_docs_budget_kb; largest: ${largest%, })"
elif [ -f .claude/rules/technical-lead.md ] \
  && [ "$(wc -c < .claude/rules/technical-lead.md)" -gt 20480 ]; then
  due="Prune is DUE (.claude/rules/technical-lead.md is over 20 KB)"
fi
# While a proposal is open the hand-off names it and writes no second one, so DUE is not printed.
if [ -n "$waiting" ]; then
  echo "Prune proposal waiting: $waiting${due#Prune is DUE}"
elif [ -n "$due" ]; then
  echo "$due"
fi
rc=0
if [ "$over" = 1 ] && [ -z "$waiting" ]; then
  echo "A size budget is over and no prune proposal is open: write it (harness/SETUP.md § Prune) before the hand-off." >&2
  rc=1
fi

# Trials, and with --prune the trend, trial numbers and rule tags. A file that is only on the
# integration branch is read from there.
command -v python3 >/dev/null 2>&1 || exit "$rc"
read -r -d '' program <<'PY' || true
import glob, re, sys

prune = "--prune" in sys.argv[1:]
DATE = r"\d{4}-\d{2}-\d{2}"

def read(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return ""

# Learnings files: date, rework rounds (QA rounds after the first), whether QA failed, cost, trial.
features = []
for chunk in sys.stdin.read().split("\036")[1:]:
    name, _, text = chunk.partition("\n")
    heading = re.search(r"^### .*?(" + DATE + ")", text, re.M)
    rounds = re.search(r"QA rounds:\s*(\d+)", text)
    cost = re.search(r"\*\*Cost:\*\*\s*≈\s*\$\s*([0-9][0-9,]*(?:\.[0-9]+)?)", text)
    trial = re.search(r"^- \*\*Trial:\*\*\s*`?([a-z0-9][a-z0-9-]*)", text, re.M)
    r = int(rounds.group(1)) if rounds else 1
    features.append({
        "name": name,
        "date": heading.group(1) if heading else "",
        "rework": max(r - 1, 0),
        "failed": r > 1 or "failed-escalated" in text,
        "cost": float(cost.group(1).replace(",", "")) if cost else None,
        "trial": trial.group(1) if trial else "",
    })

def summary(fs):
    if not fs:
        return "no features"
    costs = [f["cost"] for f in fs if f["cost"] is not None]
    rework = sum(f["rework"] for f in fs) / len(fs)
    return (f"rework rounds {rework:.1f} avg, QA fails {sum(f['failed'] for f in fs)}, "
            f"cost ${sum(costs):.2f} ({len(costs)} of {len(fs)} measured)")

if prune:
    print(f"Last {len(features)} features: {summary(features)}")

# Active trials: features run = rows already folded into § Results plus this window's files that
# name the trial on their Trial line.
for path in sorted(glob.glob("_harness/trials/*.md")):
    text = read(path)
    slug = path.rsplit("/", 1)[-1][:-3]
    status = re.search(r"^\*\*Status:\*\*\s*(\w+)", text, re.M)
    if slug == "README" or (status and status.group(1) != "active"):
        continue
    length = re.search(r"^\*\*Length:\*\*\s*(\d+)", text, re.M)
    length = int(length.group(1)) if length else 0
    results = text.split("## Results", 1)[-1] if "## Results" in text else ""
    folded = len([l for l in results.splitlines() if re.match(r"^\| *[^|\s-]", l)
                  and not l.lstrip("| ").startswith("Feature")])
    mine = [f for f in features if f["trial"] == slug]
    run = folded + len(mine)
    line = f"Trial {slug}: {run}/{length or '?'} features"
    if length and run >= length:
        line += ", ready to decide at the next prune"
    if prune and mine:
        line += f"; this window: {summary(mine)}"
    print(line)

if not prune:
    sys.exit(0)

# Rule tags: `(from <slug>, <date>)`, or `(from a, <date>; b, <date>)` once tightened. Spans in
# backticks are examples, not tags. Features since = finished on a later date (this window's
# files plus the dated lines a prune folded into LEARNINGS.md and its archive).
dates = [f["date"] for f in features if f["date"]]
for path in ("_harness/LEARNINGS.md", "_harness/LEARNINGS-archive.md"):
    entries = read(path).split("## Entries", 1)
    if len(entries) == 2:
        dates += re.findall(r"^- .*?(" + DATE + ")", entries[1], re.M)
paths = ["CLAUDE.md", "AGENTS.md"] + sorted(glob.glob(".claude/rules/*.md") + glob.glob(".claude/agents/*.md")
         + glob.glob("harness/**/*.md", recursive=True) + glob.glob("project/**/*.md", recursive=True))
tags = []
for path in paths:
    for n, line in enumerate(read(path).splitlines(), 1):
        line = re.sub(r"`[^`]*`", "", line)
        for group in re.findall(r"\(from ([^()]*?" + DATE + r"[^()]*)\)", line):
            pairs = re.findall(r"([a-z0-9][a-z0-9.-]*)(?: v\d+)?,\s*(" + DATE + ")", group)
            if pairs:
                slug, day = max(pairs, key=lambda p: p[1])
                tags.append((path, n, slug, day, sum(d > day for d in dates)))
young = sum(t[4] < 3 for t in tags)
print(f"Rule tags: {len(tags)} ({young} too new to judge: fewer than 3 features since)")
for path, n, slug, day, since in tags:
    print(f"  {path}:{n} from {slug}, {day}: features since: {since}" + (" (too new to judge)" if since < 3 else ""))
PY
printf '%s\n' "$files" | grep . | sort -u | while read -r f; do
  printf '\036%s\n' "$f"
  if [ -f "_harness/learnings/$f" ]; then cat "_harness/learnings/$f"
  elif [ -n "$integration" ]; then git show "origin/$integration:_harness/learnings/$f" 2>/dev/null
  fi
done | python3 -I -c "$program" "$@"
exit "$rc"
