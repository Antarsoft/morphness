#!/usr/bin/env bash
# Build the dated CHANGELOG.md section for a release from changelog.d/*.md.
# Usage: scripts/release-changelog.sh <release>     (YYYY-MM-DD, or YYYY-MM-DD.N for N >= 2)
# Moves any text left under "## Unreleased" (a legacy heading; it is not re-added) plus every fragment
# into "## <release>", deletes the fragments, and sets each updates/ note's `release: unreleased` to <release>. It does not touch
# .claude-plugin/plugin.json: bump `version` by hand, then run scripts/check-updates.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 1 ] || { echo "usage: scripts/release-changelog.sh <release>"; exit 2; }
exec python3 -I - "$ROOT" "$1" <<'PY'
import glob, os, re, sys
root, rel = sys.argv[1:3]
if not re.fullmatch(r"\d{4}-\d{2}-\d{2}(\.([2-9]|[1-9]\d+))?", rel):
    print("release must be YYYY-MM-DD or YYYY-MM-DD.N (N >= 2)"); sys.exit(2)
path = os.path.join(root, "CHANGELOG.md")
text = open(path, encoding="utf-8").read()
if re.search(rf"^## {re.escape(rel)}\s*$", text, re.M):
    print(f"CHANGELOG.md already has '## {rel}'"); sys.exit(1)
m = re.search(r"^## Unreleased[ \t]*\n(.*?)(?=^## )", text, re.M | re.S)
first = re.search(r"^## ", text, re.M)
if not m and not first: print("CHANGELOG.md has no release heading to insert above"); sys.exit(1)
parts = [m.group(1).strip()] if m and m.group(1).strip() else []
frags = sorted(f for f in glob.glob(os.path.join(root, "changelog.d", "*.md")) if os.path.basename(f) != "README.md")
for f in frags:
    t = open(f, encoding="utf-8").read().strip()
    if t: parts.append(t)
if not parts: print("nothing to release: no fragments and Unreleased is empty"); sys.exit(1)
section = "\n\n".join(p if p.startswith("- ") else "- " + p for p in parts)
start, end = (m.start(), m.end()) if m else (first.start(), first.start())
text = text[:start] + f"## {rel}\n\n{section}\n\n" + text[end:]
open(path, "w", encoding="utf-8").write(text)
for f in frags: os.remove(f)
n = 0
for f in glob.glob(os.path.join(root, "updates", "*.md")):
    s = open(f, encoding="utf-8").read()
    s2 = re.sub(r"^(release:\s*)unreleased\b", rf"\g<1>{rel}", s, count=1, flags=re.M)
    if s2 != s: open(f, "w", encoding="utf-8").write(s2); n += 1
print(f"CHANGELOG.md: '## {rel}' built from {len(frags)} fragment(s); {n} update note(s) set to release {rel}")
print("Next: bump .claude-plugin/plugin.json version, then run scripts/check-updates.sh")
PY
