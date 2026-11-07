#!/usr/bin/env bash
# Prints a subagent's prompt block from harness/HANDOFFS.md § Subagent prompt blocks with every field a script can
# fill already filled, so a hand-off takes one call instead of a print of the block plus the git and check calls
# that fill it (harness/TECHNICAL_LEAD.md § Full mode, step by step). What only the conversation holds (the request,
# the human's corrections, run durations) stays as a <placeholder>, and the last line lists them for you to fill.
#
# Fills: the feature folder's absolute path; the files from the plan brief's risk check (scout); the code map's path
# and commit, or drops the Code map line when there is no map (bug mode); the Path rules line, from the
# .claude/rules/*.md files whose paths: match the files plan.md names and the branch changes; for QA the merge base,
# `git diff --stat`, the untracked files and `bash scripts/checks.sh status`; for the closer the mode, the commit QA
# passed on and the cost script's --branch flag.
# It writes nothing in the work tree: it runs git commands that read (without optional locks) and `checks.sh status`,
# which keeps its records inside the git folder.
#
# Usage: bash scripts/handoff.sh <role> <slug> [--version N] [--base <commit>]
#   role: scout | fullstack | fullstack-bug | qa | qa-repro | closer
#   --base: QA round 2 tests from the commit round 1 tested (default: git merge-base origin/<integration> HEAD)
# Exits 0, or 2 on a usage error or when harness/HANDOFFS.md has no block for the role.

role=""; slug=""; version=1; base=""
usage() { echo "usage: bash scripts/handoff.sh <scout|fullstack|fullstack-bug|qa|qa-repro|closer> <slug> [--version N] [--base <commit>]" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --version) [ $# -ge 2 ] || usage; version="$2"; shift 2 ;;
    --version=*) version="${1#--version=}"; shift ;;
    --base) [ $# -ge 2 ] || usage; base="$2"; shift 2 ;;
    --base=*) base="${1#--base=}"; shift ;;
    -*) echo "handoff: unknown option $1" >&2; usage ;;
    *) if [ -z "$role" ]; then role="$1"; elif [ -z "$slug" ]; then slug="$1"; else usage; fi; shift ;;
  esac
done
case "$role" in scout|fullstack|fullstack-bug|qa|qa-repro|closer) ;; *) usage ;; esac
case "$slug" in ''|*[!a-z0-9-]*|-*) echo "handoff: the slug must be lowercase letters, digits and hyphens (got '$slug')" >&2; usage ;; esac
case "$version" in ''|*[!0-9]*|0*) echo "handoff: --version takes a number from 1 (got '$version')" >&2; usage ;; esac
case "$base" in -*|*[!0-9A-Za-z._/~^-]*) echo "handoff: --base takes a commit (got '$base')" >&2; usage ;; esac
command -v python3 >/dev/null 2>&1 || { echo "handoff: python3 is missing" >&2; exit 2; }
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
. "$here/lib/config.sh" 2>/dev/null || { echo "handoff: scripts/lib/config.sh is missing" >&2; exit 2; }
integration="$(cd "$root" && config_get branches.integration)"

GIT_OPTIONAL_LOCKS=0 ROLE="$role" SLUG="$slug" VERSION="$version" BASE="$base" INTEGRATION="${integration:-main}" \
  exec python3 -I - "$root" <<'PY'
import fnmatch, os, re, subprocess, sys

root = sys.argv[1]
role, slug, version = os.environ["ROLE"], os.environ["SLUG"], os.environ["VERSION"]
feature = os.path.join(root, "_harness", "features", slug, version)

def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True, cwd=root)
    return r.stdout.strip() if r.returncode == 0 else ""

def read(rel):
    try:
        return open(os.path.join(root, rel), encoding="utf-8-sig", errors="replace").read()
    except OSError:
        return ""

# The block: the ```text fence under the role's heading in harness/HANDOFFS.md.
heading = {"scout": "Code scout", "fullstack": "Full-stack engineer", "fullstack-bug": "Full-stack engineer",
           "qa": "QA engineer", "qa-repro": "QA engineer, bug reproduction", "closer": "Feature closer"}[role]
handoffs = read("harness/HANDOFFS.md")

def block(name):
    m = re.search(r"^### " + re.escape(name) + r"\n(.*?)(?=^### |^## |\Z)", handoffs, re.M | re.S)
    f = m and re.search(r"```text\n(.*?)\n```", m.group(1), re.S)
    return f.group(1) if f else None

text = block(heading)
if text is None:
    sys.exit(f"handoff: harness/HANDOFFS.md has no ```text block under ### {heading}")
if role == "fullstack-bug":
    extra = block("Full-stack engineer, bug mode")
    if extra is None:
        sys.exit("handoff: harness/HANDOFFS.md has no ```text block under ### Full-stack engineer, bug mode")
    text = text + "\n" + extra

plan = read(os.path.relpath(os.path.join(feature, "Plan", "plan.md"), root))
brief = read(os.path.relpath(os.path.join(feature, "Plan", "brief.md"), root))
cmap = read(os.path.relpath(os.path.join(feature, "Plan", "code-map.md"), root))
bug = (role in ("fullstack-bug", "qa-repro") or bool(re.search(r"\(bug mode\)", brief[:400]))
       or plan.lstrip().startswith("# Bug plan") or "\n## Fix limit" in plan)

# Files: the ones the plan brief was made for (its `Files:` line, every file the Technical Lead named), the plan's
# backticked paths (with a :line or :start-end cut off) that exist or sit in a folder that exists, and what the
# branch changed.
def risk_files():
    m = re.search(r"^Files: (.+)$", brief, re.M)
    return [f.strip() for f in m.group(1).split(", ") if f.strip()] if m and m.group(1).strip() != "none" else []

def plan_files():
    out = []
    for p in re.findall(r"`([^`\s]+)`", plan):
        p = re.sub(r":\d[\d-]*$", "", p).rstrip("/")
        if not p or p.startswith(("_harness/", "harness/", "/", "-", "http")) or ".." in p.split("/"):
            continue
        here = os.path.join(root, p)
        if os.path.exists(here) or ("/" in p and os.path.isdir(os.path.dirname(here))):
            out.append(p + ("/x" if os.path.isdir(here) else ""))   # a folder: match rules on what goes inside it
    return out

integration = os.environ["INTEGRATION"]
upstream = f"origin/{integration}" if git("rev-parse", "--verify", "-q", f"origin/{integration}") else integration
given = os.environ["BASE"]
merge_base = git("rev-parse", "--verify", "-q", (given or git("merge-base", upstream, "HEAD") or "-") + "^{commit}")
if given and not merge_base:
    sys.stderr.write(f"handoff: --base {given} names no commit here\n")
    sys.exit(2)
short_base = git("rev-parse", "--short", merge_base) if merge_base else ""
changed = git("diff", "--name-only", merge_base).splitlines() if merge_base else []
untracked = [l[3:] for l in git("status", "--porcelain", "--untracked-files=all").splitlines() if l.startswith("?? ")]
untracked = [u for u in untracked if not u.startswith("_harness/")]
files = list(dict.fromkeys(risk_files() + plan_files() + changed + untracked))

# Path rules: .claude/rules/*.md whose paths: globs match any of the files (** crosses folders, * doesn't).
def glob_re(g):
    out, i = "", 0
    while i < len(g):
        if g.startswith("**/", i): out += "(?:.*/)?"; i += 3
        elif g.startswith("**", i): out += ".*"; i += 2
        elif g[i] == "*": out += "[^/]*"; i += 1
        elif g[i] == "?": out += "[^/]"; i += 1
        else: out += re.escape(g[i]); i += 1
    return re.compile(out + r"\Z")

rules = []
rules_dir = os.path.join(root, ".claude", "rules")
for name in sorted(os.listdir(rules_dir)) if os.path.isdir(rules_dir) else []:
    if not name.endswith(".md") or name == "harness.md":
        continue
    head = re.match(r"\A---\n(.*?)\n---\n", read(f".claude/rules/{name}"), re.S)
    block = re.search(r"^paths:\s*\n((?:[ \t]+-[^\n]*\n?)+)", head.group(1) + "\n", re.M) if head else None
    globs = re.findall(r"^\s*-\s*[\"']?([^\"'\n]+?)[\"']?\s*$", block.group(1), re.M) if block else []
    expand = lambda g: [x for b in re.findall(r"\{([^{}]*)\}", g)[:1] for o in b.split(",") for x in expand(g.replace("{" + b + "}", o, 1))] or [g]
    globs = [x for g in globs for x in expand(g)]
    if any(glob_re(g).match(f) for g in globs for f in files):
        rules.append(f".claude/rules/{name}")

def sub(old, new):
    global text
    text = text.replace(old, new)

def sub_re(pattern, new):
    global text
    text = re.sub(pattern, lambda m: new, text)

# The scout block names the repo-relative feature folder under <abs-path>; the others mean the feature folder.
sub("<abs-path>/_harness/features/<slug>/<version>/", feature + "/")
sub("<abs-path>", feature)
sub("<slug>", slug)
sub("<version>", version)
sub_re(r"<the files plan-brief\.sh or risk-check\.sh named>", ", ".join(risk_files()) or "<the files plan-brief.sh or risk-check.sh named>")
text = re.sub(r"^Path rules: <[^\n]*?>(?=\. )", "Path rules: " + (", ".join(rules) or "none"), text, flags=re.M)

commit = (re.search(r"\*\*Commit:\*\*\s*`?([0-9a-f]{7,40})", cmap) or re.search(r"Commit[^\n]*?`?([0-9a-f]{7,40})", cmap))
if cmap and not bug:
    sub("<its Commit line>", commit.group(1) if commit else "<its Commit line>")
    text = re.sub(r"^Code map \(full mode; drop this line in bug mode[^)]*\): ", "Code map: ", text, flags=re.M)
else:
    text = re.sub(r"^Code map \(full mode;[^\n]*\n", "", text, flags=re.M)

notes = []
if not plan and role not in ("scout",):
    notes.append(f"{os.path.relpath(feature, root)}/Plan/plan.md is missing")
if role in ("fullstack", "qa") and not bug and not cmap:
    notes.append("no code map in this full-mode feature: run the code scout first (bash scripts/handoff.sh scout " + slug + ")")

if role == "qa":
    if merge_base:
        stat = git("diff", "--stat", merge_base)
        sub_re(r"<git merge-base origin/<integration> HEAD; in round 2, the commit round 1 tested>", short_base)
        sub_re(r"<git diff --stat <base> output>", ("\n" + "\n".join("  " + l.strip() for l in stat.splitlines()) + "\n") if stat else "none (no tracked file changed)")
    else:
        notes.append(f"no merge base with {upstream}: fill the base and the diff stat by hand, or pass --base")
    sub_re(r"<new files from git status --porcelain, or none>", ", ".join(untracked) or "none")
    st = subprocess.run(["bash", os.path.join(root, "scripts", "checks.sh"), "status"], capture_output=True, text=True, cwd=root)
    sub_re(r"<bash scripts/checks\.sh status output>", (st.stdout.strip() or st.stderr.strip() or f"exit {st.returncode}"))
    if merge_base:
        sub("git diff <base>", f"git diff {short_base}")

if role == "closer":
    sub("mode: full | bug;", "mode: bug;" if bug else "mode: full;")
    qa = read(os.path.relpath(os.path.join(feature, "QA", "qa-result.md"), root))
    tested = re.search(r"\*\*Commit / PR:\*\*\s*`?([0-9a-f]{7,40})", qa)
    sha = git("rev-parse", "--short", tested.group(1)) if tested else git("rev-parse", "--short", "HEAD")
    sub("<sha>", sha or "<sha>")
    branch = git("rev-parse", "--abbrev-ref", "HEAD")
    sub("<--since <time> | --branch <branch> | no flags>", f"--branch {branch}" if branch and branch != "HEAD" else "<--since <time> | --branch <branch> | no flags>")

print(text)
# What's left: each line that still holds a <placeholder> (or the closer's verdict choice), by its label.
left = []
for line in text.splitlines():
    ph = re.findall(r"<(?!/)[^<>\n]*(?:<[^<>\n]*>[^<>\n]*)*>", line)
    ph = [p for p in ph if p != "<feature>"]
    if ph or "pass | failed-escalated" in line:
        label = re.match(r"^\W*([A-Z][^:<]{0,60}):", line)
        left.append(label.group(1).strip() if label else "; ".join(ph))
left = list(dict.fromkeys(left))
print("\nhandoff: " + (f"still to fill from the conversation: {'; '.join(left)}" if left else "every field is filled") + ".")
for n in notes:
    print("handoff: " + n + ".")
PY
