#!/usr/bin/env bash
# Decides how a change is run from the files it touches, so the same request always gets the same
# answer (harness/MODES.md § Choosing mode). It prints `Mode: full` or `Mode: plain` on the first line,
# then one line per reason.
#   full   a file matches a risk path (project/CONTROLS.md § Risk paths); or a line the change adds to a
#          file that isn't documentation deletes stored data (SQL that drops a table, column, schema or
#          database, truncates, or deletes rows: the DELETES pattern below; it reads one line at a time
#          and doesn't see an ORM's delete calls); or the branch drops a risk path from that list or
#          changes this script; or more files change than mode.plain_max_files (documentation and
#          _harness/ records not counted)
#   plain  none of these
# The files: the ones named on the command line (what a plan will change), plus what the branch has
# changed so far (its commits since it left the integration branch, uncommitted changes, new files).
# The owner's word wins over the paths: --force full|plain, or mode.force in harness.config.yml.
# When it can't decide (no file named and none changed, the integration branch missing, no python3,
# an unknown option), it prints
# `Mode: full` with the reason and exits 2; otherwise it exits 0. Read-only.
# Usage: bash scripts/risk-check.sh [--force full|plain] [file ...]   (from anywhere in the repo)

force=""
files=()
while [ $# -gt 0 ]; do
  case "$1" in
    --force) force="${2:-}"; shift 2 || { echo "Mode: full (risk check: --force needs full or plain)"; exit 2; } ;;
    --force=*) force="${1#--force=}"; shift ;;
    --) shift; files+=("$@"); break ;;
    -*) echo "Mode: full (risk check: unknown option $1)"; echo "usage: bash scripts/risk-check.sh [--force full|plain] [file ...]" >&2; exit 2 ;;
    *) files+=("$1"); shift ;;
  esac
done
case "$force" in ''|full|plain) ;; *) echo "Mode: full (risk check: --force takes full or plain, not $force)"; exit 2 ;; esac
command -v python3 >/dev/null 2>&1 || { echo "Mode: full (risk check: python3 is missing)"; exit 2; }
command -v git >/dev/null 2>&1 || { echo "Mode: full (risk check: git is missing)"; exit 2; }
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib/config.sh" 2>/dev/null || { echo "Mode: full (risk check: scripts/lib/config.sh is missing or unreadable)"; exit 2; }
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Paths named on the command line are taken relative to where it was run, like git does.
prefix="$(git rev-parse --show-prefix 2>/dev/null)"
cd "$root" || { echo "Mode: full (risk check: cannot enter the project folder)"; exit 2; }

[ -n "$force" ] || force="$(config_get mode.force)"
max="$(config_get mode.plain_max_files)"
integration="$(config_get branches.integration)"

RISK_FORCE="$force" RISK_MAX="$max" RISK_INTEGRATION="$integration" RISK_PREFIX="$prefix" \
  python3 -I - "${files[@]}" <<'PY'
import os, re, subprocess, sys

def git(*args):
    try:
        r = subprocess.run(["git", *args], capture_output=True, timeout=20)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout.decode("utf-8", "replace") if r.returncode == 0 else None

def fail(why):
    print(f"Mode: full (risk check: {why})")
    sys.exit(2)

force = os.environ.get("RISK_FORCE", "").strip().strip("\"'")
if force in ("", "auto"):
    force = ""
elif force not in ("full", "plain"):
    fail(f"mode.force is {force!r}; it takes auto, full or plain")
raw_max = os.environ.get("RISK_MAX", "").strip()
max_files = int(raw_max, 10) if raw_max.isdigit() else 6
prefix = os.environ.get("RISK_PREFIX", "")
root = os.getcwd()

def named(p):
    """A path from the command line, as git names it: from the repo root."""
    p = p.strip().replace("\\", "/")
    if not p:
        return ""
    if os.path.isabs(p):
        p = os.path.relpath(os.path.realpath(p), os.path.realpath(root))
    else:
        p = os.path.join(prefix, p)
    return os.path.normpath(p).replace("\\", "/")

planned = [named(p) for p in sys.argv[1:] if p.strip()]
EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

def is_record(p):
    """Documentation and the harness's own run records: never counted, never scanned for deletes."""
    low = p.lower()
    return (low.endswith((".md", ".mdx", ".markdown", ".rst", ".adoc"))
            or low.startswith(("docs/", "_harness/")) or "/docs/" in low)

# What the branch has changed: since it left the integration branch, plus the working tree.
# Paths come NUL-separated and unquoted, so names with spaces or accents match like any other.
changed, added_lines, base = [], [], None
if git("rev-parse", "--git-dir") is not None:
    integ = os.environ.get("RISK_INTEGRATION", "") or "dev"
    if git("rev-parse", "-q", "--verify", "HEAD") is None:
        base = EMPTY_TREE  # no commit yet: everything in the folder is the change
    else:
        for ref in (f"origin/{integ}", integ, "origin/HEAD"):
            if git("rev-parse", "-q", "--verify", ref + "^{commit}"):
                base = (git("merge-base", "HEAD", ref) or "").strip() or None
                if base:
                    break
        if base is None:
            fail(f"no branch {integ} or origin/{integ} to compare with (harness.config.yml → branches.integration)")
    names = git("-c", "core.quotePath=false", "diff", "--name-only", "--no-renames", "-z", base)
    if names is None:
        fail("git diff failed")
    for p in names.split("\0"):
        if not p:
            continue
        changed.append(p)
        if is_record(p):
            continue
        patch = git("--literal-pathspecs", "diff", "-U0", "--no-renames", "--no-color", "--no-ext-diff", base, "--", p)
        if patch is None:
            fail("git diff failed")
        body = False
        for line in patch.split("\n"):
            if line.startswith("@@"):
                body = True
            elif body and line.startswith("+"):
                added_lines.append((p, line[1:]))
    untracked = git("ls-files", "--others", "--exclude-standard", "-z")
    for p in (untracked or "").split("\0"):
        if not p:
            continue
        changed.append(p)
        try:
            if os.path.getsize(p) <= 1_000_000:
                with open(p, encoding="utf-8", errors="replace") as fh:
                    added_lines += [(p, l) for l in fh.read().split("\n")]
        except OSError:
            pass

files = []
for p in planned + changed:
    if p and p != "." and p not in files:
        files.append(p)
if not files:
    fail("no file named and none changed yet: run it with the files the change will touch")

# Risk paths: every `glob` on a bullet line in project/CONTROLS.md § Risk paths.
try:
    with open("project/CONTROLS.md", encoding="utf-8-sig") as fh:
        controls = fh.read()
except OSError:
    fail("project/CONTROLS.md is missing")
def risk_rules(text):
    m = re.search(r"^## Risk paths[ \t]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    if not m:
        return None
    out = []
    for line in m.group(1).split("\n"):
        b = re.match(r"^\s*[-*]\s+(?:\*\*(.+?):?\*\*:?)?(.*)$", line)
        if not b:
            continue
        area = (b.group(1) or "risk path").rstrip(":")
        for g in re.findall(r"`([^`\s]+)`", b.group(2)):
            out.append((area, g))
    return out

rules = risk_rules(controls)
if rules is None:
    fail("project/CONTROLS.md has no § Risk paths")

def to_regex(g):
    g = g.strip()
    # Like .gitignore: a pattern with a slash (other than a trailing one) is from the repo root;
    # one without matches that name in any folder.
    anchored = "/" in g.rstrip("/")
    g = g.lstrip("/")
    if g.endswith("/"):
        g += "**"
    out, i = "", 0
    while i < len(g):
        if g.startswith("**/", i):
            out += "(?:.*/)?"; i += 3
        elif g.startswith("**", i):
            out += ".*"; i += 2
        elif g[i] == "*":
            out += "[^/]*"; i += 1
        elif g[i] == "?":
            out += "[^/]"; i += 1
        else:
            out += re.escape(g[i]); i += 1
    if not anchored:
        out = "(?:.*/)?" + out
    # A plain directory name also covers what is under it.
    return re.compile(r"^" + out + r"(?:/.*)?$", re.I)

compiled = [(area, g, to_regex(g)) for area, g in rules]
reasons = []
for p in files:
    for area, g, rx in compiled:
        if rx.match(p):
            reasons.append(f"- {p}: {area} (`{g}`)")
            break

DELETES = re.compile(r"\b(drop\s+(table|column|schema|database)\b|truncate\s+(table\s+)?[\w\"`.]+|delete\s+from\b"
                     r"|alter\s+table\b.*\bdrop\b)", re.I)
seen = set()
for p, line in added_lines:
    if is_record(p) or p in seen:
        continue
    hit = DELETES.search(line)
    if hit:
        seen.add(p)
        reasons.append(f"- {p} adds \"{hit.group(0).strip()}\": deletes stored data")

# The list and this script decide what needs a review, so weakening either is never plain.
if "scripts/risk-check.sh" in files:
    reasons.append("- scripts/risk-check.sh: the risk check itself")
if base and "project/CONTROLS.md" in files:
    before = git("show", f"{base}:project/CONTROLS.md") if base != EMPTY_TREE else None
    dropped = [g for _, g in (risk_rules(before or "") or []) if g not in {g2 for _, g2 in rules}]
    if dropped:
        reasons.append("- project/CONTROLS.md drops risk path " + ", ".join(f"`{g}`" for g in dropped))

counted = [p for p in files if not is_record(p)]
if len(counted) > max_files:
    reasons.append(f"- {len(counted)} files change, more than mode.plain_max_files ({max_files}), documentation not counted")

auto = "full" if reasons else "plain"
if force and force != auto:
    print(f"Mode: {force} (the owner chose {force}; without that: {auto})")
elif force:
    print(f"Mode: {force} (the owner chose {force})")
elif auto == "plain" and not counted:
    print("Mode: plain (documentation only)")
elif auto == "plain":
    print(f"Mode: plain ({len(counted)} file{'s' if len(counted) != 1 else ''}, none on a risk path)")
else:
    print("Mode: full")
for r in reasons:
    print(r)
PY
