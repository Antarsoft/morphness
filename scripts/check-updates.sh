#!/usr/bin/env bash
# Validate Morphness kit update notes (updates/*.md) and release metadata.
# Usage: scripts/check-updates.sh [--since <git-ref>]
#   --since: also fail when a template/ file changed since <git-ref> isn't listed in a note that was
#            added or changed since then (run in PRs with --since origin/main).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -I - "$ROOT" "$@" <<'PY'
import glob, json, os, re, subprocess, sys
root, args = sys.argv[1], sys.argv[2:]
since = None
if args:
    if args[0] != "--since" or len(args) != 2:
        print("usage: scripts/check-updates.sh [--since <git-ref>]"); sys.exit(2)
    since = args[1]
kinds = {"module", "rule", "template", "config", "fix"}
errors, notes = [], {}

def parse(text):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m: return None, None
    fm, key = {}, None
    for line in m.group(1).splitlines():
        if re.match(r"^\s*#", line) or not line.strip(): continue
        item = re.match(r"^\s+-\s+(.*?)\s*(#.*)?$", line)
        if item and key is not None:
            if not isinstance(fm[key], list): fm[key] = []
            fm[key].append(item.group(1).strip('"')); continue
        kv = re.match(r"^([a-z_]+):\s*(.*?)\s*(#.*)?$", line)
        if kv:
            key = kv.group(1); v = kv.group(2)
            fm[key] = [] if v in ("", "[]") else v.strip('"')
    return fm, m.group(2)

for f in sorted(glob.glob(os.path.join(root, "updates", "*.md"))):
    if os.path.basename(f) == "README.md": continue
    rel = os.path.relpath(f, root)
    fm, body = parse(open(f, encoding="utf-8").read())
    if fm is None: errors.append(f"{rel}: missing frontmatter"); continue
    for k in ("id", "title", "kind", "release", "applies_to", "files"):
        if k not in fm: errors.append(f"{rel}: missing '{k}'")
    i = fm.get("id", "")
    if i:
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}-[a-z0-9]+(-[a-z0-9]+)*", i):
            errors.append(f"{rel}: id '{i}' must be YYYY-MM-DD-<kebab-case>")
        if os.path.splitext(os.path.basename(f))[0] != i: errors.append(f"{rel}: file name must be '{i}.md'")
        if i in notes: errors.append(f"{rel}: duplicate id '{i}'")
        notes[i] = (rel, fm)
    k = fm.get("kind")
    if k and k not in kinds: errors.append(f"{rel}: unknown kind '{k}'")
    r = fm.get("release", "")
    if r and r != "unreleased" and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", r):
        errors.append(f"{rel}: release must be YYYY-MM-DD or unreleased")
    if k == "module":
        mod = fm.get("offer_module")
        if not mod: errors.append(f"{rel}: kind module needs offer_module")
        elif not os.path.isdir(os.path.join(root, "template", "harness", "modules", mod)):
            errors.append(f"{rel}: offer_module '{mod}' has no folder under template/harness/modules/")
    files = fm.get("files") if isinstance(fm.get("files"), list) else []
    removed = fm.get("removed") if isinstance(fm.get("removed"), list) else []
    if not files and not removed: errors.append(f"{rel}: lists no files")
    for p in files:
        if not os.path.isfile(os.path.join(root, "template", p)):
            errors.append(f"{rel}: file '{p}' not found in template/")
    for p in removed:
        if os.path.exists(os.path.join(root, "template", p)):
            errors.append(f"{rel}: removed file '{p}' still exists in template/")
    for h in ("## What changed", "## Why", "## How to apply"):
        if h not in (body or ""): errors.append(f"{rel}: missing '{h}' section")

# Releases: every dated release a note names has a CHANGELOG heading, and plugin.json carries the newest.
changelog = open(os.path.join(root, "CHANGELOG.md"), encoding="utf-8").read()
dated = re.findall(r"^## (\d{4}-\d{2}-\d{2})\s*$", changelog, re.M)
for i, (rel, fm) in notes.items():
    r = fm.get("release")
    if r and r != "unreleased" and r not in dated:
        errors.append(f"{rel}: release {r} has no '## {r}' heading in CHANGELOG.md")
if dated:
    want = dated[0].replace("-", ".")
    version = json.load(open(os.path.join(root, ".claude-plugin", "plugin.json")))["version"]
    if version != want:
        errors.append(f".claude-plugin/plugin.json: version {version} doesn't match the newest release {dated[0]} (expected {want})")

if since:
    def git(*a):
        return subprocess.run(["git", "-C", root, *a], check=True, capture_output=True, text=True).stdout.split()
    changed_tpl = {p[len("template/"):] for p in git("diff", "--name-only", since, "--", "template")
                   + git("ls-files", "--others", "--exclude-standard", "--", "template")}
    changed_notes = {p for p in git("diff", "--name-only", since, "--", "updates")
                     + git("ls-files", "--others", "--exclude-standard", "--", "updates")}
    listed = set()
    for i, (rel, fm) in notes.items():
        if rel in changed_notes:
            for key in ("files", "removed"):
                if isinstance(fm.get(key), list): listed.update(fm[key])
    for p in sorted(changed_tpl - listed):
        errors.append(f"template/{p}: changed since {since} but no new or changed note in updates/ lists it")

for e in errors: print(e)
print(f"{len(notes)} update note(s) checked, {len(errors)} problem(s)")
sys.exit(1 if errors else 0)
PY
