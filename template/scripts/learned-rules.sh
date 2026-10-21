#!/usr/bin/env bash
# Lists what this copy has learned: every rule that carries provenance, with the finding it came from,
# the day it landed and the last day a feature's learnings entry said it fired. Read-only.
# Provenance is the tag a retro adds at the end of a rule (harness/MORPHING.md § Rule provenance):
# `(from <slug>, <date>)`, `(lesson: <id>)` or `(trial: <slug>)`. Last fired is the latest entry in
# _harness/learnings/*.md, _harness/LEARNINGS.md or its archive with a `Fired:` line naming one of
# the rule's source slugs; blank when none does. Rules without a tag are counted per file, and
# listed with blank columns under --all (list bullets in CLAUDE.md, AGENTS.md, .claude/rules and project/;
# the kit's own harness/ text is not counted, it is tagged only once a retro changes it).
# Usage: bash scripts/learned-rules.sh [--all]   (from anywhere in the repo)

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1
command -v python3 >/dev/null 2>&1 || { echo "learned-rules.sh needs python3" >&2; exit 1; }
read -r -d '' program <<'PY' || true
import glob, re, sys

show_all = "--all" in sys.argv[1:]
DATE = r"\d{4}-\d{2}-\d{2}"

def read(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return ""

# Fired lines: slug -> latest day. A learnings file carries the day in its heading; a folded entry
# in LEARNINGS.md carries it on its own line.
fired = {}
def note(slugs, day):
    for s in re.findall(r"[a-z0-9][a-z0-9.-]*", slugs):
        if day and day > fired.get(s, ""):
            fired[s] = day
for path in sorted(glob.glob("_harness/learnings/*-v*.md")):
    text = read(path)
    heading = re.search(r"^### .*?(" + DATE + ")", text, re.M)
    for m in re.finditer(r"^- \*\*Fired:\*\*\s*(.+)$", text, re.M):
        note(re.sub(r"`", "", m.group(1)), heading.group(1) if heading else "")
for path in ("_harness/LEARNINGS.md", "_harness/LEARNINGS-archive.md"):
    entries = read(path).split("## Entries", 1)
    for line in entries[1].splitlines() if len(entries) == 2 else []:
        day = re.search(DATE, line)
        m = re.search(r"\bFired:\s*([^;.|]+)", line)
        if day and m:
            note(re.sub(r"`", "", m.group(1)), day.group(0))

paths = ["CLAUDE.md", "AGENTS.md"] + sorted(glob.glob(".claude/rules/*.md") + glob.glob(".claude/agents/*.md")
         + glob.glob("harness/**/*.md", recursive=True) + glob.glob("project/**/*.md", recursive=True))
own = {"CLAUDE.md", "AGENTS.md"} | set(glob.glob(".claude/rules/*.md")) | set(glob.glob("project/**/*.md", recursive=True))
bullet = r"^\s*(?:[-*]|\d+\.)\s+(?=\S)"
tagged, untagged = [], {}
for path in paths:
    in_code = False
    for n, raw in enumerate(read(path).splitlines(), 1):
        if raw.lstrip().startswith("```"):
            in_code = not in_code
        if in_code:
            continue
        line = re.sub(r"`[^`]*`", "", raw)
        src, day, extra = [], "", ""
        for group in re.findall(r"\(from ([^()]*?" + DATE + r"[^()]*)\)", line):
            pairs = re.findall(r"([a-z0-9][a-z0-9.-]*)(?: v\d+)?,\s*(" + DATE + ")", group)
            src += [p[0] for p in pairs]
            if pairs:
                day = max([day] + [p[1] for p in pairs])
        for kind, ref in re.findall(r"\((lesson|trial): ([a-z0-9][a-z0-9._/-]*)\)", line):
            extra = f"{kind}: {ref}"
            src.append(ref)
        if src:
            text = re.sub(bullet, "", re.sub(r"\s*\((?:from|lesson|trial)[^()]*\)", "", raw)).strip()
            last = max((fired.get(s, "") for s in src), default="")
            tagged.append((path, n, ", ".join(dict.fromkeys(src)) + (f" [{extra}]" if extra and not day else ""), day, last, text))
        elif path in own and re.match(bullet, raw) and not re.match(r"^\s*(?:[-*]|\d+\.)\s+\[", raw) and len(raw.split()) > 6:
            untagged.setdefault(path, []).append((n, re.sub(bullet, "", raw).strip()))

def clip(s, w=70):
    return s if len(s) <= w else s[:w - 1].rstrip() + "…"

print(f"Learned rules: {len(tagged)} with provenance, {sum(len(v) for v in untagged.values())} list items without ({sum(1 for t in tagged if not t[4])} tagged rules never recorded as fired)")
if tagged:
    print("")
    print("file:line | source finding | landed | last fired | rule")
    for path, n, src, day, last, text in tagged:
        print(f"{path}:{n} | {src} | {day} | {last} | {clip(text)}")
if untagged:
    print("")
    if show_all:
        print("Without provenance (source, landed and last fired blank):")
        for path, items in untagged.items():
            for n, text in items:
                print(f"{path}:{n} | | | | {clip(text)}")
    else:
        print("Without provenance, per file (--all lists them):")
        for path, items in untagged.items():
            print(f"  {path}: {len(items)}")
PY
python3 -I -c "$program" "$@"
