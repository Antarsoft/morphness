#!/usr/bin/env bash
# Prints named sections of a Markdown file, so the Technical Lead reads the part of a harness doc a step
# needs instead of the whole file (harness/TECHNICAL_LEAD.md § Full mode, step by step). A section is its
# heading line down to the next heading of the same or a higher level, so a `##` section includes its `###`
# subsections. A name matches a heading's text, ignoring case, `#`s, a leading `§`, backticks and `*`; a name
# that is the start of one heading's text matches it too ("Choosing mode" finds "Choosing mode (Technical
# Lead)"), and "A → B" means heading B under heading A. Headings inside code fences don't count.
# With no names, prints the file's headings with the size of each section, so you can pick.
# Exits 1 when a name matches no heading or more than one: it prints the sections the other names found, then
# the problem and the headings on stderr. Exits 2 on a usage error (no file, an empty name).
# When the sections printed together are over 12000 characters, the first line says so: one tool result that big
# was cut in a benchmark run (15.6K printed in one call), and the reader had to print it again; print fewer
# sections per call.
# Usage: bash scripts/doc-section.sh <file.md> ["<heading>" ...]   (read-only)

[ $# -ge 1 ] || { echo "usage: bash scripts/doc-section.sh <file.md> [\"<heading>\" ...]" >&2; exit 2; }
[ -f "$1" ] || { echo "doc-section: no file $1" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "doc-section: python3 is missing" >&2; exit 2; }
exec python3 -I - "$@" <<'PY'
import re, sys
path, names = sys.argv[1], sys.argv[2:]
lines = open(path, encoding="utf-8-sig", errors="replace").read().split("\n")
heads, fence = [], None
for i, line in enumerate(lines):
    f = re.match(r"^\s*(`{3,}|~{3,})", line)
    if f:
        mark = f.group(1)
        if fence is None:
            fence = mark
        elif mark[0] == fence[0] and len(mark) >= len(fence):
            fence = None
        continue
    m = None if fence else re.match(r"^(#{1,6})\s+(.*?)(?:\s+#+)?\s*$", line)
    if m and m.group(2):
        heads.append((i, len(m.group(1)), m.group(2)))

def norm(s):
    s = re.sub(r"[`*]", "", s).strip()
    s = re.sub(r"^[#§\s]+", "", s)
    return re.sub(r"\s+", " ", s).strip().lower()

def span(k):
    start, level, _ = heads[k]
    end = next((h[0] for h in heads[k + 1:] if h[1] <= level), len(lines))
    return start, end

def listing(out):
    if not heads:
        print(f"doc-section: {path} has no headings", file=out)
    for k, (i, level, text) in enumerate(heads):
        s, e = span(k)
        size = sum(len(l) + 1 for l in lines[s:e])
        print(f"{'#' * level} {text}   (line {i + 1}, {size} chars)", file=out)

def find(want, within):
    pool = [k for k in within]
    exact = [k for k in pool if norm(heads[k][2]) == want]
    return exact or [k for k in pool if norm(heads[k][2]).startswith(want)]

if not names:
    listing(sys.stdout)
    sys.exit(0)
out, bad = [], []
for name in names:
    parts = [norm(p) for p in re.split(r"\s*(?:→|->)\s*", name)]
    if not all(parts):
        print(f"doc-section: empty heading name {name!r}", file=sys.stderr)
        sys.exit(2)
    within = range(len(heads))
    hits = []
    for part in parts:
        hits = find(part, within)
        if len(hits) != 1:
            break
        s, e = span(hits[0])
        within = [k for k in range(len(heads)) if s < heads[k][0] < e]
    if len(hits) != 1:
        bad.append(f"doc-section: {'no' if not hits else len(hits)} heading{'s' if len(hits) > 1 else ''} in {path} {'match' if len(hits) > 1 else 'matches'} {name!r}")
        continue
    s, e = span(hits[0])
    out.append("\n".join(lines[s:e]).rstrip())
if out:
    text = "\n\n".join(out)
    if len(text) > 12000:
        print(f"doc-section: this print is {len(text)} characters; a tool result this big can be cut, so print fewer sections per call.")
    print(text)
if bad:
    print("\n".join(bad), file=sys.stderr)
    print(f"Headings in {path}:", file=sys.stderr)
    listing(sys.stderr)
    sys.exit(1)
PY
