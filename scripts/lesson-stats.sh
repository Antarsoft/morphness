#!/usr/bin/env bash
# The lesson counts shown on the README and the site, computed from lessons/.
# Usage: scripts/lesson-stats.sh [--check | --write]   (no flag: print the counts)
#   --check  fail when a count in README.md or docs/index.html differs from the catalog
#   --write  rewrite those counts to match
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -I - "$ROOT" "${1:-}" <<'PY'
import glob, os, re, sys
root, mode = sys.argv[1], sys.argv[2]
files = [f for f in glob.glob(os.path.join(root, "lessons", "**", "*.md"), recursive=True)
         if os.path.basename(f) != "README.md"]
def fired_count(front):
    """The evidence's `fired` number, in the one-line `evidence: { fired: N, ... }` form or as an indented
    `fired: N` under `evidence:`; None when it is missing, `unknown` or not a number."""
    ev = re.search(r"^evidence:[ \t]*(.*(?:\n[ \t]+.*)*)", front, re.M)
    m = re.search(r"\bfired:\s*[\"']?(\w+)", ev.group(1)) if ev else None
    return int(m.group(1)) if m and m.group(1).isdigit() else None

seeds = unfired = 0
folders = {"practice": 0, "stack": 0, "service": 0}
for f in files:
    m = re.match(r"^---\n(.*?)\n---\n", open(f, encoding="utf-8").read(), re.S)
    if m and re.search(r"^in_template:\s*true\s*$", m.group(1), re.M):
        seeds += 1
    if m and not fired_count(m.group(1)):
        unfired += 1    # no numeric fired count: its source didn't count how often the rule fired
    top = os.path.relpath(f, os.path.join(root, "lessons")).split(os.sep)[0]
    if top in folders:
        folders[top] += 1
total = len(files)
others = total - seeds
if sum(folders.values()) != total:
    print(f"lesson-stats: {total - sum(folders.values())} lessons are outside practice/, stack/ and service/; "
          "add their folder to this script and to the README table", file=sys.stderr)
    sys.exit(1)
if mode == "":
    print(f"lessons {total}, in the kit {seeds}, offered on a match {others}, no fired count {unfired}, "
          + ", ".join(f"{k} {v}" for k, v in folders.items()))
    sys.exit(0)

# every place a count appears: (file, pattern with one number group, template for the replacement text)
places = [
    ("README.md", r"badge/lessons-(\d+)-", total),
    ("README.md", r"\*\*(\d+) lessons\*\*", total),
    ("README.md", r"(\d+) ship inside the kit", seeds),
    ("README.md", r"the other (\d+) are offered", others),
    ("README.md", r"(\d+) of them have\s+no `fired` count", unfired),
    ("README.md", r"\[`practice/`\]\(lessons/practice\) \| (\d+) \|", folders["practice"]),
    ("README.md", r"\[`stack/`\]\(lessons/stack\) \| (\d+) \|", folders["stack"]),
    ("README.md", r"\[`service/`\]\(lessons/service\) \| (\d+) \|", folders["service"]),
    ("docs/index.html", r"<b>(\d+)</b><span>lessons in the catalog", total),
    ("docs/index.html", r"<b>(\d+)</b><span>ship inside the kit", seeds),
    ("docs/index.html", r"<b>(\d+)</b><span>offered when they match", others),
    ("docs/index.html", r"<b>(\d+)</b><span>have no <code>fired</code> count yet", unfired),
]
bad = []
for rel, pat, want in places:
    path = os.path.join(root, rel)
    text = open(path, encoding="utf-8").read()
    ms = list(re.finditer(pat, text))
    if len(ms) != 1:
        bad.append(f"{rel}: expected one match for /{pat}/, found {len(ms)}"); continue
    have = int(ms[0].group(1))
    if have == want:
        continue
    if mode == "--write":
        text = text[:ms[0].start(1)] + str(want) + text[ms[0].end(1):]
        open(path, "w", encoding="utf-8").write(text)
        print(f"{rel}: {have} -> {want}")
    else:
        bad.append(f"{rel}: shows {have}, the catalog has {want} (/{pat}/)")
for b in bad:
    print("lesson-stats: " + b, file=sys.stderr)
if bad:
    print("run scripts/lesson-stats.sh --write to fix the counts", file=sys.stderr)
    sys.exit(1)
print(f"lesson-stats: counts match ({total} lessons, {seeds} in the kit, {others} offered on a match, {unfired} with no fired count)")
PY
