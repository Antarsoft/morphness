#!/usr/bin/env bash
# Prints an anonymous evidence summary of how the harness has worked in this project: counts and
# rates read from the run records (_harness/learnings/, LEARNINGS.md and its archive, prunes/,
# trials/), nothing else. No feature names, retro text, paths or people leave the records; the
# summary is built from a fixed list of fields, so a new free-text field can't leak into it.
# Read-only and offline: it sends nothing anywhere. /morph-share shows it to the owner before any
# of it is shared (harness/MORPHING.md § Sharing evidence).
#
# Usage: bash scripts/evidence.sh [--json] [--out]
#   (no option)  the summary as Markdown on stdout
#   --json       the same figures as JSON
#   --out        also write _harness/evidence/<today>.md and .json

. "$(cd "$(dirname "$0")" && pwd)/lib/config.sh" || exit 0
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

if ! command -v python3 >/dev/null 2>&1; then
  echo "Evidence: not measured (python3 not found)"
  exit 0
fi
export EVIDENCE_RELEASE="$(config_get installed_from.release)"
export EVIDENCE_PRUNE_EVERY="$(config_get loop.prune_every)"

python3 -I - "$@" <<'PY'
import glob, json, os, re, statistics, sys
from datetime import date

DATE = r"\d{4}-\d{2}-\d{2}"
args = sys.argv[1:]
MIN_WINDOW = 10

def read(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return ""

def num(s):
    return float(s.replace(",", ""))

# Features: the learnings files not yet folded, then the one-line entries a prune folded.
feats, seen = [], set()
for path in sorted(glob.glob("_harness/learnings/*-v*.md")):
    text = read(path)
    head = re.search(r"^### (\S+)(?: v\d+)?.*?(" + DATE + ")", text, re.M)
    rounds = re.search(r"QA rounds:\s*(\d+)", text)
    cost = re.search(r"\*\*Cost:\*\*\s*≈\s*\$\s*([0-9][0-9,]*(?:\.[0-9]+)?)", text)
    verdict = re.search(r"\*\*Verdict:\*\*\s*([a-z-]+)", text)
    mode = "small" if "none (small mode)" in text else "bug" if "none (bug mode)" in text else "full"
    causes = {}
    m = re.search(r"\*\*Failure causes:\*\*\s*(.*)", text)
    for label, n in re.findall(r"(plan gap|implementation|environment|process)\s*×\s*(\d+)", m.group(1) if m else ""):
        causes[label] = causes.get(label, 0) + int(n)
    key = (head.group(1), head.group(2)) if head else (path, "")
    seen.add(key)
    feats.append({"date": head.group(2) if head else "", "pass": bool(verdict) and verdict.group(1) == "pass",
                  "rounds": int(rounds.group(1)) if rounds else 1, "cost": num(cost.group(1)) if cost else None,
                  "mode": mode, "causes": causes,
                  "escaped": len(re.findall(r"^- \*\*Escaped:\*\*", text, re.M)), "folded": False})
for path in ("_harness/LEARNINGS.md", "_harness/LEARNINGS-archive.md"):
    text = read(path)
    text = text.split("## Entries", 1)[1] if "## Entries" in text else text
    for slug, day, rest in re.findall(r"^- (\S+)(?: v\d+)?, (" + DATE + r"): (.*)$", text, re.M):
        if (slug, day) in seen:
            continue
        seen.add((slug, day))
        rounds = re.search(r"QA rounds\s*(\d+)", rest)
        cost = re.search(r"≈\s*\$\s*([0-9][0-9,]*(?:\.[0-9]+)?)", rest)
        feats.append({"date": day, "pass": rest.lstrip().startswith("pass"),
                      "rounds": int(rounds.group(1)) if rounds else 1,
                      "cost": num(cost.group(1)) if cost else None, "mode": "", "causes": {}, "escaped": 0, "folded": True})
feats.sort(key=lambda f: f["date"])

# Windows: a prune's date closes the window of the features finished on or before it.
prunes = []
for path in sorted(glob.glob("_harness/prunes/*.md")):
    name = os.path.basename(path)[:-3]
    status = re.search(r"^\*\*Status:\*\*\s*(\w+)", read(path), re.M)
    if re.fullmatch(DATE, name) and status and status.group(1) in ("approved", "applied"):
        prunes.append((name, read(path)))
edges = [d for d, _ in prunes]

def window(f):
    for i, e in enumerate(edges):
        if f["date"] <= e:
            return i
    return len(edges)

def stats(fs):
    costs = [f["cost"] for f in fs if f["cost"] is not None]
    return {"features": len(fs),
            "first_time_pass": round(sum(f["pass"] and f["rounds"] == 1 for f in fs) / len(fs), 2) if fs else None,
            "avg_qa_rounds": round(sum(f["rounds"] for f in fs) / len(fs), 2) if fs else None,
            "avg_cost_usd": round(sum(costs) / len(costs), 2) if costs else None, "cost_measured": len(costs),
            "enough_data": len(fs) >= MIN_WINDOW}

windows = []
for i in range(len(edges) + 1):
    fs = [f for f in feats if window(f) == i]
    if fs:
        windows.append(dict(stats(fs), window=i + 1, ends=edges[i] if i < len(edges) else "open"))

# Rule audits and decisions from the prune records.
def section(text, start, end):
    m = re.search(r"^## " + re.escape(start) + r".*?\n(.*?)(?=^## " + re.escape(end) + r"|\Z)", text, re.M | re.S)
    return m.group(1) if m else ""

def rows(block):
    for line in block.splitlines():
        if line.startswith("|") and not re.match(r"^\|[\s|:-]+$", line):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if cells and cells[0] not in ("Rule / item (file)", "Row", "Trial", "Item"):
                yield cells

audit = {"fired": 0, "insurance": 0, "never fired": 0, "too new": 0}
decisions = {}
for _, text in prunes:
    for cells in rows(section(text, "2. Rule audit", "3.")):
        if len(cells) >= 3 and " · " not in cells[2]:
            for k in audit:
                if cells[2].lower().startswith(k):
                    audit[k] += 1
    for cells in rows(section(text, "4. Decision", "5.")):
        if len(cells) >= 2 and cells[1]:
            word = re.split(r"[\s,:;]+", cells[1].lower())[0]
            if word in ("keep", "merge", "shorten", "move", "remove", "revert", "carry", "apply", "decline", "later"):
                decisions[word] = decisions.get(word, 0) + 1

# Retro action items: folded tables plus unfolded learnings files.
items = {"applied": 0, "skipped": 0, "open": 0, "deferred": 0}
text = read("_harness/LEARNINGS.md")
for name, key in (("Applied", "applied"), ("Skipped", "skipped"), ("Open", "open")):
    m = re.search(r"^### " + name + r"\n(.*?)(?=^### |^## |\Z)", text, re.M | re.S)
    for cells in rows(m.group(1) if m else ""):
        if cells[0] != "From retro" and "<" not in cells[0]:
            items[key] += 1
for path in glob.glob("_harness/learnings/*-v*.md"):
    for cells in rows(section(read(path), "Action items", "\x00")):
        if len(cells) >= 7 and "<" not in cells[0] and cells[0] != "From retro":
            st = cells[5].lower().split()[0] if cells[5] else ""
            if st in items:
                items[st] += 1

# Trials and adopted lessons.
trials = {}
for path in glob.glob("_harness/trials/*.md"):
    if os.path.basename(path) == "README.md":
        continue
    st = re.search(r"^\*\*Status:\*\*\s*(\w+)", read(path), re.M)
    trials[st.group(1) if st else "unknown"] = trials.get(st.group(1) if st else "unknown", 0) + 1
adopted = 0
for path in ["CLAUDE.md", "AGENTS.md"] + glob.glob(".claude/rules/*.md") + glob.glob("harness/**/*.md", recursive=True) + glob.glob("project/**/*.md", recursive=True):
    for line in read(path).splitlines():
        adopted += len(re.findall(r"\(lesson: [a-z0-9-]+\)", re.sub(r"`[^`]*`", "", line)))

allstats = stats(feats)
escaped = sum(f["escaped"] for f in feats)
unfolded = [f for f in feats if not f["folded"]]
causes = {}
for f in unfolded:
    for k, n in f["causes"].items():
        causes[k] = causes.get(k, 0) + n
modes = {}
for f in unfolded:
    modes[f["mode"]] = modes.get(f["mode"], 0) + 1
costs = [f["cost"] for f in feats if f["cost"] is not None]
data = {
    "generated": date.today().isoformat(),
    "morphness_release": os.environ.get("EVIDENCE_RELEASE", ""),
    "first_feature": feats[0]["date"] if feats else "", "last_feature": feats[-1]["date"] if feats else "",
    "overall": dict(allstats, median_cost_usd=round(statistics.median(costs), 2) if costs else None),
    "windows": windows, "escapes_recorded": escaped,
    "failure_causes_unfolded": causes, "modes_unfolded": modes,
    "retro_items": items, "prunes": len(prunes), "rule_audit": audit, "prune_decisions": decisions,
    "trials": trials, "lessons_adopted": adopted,
}

def pct(x):
    return "n/a" if x is None else f"{round(x * 100)}%"

def usd(x):
    return "n/a" if x is None else f"${x:.2f}"

o = data["overall"]
md = ["# Morphness evidence summary", "",
      f"Generated {data['generated']} from the project's own run records. Counts and rates only: no feature names, "
      "retro text, paths or people.", "",
      f"- **Span:** {data['first_feature'] or 'n/a'} to {data['last_feature'] or 'n/a'}, {o['features']} features finished"
      + (f", Morphness release {data['morphness_release']}" if data["morphness_release"] and "{{" not in data["morphness_release"] else ""),
      f"- **Quality:** {pct(o['first_time_pass'])} passed QA first time; {o['avg_qa_rounds'] if o['avg_qa_rounds'] is not None else 'n/a'} QA rounds per feature on average",
      f"- **Escapes:** {escaped} bugs recorded as found after QA passed (counted from `Escaped` lines in learnings files not yet folded by a prune)",
      f"- **Cost:** average {usd(o['avg_cost_usd'])}, median {usd(o['median_cost_usd'])} per feature over {o['cost_measured']} measured; estimates at API list prices",
      f"- **Retro items:** {items['applied']} applied, {items['skipped']} skipped, {items['open'] + items['deferred']} open or deferred",
      f"- **Prunes:** {len(prunes)}; rule audit rows: {audit['fired']} fired, {audit['insurance']} insurance, {audit['never fired']} never fired, {audit['too new']} too new; "
      "decisions: " + (", ".join(f"{n} {w}" for w, n in sorted(decisions.items())) or "none yet"),
      f"- **Trials:** " + (", ".join(f"{n} {s}" for s, n in sorted(trials.items())) or "none"),
      f"- **Lessons adopted from the catalog:** {adopted}", ""]
if causes:
    md += ["Failure causes, features not yet folded: " + ", ".join(f"{k} {n}" for k, n in sorted(causes.items())), ""]
if windows:
    md += ["## By prune window", "", "| Window | Ends | Features | QA first time | Avg QA rounds | Avg cost |", "|---|---|---|---|---|---|"]
    for w in windows:
        few = "" if w["enough_data"] else f" (fewer than {MIN_WINDOW}: too few to read a trend)"
        md.append(f"| {w['window']} | {w['ends']} | {w['features']}{few} | {pct(w['first_time_pass'])} | {w['avg_qa_rounds']} | {usd(w['avg_cost_usd'])} |")
    md.append("")
md += ["## Read with care", "",
       "- Every figure is recorded by the project's own agents and has not been audited.",
       "- Escapes are under-counted: a bug found by a fix PR only counts once someone records its `Escaped` line.",
       "- Windows that mix different models, effort levels or feature sizes are not like for like.",
       "- Cost is an estimate at public API prices, not a bill.",
       "- Without a control, these figures show what the process produced, not what it saved."]
text = "\n".join(md) + "\n"

if "--json" in args and "--out" not in args:
    print(json.dumps(data, indent=2))
else:
    sys.stdout.write(text)
if "--out" in args:
    os.makedirs("_harness/evidence", exist_ok=True)
    base = f"_harness/evidence/{data['generated']}"
    open(base + ".md", "w", encoding="utf-8").write(text)
    open(base + ".json", "w", encoding="utf-8").write(json.dumps(data, indent=2) + "\n")
    print(f"Wrote {base}.md and {base}.json", file=sys.stderr)
PY
