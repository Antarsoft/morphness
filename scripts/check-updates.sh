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
# Release names: `v0.13.0` (semantic version) since the dated names ended; the earlier releases keep the
# date (`2026-10-14`), then `.2`, `.3` ... for later releases the same day.
LEGACY = re.compile(r"(\d{4})-(\d{2})-(\d{2})(?:\.([2-9]|[1-9]\d+))?")
SEMVER = re.compile(r"v(\d+)\.(\d+)\.(\d+)")
NAME = "v<major>.<minor>.<patch>, or an earlier dated name YYYY-MM-DD / YYYY-MM-DD.N (N >= 2)"
# The first two releases used the dotted date as the plugin version; later ones use YYYYMMDD.N.0.
LEGACY_VERSIONS = {"2026-10-12": "2026.10.12", "2026-10-13": "2026.10.13"}

def is_release(name):
    return bool(LEGACY.fullmatch(name) or SEMVER.fullmatch(name))

def release_key(name):
    # Dated names sort before every semantic version; versions compare as numbers (v0.10.0 > v0.9.0).
    m = SEMVER.fullmatch(name)
    if m: return (1, int(m.group(1)), int(m.group(2)), int(m.group(3)))
    m = LEGACY.fullmatch(name)
    return (0, int(m.group(1) + m.group(2) + m.group(3)), int(m.group(4) or 1), 0)

def plugin_version(name):
    # Dated releases only. A semantic release keeps a date-shaped plugin build number (see below).
    if name in LEGACY_VERSIONS: return LEGACY_VERSIONS[name]
    k = release_key(name)
    return f"{k[1]}.{k[2]}.0"
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

all_removed = set()
for f in glob.glob(os.path.join(root, "updates", "*.md")):
    fm0, _ = parse(open(f, encoding="utf-8").read())
    if fm0 and isinstance(fm0.get("removed"), list): all_removed.update(fm0["removed"])

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
    if r and r != "unreleased" and not is_release(r):
        errors.append(f"{rel}: release must be {NAME} or unreleased")
    if k == "module":
        mod = fm.get("offer_module")
        if not mod: errors.append(f"{rel}: kind module needs offer_module")
        elif not os.path.isdir(os.path.join(root, "template", "harness", "modules", mod)):
            errors.append(f"{rel}: offer_module '{mod}' has no folder under template/harness/modules/")
    files = fm.get("files") if isinstance(fm.get("files"), list) else []
    removed = fm.get("removed") if isinstance(fm.get("removed"), list) else []
    if not files and not removed: errors.append(f"{rel}: lists no files")
    for p in files:
        # An older note may name a file a later note moved or deleted (its `removed:` list).
        if p not in all_removed and not os.path.isfile(os.path.join(root, "template", p)):
            errors.append(f"{rel}: file '{p}' not found in template/")
    for p in removed:
        if os.path.exists(os.path.join(root, "template", p)):
            errors.append(f"{rel}: removed file '{p}' still exists in template/")
    for pair in (fm.get("moved") if isinstance(fm.get("moved"), list) else []):
        src, _, dst = pair.partition(" -> ")
        if not dst: errors.append(f"{rel}: moved entry '{pair}' must read 'old/path -> new/path'"); continue
        if src not in removed: errors.append(f"{rel}: moved from '{src}' must also be listed under removed")
        if dst not in files: errors.append(f"{rel}: moved to '{dst}' must also be listed under files")
    for h in ("## What changed", "## Why", "## How to apply"):
        if h not in (body or ""): errors.append(f"{rel}: missing '{h}' section")

# Releases: every release a note names has a CHANGELOG heading, and plugin.json carries the newest.
# Headings: `## v0.13.0 (2026-10-21)`, or for the earlier releases `## 2026-10-20.5`.
changelog = open(os.path.join(root, "CHANGELOG.md"), encoding="utf-8").read()
HEADING = re.compile(r"^## (\S+)(?: \((\d{4}-\d{2}-\d{2})\))?\s*$", re.M)
dated, heading_date = [], {}
for h, d in HEADING.findall(changelog):
    if not (re.match(r"\d{4}-\d{2}-\d{2}", h) or h.startswith("v")): continue   # other sections
    if not is_release(h):
        errors.append(f"CHANGELOG.md: heading '## {h}' isn't a release name ({NAME})"); continue
    if SEMVER.fullmatch(h) and not d: errors.append(f"CHANGELOG.md: '## {h}' needs its date: '## {h} (YYYY-MM-DD)'")
    if LEGACY.fullmatch(h) and d: errors.append(f"CHANGELOG.md: '## {h}' is a dated name and takes no version date")
    dated.append(h); heading_date[h] = d
if dated != sorted(dated, key=release_key, reverse=True):
    errors.append("CHANGELOG.md: release headings must be newest first")
if len(set(dated)) != len(dated):
    errors.append("CHANGELOG.md: a release heading appears twice")
for i, (rel, fm) in notes.items():
    r = fm.get("release")
    if r and r != "unreleased" and r not in dated:
        errors.append(f"{rel}: release {r} has no '## {r}' heading in CHANGELOG.md")

# The version map: each dated release has a semantic version, ascending, and the newest version
# heading is above the last mapped one.
mapped = {}
for d, v in re.findall(r"^\|\s*(\d{4}-\d{2}-\d{2}(?:\.\d+)?)\s*\|\s*(v\d+\.\d+\.\d+)\s*\|", changelog, re.M):
    if d in mapped: errors.append(f"CHANGELOG.md: version map lists {d} twice")
    mapped[d] = v
legacy = [h for h in dated if LEGACY.fullmatch(h)]
for h in legacy:
    if h not in mapped: errors.append(f"CHANGELOG.md: dated release {h} is missing from the version map")
for h in mapped:
    if h not in legacy: errors.append(f"CHANGELOG.md: version map names {h}, which has no '## {h}' heading")
ordered = sorted((h for h in mapped if h in legacy), key=release_key)
vers = [release_key(mapped[h]) for h in ordered]
if vers != sorted(set(vers)):
    errors.append("CHANGELOG.md: version map versions must rise with the release order")
current = [h for h in dated if SEMVER.fullmatch(h)]
if current and vers and release_key(current[-1]) <= max(vers):
    errors.append(f"CHANGELOG.md: version {current[-1]} must be above the last mapped version")

if dated:
    version = json.load(open(os.path.join(root, ".claude-plugin", "plugin.json")))["version"]
    if LEGACY.fullmatch(dated[0]):
        want = plugin_version(dated[0])
        if version != want:
            errors.append(f".claude-plugin/plugin.json: version {version} doesn't match the newest release {dated[0]} (expected {want})")
    else:
        # Claude Code offers a plugin update only when this number rises, and 0.x is below the dated
        # numbers, so plugin.json keeps YYYYMMDD.N.0 as a plugin build number: the release date,
        # above every earlier one.
        m = re.fullmatch(r"(\d{8})\.(\d+)\.0", version)
        if not m or m.group(1) != heading_date[dated[0]].replace("-", ""):
            errors.append(f".claude-plugin/plugin.json: version {version} must be YYYYMMDD.N.0 with the date of {dated[0]} ({heading_date[dated[0]]})")
        elif legacy and (int(m.group(1)), int(m.group(2))) <= release_key(legacy[0])[1:3]:
            errors.append(f".claude-plugin/plugin.json: version {version} must be above the newest dated release's {plugin_version(legacy[0])}")

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

    # Kit changes carry a changelog fragment instead of editing CHANGELOG.md (no merge conflicts).
    added = {p for p in git("diff", "--name-only", "--diff-filter=AM", since, "--", "changelog.d")
             + git("ls-files", "--others", "--exclude-standard", "--", "changelog.d")}
    kit = git("diff", "--name-only", since, "--", "template", "skills") \
        + git("ls-files", "--others", "--exclude-standard", "--", "template", "skills")
    if kit and not any(os.path.basename(p) != "README.md" for p in added):
        errors.append(f"template/ or skills/ changed since {since} but no new changelog.d/<slug>.md fragment (don't edit CHANGELOG.md)")

for e in errors: print(e)
print(f"{len(notes)} update note(s) checked, {len(errors)} problem(s)")
sys.exit(1 if errors else 0)
PY
