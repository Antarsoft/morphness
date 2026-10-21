#!/usr/bin/env bash
# Build the CHANGELOG.md section for a release from changelog.d/*.md.
# Usage: scripts/release-changelog.sh --suggest            print the next version and why
#        scripts/release-changelog.sh <vX.Y.Z> [YYYY-MM-DD]   build the release (date defaults to today, UTC)
# Moves any text left under "## Unreleased" (a legacy heading; it is not re-added) plus every fragment
# into "## <vX.Y.Z> (<date>)", deletes the fragments, sets each updates/ note's `release: unreleased` to
# <vX.Y.Z> and bumps .claude-plugin/plugin.json to the plugin build number for the date
# (YYYYMMDD.N.0, N counting that day's releases). Then run scripts/check-updates.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 1 ] && [ $# -le 2 ] || { echo "usage: scripts/release-changelog.sh --suggest | <vX.Y.Z> [YYYY-MM-DD]"; exit 2; }
exec python3 -I - "$ROOT" "$@" <<'PY'
import datetime, glob, json, os, re, sys
root, arg = sys.argv[1], sys.argv[2]
path = os.path.join(root, "CHANGELOG.md")
text = open(path, encoding="utf-8").read()
SEMVER = re.compile(r"v(\d+)\.(\d+)\.(\d+)")

def triple(v):
    return tuple(int(x) for x in SEMVER.fullmatch(v).groups())

# The current version: the newest semantic heading, else the last row of the version map.
known = re.findall(r"^## (v\d+\.\d+\.\d+)\b", text, re.M) + re.findall(r"^\|[^|\n]*\|\s*(v\d+\.\d+\.\d+)\s*\|", text, re.M)
current = max(known, key=triple) if known else "v0.0.0"

def unreleased_notes():
    out = []
    for f in glob.glob(os.path.join(root, "updates", "*.md")):
        s = open(f, encoding="utf-8").read()
        if re.search(r"^release:\s*unreleased\b", s, re.M):
            k = re.search(r"^kind:\s*(\w+)", s, re.M)
            out.append((os.path.basename(f), k.group(1) if k else "?"))
    return sorted(out)

if arg == "--suggest":
    notes = unreleased_notes()
    frags = [f for f in glob.glob(os.path.join(root, "changelog.d", "*.md")) if os.path.basename(f) != "README.md"]
    if not notes and not frags: print(f"current {current}; nothing to release"); sys.exit(0)
    a, b, c = triple(current)
    minor = any(k != "fix" for _, k in notes) or (frags and not notes)
    nxt = f"v{a}.{b + 1}.0" if minor else f"v{a}.{b}.{c + 1}"
    print(f"current {current}; {len(notes)} unreleased update note(s), {len(frags)} fragment(s)")
    for n, k in notes: print(f"  {k:9} {n}")
    print(f"suggested: {nxt} ({'a note that is not a fix, or skill-only changes: minor' if minor else 'fixes only: patch'}). The maintainer decides.")
    sys.exit(0)

rel = arg
if not SEMVER.fullmatch(rel):
    print("release must be a semantic version like v0.13.0 (dated names ended with 2026-10-20.5)"); sys.exit(2)
if triple(rel) <= triple(current):
    print(f"{rel} must be above the current version {current}"); sys.exit(1)
date = sys.argv[3] if len(sys.argv) > 3 else datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")
if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", date):
    print("date must be YYYY-MM-DD"); sys.exit(2)
if re.search(rf"^## {re.escape(rel)}\b", text, re.M):
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

# Plugin build number: the date, then the release number of that day. Claude Code offers a plugin update
# only when it rises, and a 0.x version is below the dated numbers, so it stays a date-shaped number.
pj = os.path.join(root, ".claude-plugin", "plugin.json")
raw = open(pj, encoding="utf-8").read()
old = json.loads(raw)["version"]
d8 = date.replace("-", "")
mm = re.fullmatch(r"(\d{8})\.(\d+)\.0", old)
n = int(mm.group(2)) + 1 if mm and mm.group(1) == d8 else 1
build = f"{d8}.{n}.0"
if mm and (int(mm.group(1)), int(mm.group(2))) >= (int(d8), n):
    print(f"date {date} is not after the current plugin build {old}"); sys.exit(1)

section = "\n\n".join(p if p.startswith("- ") else "- " + p for p in parts)
start, end = (m.start(), m.end()) if m else (first.start(), first.start())
text = text[:start] + f"## {rel} ({date})\n\n{section}\n\n" + text[end:]
open(path, "w", encoding="utf-8").write(text)
open(pj, "w", encoding="utf-8").write(raw.replace(f'"version": "{old}"', f'"version": "{build}"', 1))
for f in frags: os.remove(f)
cnt = 0
for f in glob.glob(os.path.join(root, "updates", "*.md")):
    s = open(f, encoding="utf-8").read()
    s2 = re.sub(r"^(release:\s*)unreleased\b", rf"\g<1>{rel}", s, count=1, flags=re.M)
    if s2 != s: open(f, "w", encoding="utf-8").write(s2); cnt += 1
print(f"CHANGELOG.md: '## {rel} ({date})' built from {len(frags)} fragment(s); {cnt} update note(s) set to release {rel}")
print(f"plugin.json: version {old} -> {build}")
print("Next: run scripts/check-updates.sh")
PY
