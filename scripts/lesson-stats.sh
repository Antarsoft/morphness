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
seeds = 0
for f in files:
    m = re.match(r"^---\n(.*?)\n---\n", open(f, encoding="utf-8").read(), re.S)
    if m and re.search(r"^in_template:\s*true\s*$", m.group(1), re.M):
        seeds += 1
total = len(files)
others = total - seeds
if mode == "":
    print(f"lessons {total}, in the kit {seeds}, offered on a match {others}")
    sys.exit(0)

# every place a count appears: (file, pattern with one number group, template for the replacement text)
places = [
    ("README.md", r"badge/lessons-(\d+)-", total),
    ("README.md", r"\*\*(\d+) lessons\*\*", total),
    ("README.md", r"(\d+) ship inside the kit", seeds),
    ("README.md", r"the other (\d+) are offered", others),
    ("docs/index.html", r"<b>(\d+)</b><span>lessons in the catalog", total),
    ("docs/index.html", r"<b>(\d+)</b><span>ship inside the kit", seeds),
    ("docs/index.html", r"<b>(\d+)</b><span>offered when they match", others),
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
print(f"lesson-stats: counts match ({total} lessons, {seeds} in the kit, {others} offered on a match)")
PY
