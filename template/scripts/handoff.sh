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
# For Full-stack and QA it also compiles the agent brief: the project addendum, .claude/rules/testing.md, the path rules
# and the project files the role body and the addendum name (with their comments and emptied headings taken out),
# written to <git folder>/morphness/briefs/<slug>-<version>-<fullstack|qa>.md and named on the Agent brief line, so
# the agent reads one file instead of five to seven. It is rebuilt at every hand-off, so it never lags its sources.
# It writes nothing in the work tree: it runs git commands that read (without optional locks) and `checks.sh status`,
# which keeps its records inside the git folder, and the brief goes in the git folder too.
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
bug_repro="$(cd "$root" && config_get mode.bug_repro)"

GIT_OPTIONAL_LOCKS=0 ROLE="$role" SLUG="$slug" VERSION="$version" BASE="$base" INTEGRATION="${integration:-main}" BUG_REPRO="${bug_repro:-qa}" \
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
own_repro = os.environ.get("BUG_REPRO") == "fullstack"   # mode.bug_repro: fullstack (a trial, harness/MODES.md § Bug mode)
if os.environ.get("BUG_REPRO") not in ("qa", "fullstack"):
    sys.stderr.write(f"handoff: harness.config.yml mode.bug_repro is {os.environ.get('BUG_REPRO')!r}; it takes qa or fullstack, so qa is used\n")
if role == "qa-repro" and own_repro:
    sys.stderr.write("handoff: mode.bug_repro is fullstack, so there is no QA reproduction run: the Full-stack engineer "
                     "writes and commits the failing test (bash scripts/handoff.sh fullstack-bug " + slug + ")\n")
    sys.exit(2)
if role == "fullstack-bug":
    name = "Full-stack engineer, bug mode with its own reproduction" if own_repro else "Full-stack engineer, bug mode"
    extra = block(name)
    if extra is None:
        sys.exit(f"handoff: harness/HANDOFFS.md has no ```text block under ### {name}")
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

def expand(g):   # a {a,b} brace in a paths: glob
    return [x for b in re.findall(r"\{([^{}]*)\}", g)[:1] for o in b.split(",") for x in expand(g.replace("{" + b + "}", o, 1))] or [g]

rules = []
rules_dir = os.path.join(root, ".claude", "rules")
for name in sorted(os.listdir(rules_dir)) if os.path.isdir(rules_dir) else []:
    if not name.endswith(".md") or name == "harness.md":
        continue
    head = re.match(r"\A---\n(.*?)\n---\n", read(f".claude/rules/{name}"), re.S)
    block = re.search(r"^paths:\s*\n((?:[ \t]+-[^\n]*\n?)+)", head.group(1) + "\n", re.M) if head else None
    globs = re.findall(r"^\s*-\s*[\"']?([^\"'\n]+?)[\"']?\s*$", block.group(1), re.M) if block else []
    globs = [x for g in globs for x in expand(g)]
    if any(glob_re(g).match(f) for g in globs for f in files):
        rules.append(f".claude/rules/{name}")

# The agent brief (Full-stack and QA): the project files the role body says to read before starting, compiled into one
# file in the git folder, so the agent reads one file instead of five to seven. Comments (morph-init's placeholders)
# and headings left empty without them are dropped; each source keeps its own words. It is compiled at every
# hand-off from the files as they are, so a retro edit or a fact the Full-stack engineer adds is in the next brief.
def headings(lines):
    out, fence = [], None
    for i, line in enumerate(lines):
        f = re.match(r"^\s*(`{3,}|~{3,})", line)
        if f:
            fence = f.group(1) if fence is None else (None if f.group(1)[0] == fence[0] and len(f.group(1)) >= len(fence) else fence)
            continue
        m = None if fence else re.match(r"^(#{1,6})\s+(.*?)(?:\s+#+)?\s*$", line)
        if m and m.group(2):
            out.append((i, len(m.group(1)), m.group(2)))
    return out

def norm(s):
    s = re.sub(r"[`*]", "", s).strip()
    return re.sub(r"\s+", " ", re.sub(r"^[#§\s]+", "", s)).strip().lower()

def clean(src, rel=""):
    src = re.sub(r"\A---\n.*?\n---\n", "", src, flags=re.S)            # a rule file's paths: frontmatter
    # Comments and links are rewritten only outside code: a fence or a `span` keeps its text as written.
    parts = re.split(r"(^[ \t]*(?:`{3,}|~{3,})[^\n]*\n.*?^[ \t]*(?:`{3,}|~{3,})[ \t]*$)", src, flags=re.M | re.S)
    keep_code = lambda pat, fn: lambda t: re.sub(r"(`[^`\n]*`)|" + pat, lambda m: m.group(1) or fn(m), t, flags=re.S)
    # A relative link would point the wrong way from the git folder: write its target as a repo path instead.
    def link(m):
        label, target = m.group(2), m.group(3)
        if re.match(r"^[a-z]+:|^#|^/", target):
            return m.group(0)
        path, hash_, anchor = target.partition("#")
        path = os.path.normpath(os.path.join(os.path.dirname(rel), path)).replace(os.sep, "/")
        bare = label.strip("`")
        shown = path + hash_ + anchor
        return f"`{shown}`" if bare == path else f"{label} (`{shown}`)"
    strip = keep_code(r"<!--.*?-->", lambda m: "")
    links = keep_code(r"(?<!!)\[([^\]\n]+)\]\(([^)\s]+)\)", lambda m: link(m))
    src = "".join(t if k % 2 else links(strip(t)) for k, t in enumerate(parts))
    return [l.rstrip() for l in src.split("\n")]

def spans(lines):
    hs = headings(lines)
    return [(i, lvl, t, next((h[0] for h in hs[k + 1:] if h[1] <= lvl), len(lines))) for k, (i, lvl, t) in enumerate(hs)]

def drop_empty(lines):
    # A heading whose section holds nothing but blank lines and headings goes, with its empty subsections.
    gone = set()
    for i, lvl, t, end in spans(lines):
        body = [l for j, l in enumerate(lines[i + 1:end], i + 1) if l.strip()]
        if all(re.match(r"^#{1,6}\s", l) for l in body):
            gone.update(range(i, end))
    return [l for j, l in enumerate(lines) if j not in gone]

def demote(lines, by):
    hs = {i: lvl for i, lvl, _ in headings(lines)}
    return [("#" * min(6, hs[j] + by) + l[hs[j]:]) if j in hs else l for j, l in enumerate(lines)]

def section(lines, name):
    want, sp = norm(name), spans(lines)
    hit = [s for s in sp if norm(s[2]) == want] or [s for s in sp if norm(s[2]).startswith(want)]
    return lines[hit[0][0]:hit[0][3]] if len(hit) == 1 else None

def part(rel, names=None, note=()):
    src = read(rel)
    if not src:
        return None, [f"{rel} is missing"]
    lines, missing = clean(src, rel), []
    if lines and re.match(r"^# ", next((l for l in lines if l.strip()), "")):
        first = next(j for j, l in enumerate(lines) if l.strip())
        lines = lines[first + 1:]                                            # the file's own title
    for name, said in note:                                                  # a line under a heading
        got = section(lines, name)
        if got is not None:
            k = next(j for j in range(len(lines)) if lines[j:j + len(got)] == got)
            lines[k + 1:k + 1] = ["", said]
    if names:
        picked = []
        for name in names:
            got = section(lines, name)
            if got is None:
                missing.append(f"{rel} has no single section § {name}")
            else:
                picked += got + [""]
        lines = picked
    lines = drop_empty(lines)
    top = min((lvl for _, lvl, _ in headings(lines)), default=3)
    lines = demote(lines, 3 - top)
    text_ = re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip()
    return text_, missing

def reads_named(addendum):
    # The project files and sections the addendum's § Read before you start names, as "project/STACK.md § A, § B and
    # § C" on one line (a link's label counts as its text). A file named after skip, not, never, except or without is
    # left out; anything else the list says (another doc, a condition) stays in the brief's copy of the list.
    m = section(clean(read(addendum), addendum), "Read before you start")
    out = {}
    for line in (m[1:] if m else []):
        refs = list(re.finditer(r"`?(project/[\w./-]+\.md)`?", line))
        for k, r in enumerate(refs):
            if re.search(r"\b(?:skip|not|never|except|without|no)\b[^.;]{0,30}$", line[:r.start()], re.I):
                continue
            seg = line[r.end():refs[k + 1].start() if k + 1 < len(refs) else len(line)]
            seg = re.split(r";|\.(?:\s|$)", seg)[0]
            names = [n.strip() for n in re.findall(r"§\s*(.+?)(?=\s*(?:,\s*(?:and\s+)?§|\s+and\s+§|$))", seg)]
            names = [n for n in names if n]
            prev = out.get(r.group(1), [])
            out[r.group(1)] = None if prev is None or not names else prev + [n for n in names if n not in prev]
    return list(out.items())

def agent_brief(kind):
    addendum = f"project/agents/{'fullstack-engineer' if kind == 'fullstack' else 'qa-engineer'}.md"
    said = ("(The project files and sections this list names are below in this brief, so don't open them; read "
            "anything else it names yourself.)")
    srcs = [(addendum, None, (("Read before you start", said),)), (".claude/rules/testing.md", None, ())]
    srcs += [(r, None, ()) for r in rules]
    if kind == "fullstack":
        srcs += [("project/TESTING.md", None, ()), ("project/PROJECT.md", None, ())]
    whole = {rel for rel, names, _ in srcs}
    srcs += [(f, names, ()) for f, names in reads_named(addendum) if f not in whole]
    body, listed, problems = [], [], []
    for rel, names, note in srcs:
        got, missing = part(rel, names, note)
        problems += missing
        if got is None:
            continue
        found = [n for n in (names or []) if not any(n in p for p in missing)]
        label = rel + (" § " + ", § ".join(found) if found else "")
        listed.append(label)
        body.append(f"## {label}\n\n{got or '(nothing filled in yet)'}")
    common = git("rev-parse", "--git-common-dir")                           # where checks.sh keeps its records too
    gitdir = os.path.normpath(os.path.join(root, common)) if common else ""
    if not gitdir:
        return None, ["not a git checkout: no agent brief, so the agent reads the files itself"]
    path = os.path.join(gitdir, "morphness", "briefs", f"{slug}-{version}-{kind}.md")
    head = (f"# Agent brief: {'Full-stack engineer' if kind == 'fullstack' else 'QA engineer'}, {slug} v{version}\n\n"
            f"Compiled by scripts/handoff.sh at commit {git('rev-parse', '--short', 'HEAD') or 'none'} from the files below, "
            "with their comments taken out. Read this instead of them; open a source only for a section that is "
            "missing here. Don't edit this file: it is rebuilt at every hand-off, so a change goes in the source.\n\n"
            "Sources: " + "; ".join(listed) + "\n"
            + ("".join(f"\nMissing: {p}; read the file itself for it.\n" for p in problems)))
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(head + "\n" + "\n\n".join(body) + "\n")
    except OSError as e:
        return None, problems + [f"could not write the agent brief ({e.strerror}), so the agent reads the files itself"]
    return path, problems

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

brief_kind = {"fullstack": "fullstack", "fullstack-bug": "fullstack", "qa": "qa", "qa-repro": "qa"}.get(role)
brief_path, brief_notes = agent_brief(brief_kind) if brief_kind and plan else (None, [])
if brief_path:
    text = re.sub(r"^Agent brief \(drop this line when there is none\): <[^\n]*?>", "Agent brief: " + brief_path, text, flags=re.M)
    text = re.sub(r"^(Path rules: [^\n]*?\. )Read them (?:before the first edit|first)\.", r"\1They are in the agent brief.", text, flags=re.M)
else:
    text = re.sub(r"^Agent brief \(drop this line[^\n]*\n", "", text, flags=re.M)

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

notes += ["agent brief: " + n for n in brief_notes]

# Bug order (mode.bug_repro: fullstack): the failing test is committed alone, as WIP(<slug>): failing test, before any
# product change, and the test is unchanged since. The check reads the branch's own commits (none reachable from the
# integration or production branch, so a merge of either and a QA round 2's --base don't move it), and lists the
# product files the branch changed, which QA puts back as they were at that commit to see the test fail.
test_globs = []
_head = re.match(r"\A---\n(.*?)\n---\n", read(".claude/rules/testing.md"), re.S)
_block = re.search(r"^paths:\s*\n((?:[ \t]+-[^\n]*\n?)+)", _head.group(1) + "\n", re.M) if _head else None
for g in re.findall(r"^\s*-\s*[\"']?([^\"'\n]+?)[\"']?\s*$", _block.group(1), re.M) if _block else []:
    test_globs += [glob_re(x) for x in expand(g)]

def test_file(f):
    return any(r.match(f) for r in test_globs)

def own_commits():
    production = subprocess.run(["bash", "-c", ". scripts/lib/config.sh && config_get branches.production"],
                                capture_output=True, text=True, cwd=root).stdout.strip()
    stop = [r for b in dict.fromkeys([integration, production]) if b
            for r in (b, f"origin/{b}") if git("rev-parse", "--verify", "-q", r)]
    if not stop:
        return None
    return git("rev-list", "--reverse", "--topo-order", "--no-merges", "HEAD", "--not", *stop).splitlines()

def changed_in(sha):
    return [f for f in git("diff-tree", "--no-commit-id", "--name-only", "-r", sha).splitlines() if not f.startswith("_harness/")]

def bug_order():
    commits = own_commits()
    if commits is None:
        return None, [], f"no {integration} branch here, so the order can't be checked: QA checks it by hand"
    marks = [c for c in commits if re.fullmatch(rf"WIP\({re.escape(slug)}\): failing test\.?", git("log", "-1", "--format=%s", c).strip())]
    if len(marks) != 1:
        return None, [], f"PROBLEM: {len(marks)} commits on this branch are named WIP({slug}): failing test; there must be exactly one"
    mark, problems = marks[0], []
    before = commits[:commits.index(mark)]
    for sha in before:
        product = [f for f in changed_in(sha) if not test_file(f)]
        if product:
            problems.append(f"{sha[:9]} changes {', '.join(product)} before the failing-test commit")
    in_mark = changed_in(mark)
    tests = [f for f in in_mark if test_file(f)]
    if [f for f in in_mark if not test_file(f)] or not tests:
        problems.append(f"the failing-test commit changes {', '.join(f for f in in_mark if not test_file(f)) or 'no test file'}: it must hold only the test")
    # What the branch itself changed after it: its own later commits and the work tree, not a merged teammate's change.
    since = list(dict.fromkeys([f for c in commits[commits.index(mark) + 1:] for f in changed_in(c)]
                               + [f for f in git("diff", "--name-only", "HEAD").splitlines() if not f.startswith("_harness/")]))
    edited = [f for f in tests if f in since]
    if edited:
        problems.append(f"the test changed after the failing-test commit ({', '.join(edited)})")
    product = [f for f in since if not test_file(f)]
    support = [f for f in since if test_file(f) and f not in tests]
    short = git("rev-parse", "--short", mark)
    extra = (f" Other test files changed since: {', '.join(support)}; check they don't weaken the test." if support else "")
    if problems:
        return short, product, "PROBLEM: " + "; ".join(problems) + "." + extra
    return short, product, (f"ok: failing test {short} ({', '.join(tests)}) holds only test files, no product change comes before "
                            f"it, and the test is unchanged since. That shows the order of the commits, not that the fix wasn't "
                            f"already in the work tree; the run below shows that. Product files the branch changed since: "
                            f"{', '.join(product) or 'none'}." + extra)

if role == "qa" and own_repro and bug:
    mark, product, said = bug_order()
    text = re.sub(r"^Bug order \(mode\.bug_repro: fullstack; drop this line otherwise\): <[^\n]*?>", "Bug order: " + said.rstrip("."), text, flags=re.M)
    if mark:
        sub("<the failing-test commit>", mark)
        sub("each product file the branch changed", "each product file the Bug order line lists")
    if said.startswith(("PROBLEM", "no merge")):
        notes.append("bug order: " + said)
else:
    text = re.sub(r"^Bug order \(mode\.bug_repro[^\n]*\n", "", text, flags=re.M)

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
