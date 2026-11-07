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
#   plain  none of these. A file on a risk path in a database area (its name says database, schema, migration
#          or sql, and nothing a risk path guards) counts as plain when it is a new .sql migration whose every
#          statement fits the strict allow-list in add_statement() below, or a .sql database test in a test
#          folder outside the migrations: printed as `+ <file>: …` lines and a `Needs:` line
#          (harness/MODES.md § Additive migration). When anything else makes the change full, or the owner
#          forces full, they are risk paths again.
#          With mode.risk_by: change (a trial; the default, file, judges by path alone), a file on a risk path
#          that isn't a .sql file also counts as plain when the change to it is an ordering or paging edit: every
#          changed line is an order/sort/limit/range call, a blank line or a comment (an allow-list, ORDER_CALL
#          below); the file is on the integration branch and still there; at most mode.contained_max_lines lines
#          change; no risk area it matches is about sign-in, secrets, money or the database; and no line of the
#          functions the change is in has a risk word (RISK_TERMS_* below, plus mode.risk_terms). Printed as
#          `~ <file>: …` lines and a `Needs:` line (harness/MODES.md § Contained change). A file named but not
#          changed yet is full, with a note to make the change first and run this again.
# The files: the ones named on the command line (what a plan will change), plus what the branch has
# changed so far (its commits since it left the integration branch, uncommitted changes, new files).
# The owner's word wins over the paths: --force full|plain, or mode.force in harness.config.yml.
# When it can't decide (no file named and none changed, the integration branch missing, no python3,
# an unknown option), it prints
# `Mode: full` with the reason and exits 2; otherwise it exits 0. Read-only (under the trial it writes one temporary
# git attributes file, removed on exit).
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
risk_by="$(config_get mode.risk_by)"
contained_max="$(config_get mode.contained_max_lines)"
risk_terms="$(config_get mode.risk_terms)"

RISK_FORCE="$force" RISK_MAX="$max" RISK_INTEGRATION="$integration" RISK_PREFIX="$prefix" \
  RISK_BY="$risk_by" RISK_CONTAINED_MAX="$contained_max" RISK_TERMS="$risk_terms" \
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
risk_by = os.environ.get("RISK_BY", "").strip().strip("\"'") or "file"
if risk_by not in ("file", "change"):
    fail(f"mode.risk_by is {risk_by!r}; it takes file or change")
raw_cmax = os.environ.get("RISK_CONTAINED_MAX", "").strip()
contained_max = int(raw_cmax, 10) if raw_cmax.isdigit() else 10
raw_terms = os.environ.get("RISK_TERMS", "").strip()
if risk_by == "change":
    try:
        with open("harness.config.yml", encoding="utf-8-sig") as fh:
            block_list = re.search(r"^[ \t]+risk_terms:[ \t]*(#.*)?$", fh.read(), re.M)
    except OSError:
        block_list = None
    if block_list or (raw_terms and not re.fullmatch(r"\[[^\[\]]*\]|[\w.-]+", raw_terms)):
        fail("mode.risk_terms must be one line: a list such as [team_id, org_id], or one word")
extra_terms = [w.strip().strip("\"'").lower() for w in raw_terms.strip("[]").split(",")]
extra_terms = [w for w in extra_terms if w]
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

# A database file can count as plain when it only adds (harness/MODES.md § Small mode → Additive migration):
# a new .sql migration whose every statement is on the list below, or a database test in a test folder. Only when
# every risk area the file matches is about the database; anything the script can't read stays full.
# A strict allow-list: each statement must match one of the shapes below in full, or the file is not additive.
# Anything the reader is unsure of (prefixed strings, $ outside a $$ body, schemas other than public, a function
# call it doesn't know) makes the migration full. False "full" answers are fine; false "plain" ones are not.

class NotAdditive(Exception):
    pass


def sql_skeleton(text):
    """The statements of an SQL file, each as (skeleton, bodies): string literals become 'S', quoted names become
    plain names ("notes" is notes, "Notes" becomes q_<hex>), $$ bodies become $$Bn$$ with the body kept, and
    comments go. Raises NotAdditive on anything it can't read safely."""
    out, cur, bodies, i, n = [], [], [], 0, len(text)
    def ident_char(c):
        return c.isalnum() or c in "_$"
    while i < n:
        c = text[i]
        if text.startswith("--", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
            continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2)
            if j < 0 or "/*" in text[i + 2:j]:
                raise NotAdditive("a block comment it can't read")
            cur.append(" ")
            i = j + 2
            continue
        if c == "'":
            if i and (ident_char(text[i - 1]) or text[i - 1] == "&"):
                raise NotAdditive("a prefixed string (E'', U&'' or similar)")
            j = i + 1
            while True:
                if j >= n:
                    raise NotAdditive("a string that doesn't end")
                if text[j] == "\\":
                    raise NotAdditive("a backslash in a string")  # read as an escape when standard_conforming_strings is off
                if text[j] == "'":
                    if j + 1 < n and text[j + 1] == "'":
                        j += 2
                        continue
                    break
                j += 1
            cur.append("'S'")
            i = j + 1
            continue
        if c == '"':
            j = text.find('"', i + 1)
            if j < 0 or text.startswith('""', j):
                raise NotAdditive("a quoted name it can't read")
            name = text[i + 1:j]
            cur.append(name if re.fullmatch(r"[a-z_][a-z0-9_]*", name) else "q_" + name.encode().hex())
            i = j + 1
            continue
        if c == "$":
            if text.startswith("$$", i) and not (i and ident_char(text[i - 1])):
                j = text.find("$$", i + 2)
                if j < 0:
                    raise NotAdditive("a $$ body that doesn't end")
                cur.append(f"$$B{len(bodies)}$$")
                bodies.append(text[i + 2:j])
                i = j + 2
                continue
            raise NotAdditive("a $ outside a $$ body")
        if c == ";":
            s = " ".join("".join(cur).lower().split())
            if s:
                out.append((s, list(bodies)))
            cur, bodies = [], []
            i += 1
            continue
        cur.append(c)
        i += 1
    s = " ".join("".join(cur).lower().split())
    if s:
        out.append((s, list(bodies)))
    return out


IDENT = r"[a-z_][a-z0-9_]*"
QNAME = rf"(?:{IDENT}\.)?{IDENT}"
# Functions an expression may call: plain value functions that read nothing but their arguments (and the
# session's user id), so a default, a check or a policy built from them can't change or copy other data.
SAFE_CALLS = {"length", "char_length", "character_length", "octet_length", "cardinality", "array_length", "lower",
              "upper", "btrim", "trim", "ltrim", "rtrim", "coalesce", "nullif", "greatest", "least", "now",
              "gen_random_uuid", "uuid_generate_v4", "auth.uid", "auth.jwt", "auth.role", "unnest", "abs",
              "round", "floor", "ceil", "date_trunc", "position", "substring", "starts_with", "jsonb_typeof",
              "array_position", "to_tsvector", "regexp_like", "string_to_array", "array_to_string",
              "regexp_replace", "split_part", "concat"}
KEYWORDS = {"in", "any", "all", "some", "exists", "array", "and", "or", "not", "check", "values", "row", "using",
            "with", "key", "unique", "references", "primary", "on", "where", "select", "from", "as", "is", "then",
            "else", "when", "case", "filter", "over", "distinct", "between", "like", "ilike", "similar", "default",
            "null", "foreign", "include", "constraint"}
TYPE_CALLS = {"varchar", "character varying", "char", "character", "numeric", "decimal", "time", "timestamp",
              "timestamptz", "interval", "bit", "varbit", "float"}
SENSITIVE = re.compile(r"(user|account|auth|session|token|password|secret|credential|billing|payment|invoice|"
                       r"subscription|charge|price|plan|role|permission|member|admin|key|grant|policy|owner)")
LITERAL = r"(?:'s'|-?\d+(?:\.\d+)?|true|false|null|current_timestamp|current_date)(?:\s*::\s*[a-z_ ]+(?:\[\])?)?"


def full_name(name):
    """public.notes and notes are the same table; another schema is never additive."""
    schema, _, table = name.rpartition(".")
    if schema and schema != "public":
        raise NotAdditive(f"a table outside the public schema ({name})")
    return table


def balanced(s):
    depth = 0
    for c in s:
        depth += (c == "(") - (c == ")")
        if depth < 0:
            return False
    return depth == 0


def calls_ok(expr, funcs, extra=()):
    for m in re.finditer(r"([a-z_][a-z0-9_.]*)\s*\(", expr):
        f = m.group(1)
        if f in KEYWORDS or f in SAFE_CALLS or f in funcs or f in extra:
            continue
        raise NotAdditive(f"a call to {f}()")


def split_top(s):
    out, depth, cur = [], 0, []
    for c in s:
        depth += (c == "(") - (c == ")")
        if c == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
            continue
        cur.append(c)
    out.append("".join(cur).strip())
    return [a for a in out if a]


def additive(text, others=""):
    """None when the migration only adds; otherwise why not, in a few words. others: the project's other SQL,
    where a function the migration creates must not be named yet (a new overload can take over an existing call)."""
    try:
        stmts = sql_skeleton(text)
        if not stmts:
            return "no SQL statement"
        new, rls, funcs = set(), set(), set()
        for s, bodies in stmts:
            add_statement(s, bodies, new, rls, funcs)
        for f in sorted(funcs):
            if "." not in f and others is None:
                return "can't read the project's other SQL to check the function names"
            if "." not in f and re.search(rf"(?<![\w$]){re.escape(f)}\"?\s*\(", others, re.I):
                return f"a function named like one the project already has or calls ({f})"
        open_tables = sorted(new - rls)
        if open_tables:
            return f"new table {open_tables[0]} has no row-level security"
        return None
    except NotAdditive as e:
        return str(e)


def short(s):
    return s[:70] + ("…" if len(s) > 70 else "")


def add_statement(s, bodies, new, rls, funcs):
    if s in ("begin", "commit", "begin transaction", "start transaction", "commit transaction"):
        return
    m = re.fullmatch(rf"create table ({QNAME}) \((.*)\)", s)
    if m:
        table, body = full_name(m.group(1)), m.group(2)
        if not balanced(body) or re.search(r"\b(select|like|inherits|partition|including|generated)\b", body):
            raise NotAdditive(short(s))
        if SENSITIVE.search(table):
            raise NotAdditive(f"a table named for sign-in, secrets, money or permissions ({table})")
        calls_ok(body, funcs, TYPE_CALLS)
        new.add(table)
        return
    m = re.fullmatch(rf"alter table (?:only )?({QNAME}) (?:enable|force) row level security", s)
    if m:
        table = full_name(m.group(1))
        if table not in new:
            raise NotAdditive(f"row-level security turned on for a table it doesn't create ({table})")
        rls.add(table)
        return
    m = re.fullmatch(rf"alter table (?:only )?({QNAME}) (add .*)", s)
    if m:
        table = full_name(m.group(1))
        if SENSITIVE.search(table):
            raise NotAdditive(f"a table named for sign-in, secrets, money or permissions ({table})")
        for action in split_top(m.group(2)):
            add_action(action, table in new, funcs)
        return
    m = re.fullmatch(rf"create (?:unique )?index (?:concurrently )?(?:if not exists )?{IDENT} on (?:only )?({QNAME})"
                     rf"(?: using {IDENT})? \((.*)\)(?: where (.*))?", s)
    if m:
        full_name(m.group(1))
        expr = m.group(2) + " " + (m.group(3) or "")
        if not balanced(m.group(2)) or re.search(r"\bselect\b", expr):
            raise NotAdditive(short(s))
        calls_ok(expr, funcs)
        return
    m = re.fullmatch(rf"create policy {IDENT} on ({QNAME})(?: as (?:permissive|restrictive))?"
                     rf"(?: for (?:all|select|insert|update|delete))? to ({IDENT}(?:, ?{IDENT})*)(.*)", s)
    if m:
        table, roles, rest = full_name(m.group(1)), {r.strip() for r in m.group(2).split(",")}, m.group(3)
        if table not in new:
            raise NotAdditive(f"a policy on a table it doesn't create ({table})")
        if roles & {"public", "anon"}:
            raise NotAdditive("a policy for public or anon")
        parts = re.fullmatch(r"(?: using \((.*?)\))?(?: with check \((.*)\))?", rest)
        if not parts or not (parts.group(1) or parts.group(2)):
            raise NotAdditive(short(s))
        for expr in (parts.group(1), parts.group(2)):
            if expr is None:
                continue
            if not balanced(expr) or re.sub(r"[()\s]", "", expr) in ("true", "1=1", "'s'='s'", "notfalse"):
                raise NotAdditive("a policy that lets every row through")
            calls_ok(expr, funcs)
        return
    m = re.fullmatch(rf"grant ((?:select|insert|update|delete|all(?: privileges)?)(?:, ?(?:select|insert|update|delete))*)"
                     rf" on (?:table )?({QNAME}) to ({IDENT}(?:, ?{IDENT})*)", s)
    if m:
        if full_name(m.group(2)) not in new:
            raise NotAdditive(f"a grant on a table it doesn't create ({m.group(2)})")
        if {r.strip() for r in m.group(3).split(",")} & {"public", "anon"}:
            raise NotAdditive("a grant to public or anon")
        return
    m = re.fullmatch(rf"create function ({QNAME}) ?\(([^()]*)\) returns ([a-z_ \[\]]+?) (.*?)as \$\$b(\d+)\$\$(.*)", s)
    if m:
        name = m.group(1)
        if SENSITIVE.search(full_name(name)):
            raise NotAdditive(f"a function named for sign-in, secrets, money or permissions ({name})")
        header = (m.group(4) + " " + m.group(6)).split()
        allowed = {"language", "sql", "immutable", "stable", "strict", "parallel", "safe", "set", "search_path",
                   "=", "to", "'s'", "public", "returns", "null", "on", "input", "called"}
        words = set(header)
        if not words <= allowed or "sql" not in words or not words & {"immutable", "stable"}:
            raise NotAdditive("a function that isn't a stable or immutable SQL function")
        body = bodies[int(m.group(5))]
        clean = " ".join(re.sub(r"'(?:[^']|'')*'", "'s'", body.lower()).split())
        if not clean.startswith("select ") or ";" in clean.rstrip("; ") or re.search(
                r"\b(insert|update|delete|merge|copy|call|truncate|drop|alter|grant|revoke|create|set|perform|execute|do)\b", clean):
            raise NotAdditive("a function body that does more than select")
        calls_ok(clean, funcs)
        funcs.add(full_name(name))  # called as f() or public.f(), never another schema's f()
        funcs.add("public." + full_name(name))
        return
    if re.fullmatch(rf"comment on (?:table|column) {QNAME}(?:\.{IDENT})? is 's'", s):
        return
    raise NotAdditive(short(s))


def add_action(a, on_new, funcs):
    m = re.fullmatch(rf"add (?:column )?(?:if not exists )?({IDENT}) (.*)", a)
    if m and m.group(1) not in ("constraint", "primary", "unique", "foreign", "check"):
        col, rest = m.group(1), m.group(2)
        if SENSITIVE.search(col):
            raise NotAdditive(f"a column named for sign-in, secrets, money or permissions ({col})")
        if re.search(r"\b(generated|select|collate)\b", rest) or re.search(r"\bon (delete|update)\b", rest):
            raise NotAdditive(short(a))
        for d in re.finditer(r"\bdefault\s+", rest):
            if not re.match(LITERAL, rest[d.end():]):
                raise NotAdditive("a default that isn't a plain value")
        calls_ok(re.sub(r"\bdefault\s+" + LITERAL, "", rest), funcs, TYPE_CALLS)
        return
    m = re.fullmatch(rf"add constraint {IDENT} check \((.*)\)", a)
    if m:
        if not balanced(m.group(1)) or re.search(r"\bselect\b", m.group(1)):
            raise NotAdditive(short(a))
        calls_ok(m.group(1), funcs)
        return
    if re.fullmatch(rf"add constraint {IDENT} unique \({IDENT}(?:, ?{IDENT})*\)", a):
        return
    m = re.fullmatch(rf"add constraint {IDENT} foreign key \({IDENT}(?:, ?{IDENT})*\) references ({QNAME})"
                     rf"(?: ?\({IDENT}(?:, ?{IDENT})*\))?(.*)", a)
    if m:
        if m.group(2).strip() and (not on_new or not re.fullmatch(r"( on delete (cascade|restrict|no action|set null))?", m.group(2))):
            raise NotAdditive(short(a))
        return
    raise NotAdditive(short(a))

# An area counts as the database's when its name says so and names nothing else a risk path guards.
DB_AREA = re.compile(r"database|schema|migration|\bsql\b", re.I)
NOT_DB_AREA = re.compile(r"auth|sign|session|access|billing|money|payment|secret|permission|policy|polic|tenan", re.I)
# A database test lives in a test folder, never next to the migrations (a .sql file there is applied).
SQL_TEST = re.compile(r"(^|/)(tests?|spec)/[^ ]*\.sql$", re.I)

def other_sql(p):
    """The project's SQL as the integration branch has it, as one text: what existed before this change."""
    if base is None or base == EMPTY_TREE:
        return ""
    listing = git("ls-tree", "-r", "-z", "--name-only", base)
    if listing is None:
        return None
    out = []
    for q in listing.split("\0"):
        if q.lower().endswith(".sql") and q != p:
            text = git("show", f"{base}:{q}")
            if text is None:
                return None
            out.append(text)
    return "\n".join(out)

def is_new(p):
    """Not in the integration branch yet: the branch adds it, or it is still untracked."""
    if base == EMPTY_TREE:
        return True
    if base is None:
        return False  # no git history to compare with: never counted as new
    return git("cat-file", "-e", f"{base}:{p}") is None

# mode.risk_by: change (a trial, harness/MODES.md § Contained change): an ordering or paging edit to a risk-path file.
# An allow-list, like the additive migration's: every changed line must be one of the shapes below, so a change to
# who sees what never fits (two reviews showed that a list of risky words can't be made safe). As a second guard
# the whole function around each change (git diff -W) must have no word from the risk list. False "full" answers
# are fine; false "plain" ones are not.
ORDER_CALL = re.compile(r"\s*\.?(order|orderBy|order_by|thenBy|thenByDescending|sort|sortBy|sort_by|range|limit|"
                        r"offset|take|skip|reverse|desc|asc|nullsLast|nulls_last|nullsFirst|nulls_first)\s*"
                        r"\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\)\s*[;,]?\s*")
ARG_OK = re.compile(r"[\w\s\"'`.,:{}\[\]\-+*/%|&<>=!?()]*")   # literals, names, objects, comparators; no ${} or calls checked below
COMMENT_LINE = {"//": ("js", "jsx", "ts", "tsx", "mjs", "cjs", "go", "java", "kt", "cs", "c", "cc", "cpp", "h",
                       "hpp", "rs", "swift", "scala", "dart", "php"),
                "#": ("py", "rb", "sh", "bash", "yml", "yaml", "toml", "ex", "exs", "pl", "pm", "r")}
RISK_TERMS_LONG = ("user", "owner", "auth", "session", "login", "logout", "token", "passw", "secret", "credential",
                   "cookie", "csrf", "permission", "privilege", "access", "admin", "polic", "grant", "revoke",
                   "tenant", "member", "account", "team", "workspace", "visib", "public", "private", "share",
                   "allow", "deny", "forbid", "guard", "scope", "bearer", "apikey", "privatekey", "email", "billing",
                   "payment", "invoice", "charge", "price", "subscription", "refund", "amount", "discount", "credit",
                   "balance", "cost", "tax", "quota", "delete", "destroy", "remove", "drop", "truncate", "purge",
                   "unlink", "rmtree", "prune", "wipe", "archive", "unscoped", "sudo", "impersonat", "encrypt",
                   "decrypt", "verify", "sign", "role", "redirect", "upload", "creator", "createdby", "viewer",
                   "staff", "moderator", "editor", "collaborator", "invite", "company", "customer", "cannot")
RISK_TERMS_SHORT = ("uid", "jwt", "acl", "rls", "env", "sql", "raw", "exec", "eval", "pwd", "perm", "org", "fee", "mine")
RISK_TERMS_EXACT = {"can", "may", "me", "rm", "del"}
SENSITIVE_AREA = re.compile(r"sign[ -]?in|auth|session|login|password|secret|credential|token|billing|money|payment|"
                            r"price|invoice|subscription|checkout|refund|payout|wallet|stripe|\btax", re.I)
SECRET_LITERAL = re.compile(r"sk_live_|sk_test_|AKIA[0-9A-Z]{12}|-----BEGIN|ghp_|xox[bp]-")

def words(text):
    text = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", text)
    text = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1 \2", text)
    return [w.lower() for w in re.findall(r"[A-Za-z]+", text)]

def flat(text):
    return re.sub(r"[_\-\s]", "", text.lower())

def risky_word(text):
    """The first risk word in a line, or None. Each identifier is read whole (flattened) and split into words; the
    project's terms (mode.risk_terms) match anywhere, with `_`, `-` and spaces ignored."""
    low = flat(text)
    for t in extra_terms:
        if flat(t) in low:
            return t
    if SECRET_LITERAL.search(text):
        return "a secret-shaped literal"
    for ident in re.findall(r"[A-Za-z_$][\w$]*", text):
        whole = flat(ident)
        for w in [whole] + words(ident):
            if w in RISK_TERMS_EXACT:
                return w
            for t in RISK_TERMS_SHORT:
                if w.startswith(t):
                    return w
            for t in RISK_TERMS_LONG:
                if t in w:
                    return w
    return None

def allowed_line(p, text):
    """None when a changed line is blank, a whole-line comment or an ordering or paging call; else why not."""
    ext = p.rsplit(".", 1)[-1].lower() if "." in p.rsplit("/", 1)[-1] else ""
    code = text.strip()
    if not code:
        return None
    for mark, exts in COMMENT_LINE.items():
        if ext in exts and code.startswith(mark) and not code.startswith("#!"):
            return None if mark != "#" or not re.match(r"#\s*(if|ifdef|ifndef|define|include|\[)", code) else "a directive"
    body = code
    if ext in COMMENT_LINE["//"]:
        body = re.sub(r"\s//\s[^\"'`]*$", "", body)  # a trailing comment with no quote in it
    m = ORDER_CALL.fullmatch(body)
    if not m:
        return f"a changed line that isn't ordering or paging (`{short(code)}`)"
    args = body[body.index("(") + 1:body.rindex(")")]
    if "${" in args or "#{" in args or not ARG_OK.fullmatch(args):
        return f"an ordering call with an argument it can't read (`{short(code)}`)"
    if re.search(r"[A-Za-z_$][\w$]*\s*\(", args) and not re.fullmatch(r"\s*\(?\s*\w+\s*,\s*\w+\s*\)?\s*=>.*", args):
        return f"an ordering call that calls something (`{short(code)}`)"
    hit = risky_word(body)
    if hit:
        return f"a changed line is about `{hit}`"
    return None

# git's own diff drivers (git ships these), so a method is found as its own function where the language has one.
DRIVERS = {"py": "python", "rb": "ruby", "go": "golang", "java": "java", "kt": "kotlin", "php": "php", "rs": "rust",
           "cs": "csharp", "cpp": "cpp", "cc": "cpp", "c": "cpp", "h": "cpp", "hpp": "cpp", "ex": "elixir",
           "exs": "elixir", "pl": "perl", "pm": "perl", "m": "objc", "css": "css"}
attrs_file = None

def function_patch(p):
    """The diff of p with each change's whole function (git diff -W). None when it can't be read."""
    global attrs_file
    if attrs_file is None:
        import atexit, tempfile
        try:
            fd, attrs_file = tempfile.mkstemp(prefix="risk-attrs-")
            with os.fdopen(fd, "w") as fh:
                fh.write("".join(f"*.{e} diff={d}\n" for e, d in DRIVERS.items()))
        except OSError:
            return None
        atexit.register(lambda: os.path.exists(attrs_file) and os.remove(attrs_file))
    return git("-c", f"core.attributesFile={attrs_file}", "--literal-pathspecs", "diff", "-W", "--no-renames",
               "--no-color", "--no-ext-diff", "--no-textconv", base, "--", p)

def contained(p, hits):
    """(True, line) when the change to p is contained; (False, why) otherwise; (None, why) when it isn't made yet."""
    areas = [a for a, _ in hits if SENSITIVE_AREA.search(a)]
    if areas:
        return False, f"a sign-in, secrets or money area ({areas[0]})"
    areas = [a for a, _ in hits if DB_AREA.search(a)]
    if areas:
        return False, f"a database area ({areas[0]}): only a migration that adds counts there"
    if base is None or base == EMPTY_TREE or is_new(p):
        return False, "a new file"
    if not os.path.isfile(p):
        return False, "the branch deletes it"
    if p not in changed:
        return None, "not changed yet"
    patch = function_patch(p)
    if patch is None:
        return False, "git diff failed"
    if "\nBinary files " in patch or "\nGIT binary patch" in patch:
        return False, "a binary file"
    ext = p.rsplit(".", 1)[-1].lower() if "." in p.rsplit("/", 1)[-1] else ""
    count, body, in_block = 0, False, False
    for line in patch.split("\n"):
        if line.startswith("@@"):
            body, in_block = True, False  # with -W the hunk holds the whole function; the header names the one before it
            continue
        if not body or not line or line.startswith("\\"):
            continue
        sign, text = line[0], line[1:]
        if sign in "+-":
            count += 1
            why = allowed_line(p, text)
            if why:
                return False, why
            continue
        # an unchanged line of the same function: comments run nothing, the code around them is read
        code = text.strip()
        if in_block or code.startswith("/*"):
            in_block = "*/" not in code
            continue
        if any(ext in exts and code.startswith(mark) for mark, exts in COMMENT_LINE.items()) and not re.match(r"#\s*(if|ifdef|ifndef|define|include|\[)", code):
            continue
        hit = risky_word(text)
        if hit:
            return False, f"a line in the same function is about `{hit}`"
    if count == 0:
        return False, "no line changes (a mode or rename only)"
    if count > contained_max:
        return False, f"{count} lines change, more than mode.contained_max_lines ({contained_max})"
    return True, f"ordering or paging only ({count} line{'s' if count != 1 else ''}; no word from the risk check's list in its functions)"

reasons, additions, unwritten = [], [], []
contained_lines, unwritten_code = [], []
for p in files:
    hits = [(area, g) for area, g, rx in compiled if rx.match(p)]
    if not hits:
        continue
    reason = f"- {p}: {hits[0][0]} (`{hits[0][1]}`)"
    if risk_by == "change" and not p.lower().endswith(".sql"):
        ok, why = contained(p, hits)
        if ok:
            contained_lines.append((reason, f"~ {p}: {why}"))
        elif ok is None:
            unwritten_code.append(p)
            reasons.append(reason)
        else:
            reasons.append(f"{reason}: not contained ({why})")
        continue
    if not p.lower().endswith(".sql") or not all(DB_AREA.search(area) and not NOT_DB_AREA.search(area) for area, _ in hits):
        reasons.append(reason)
        continue
    if SQL_TEST.search(p) and "migration" not in p.lower():
        additions.append((reason, f"+ {p}: database test"))
        continue
    if not os.path.isfile(p):
        if p in changed:
            reasons.append(reason + ": the branch deletes it")
        else:
            unwritten.append(p)
            reasons.append(reason)
        continue
    if not is_new(p):
        reasons.append(reason + ": changes a migration the integration branch already has")
        continue
    try:
        with open(p, encoding="utf-8-sig", errors="replace") as fh:
            more = additive(fh.read(), other_sql(p))
    except OSError:
        more = "can't read it"
    if more:
        reasons.append(reason + f": does more than add ({more})")
    else:
        additions.append((reason, f"+ {p}: additive migration (new tables with row-level security, new columns)"))

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

# Under the trial the area names decide too, and scripts/lib/config.sh reads the switch, so any change to either
# is a reason; turning the trial on, or changing how it judges, is the owner's call in a change of its own.
if risk_by == "change" and base and base != EMPTY_TREE:
    def section(text):
        m = re.search(r"^## Risk paths[ \t]*$(.*?)(?=^## |\Z)", text or "", re.M | re.S)
        return m.group(1).strip() if m else ""
    if "project/CONTROLS.md" in files and section(git("show", f"{base}:project/CONTROLS.md")) != section(controls):
        reasons.append("- project/CONTROLS.md changes § Risk paths: its area names decide what a contained change may touch")
    if "scripts/lib/config.sh" in files:
        reasons.append("- scripts/lib/config.sh: it reads the risk check's settings")
    if ".gitattributes" in files:
        reasons.append("- .gitattributes: it can change how the risk check reads a function")
if risk_by == "change" and base and base != EMPTY_TREE and "harness.config.yml" in files:
    before_cfg = git("show", f"{base}:harness.config.yml") or ""
    def cfg_before(key):
        try:
            r = subprocess.run(["bash", "-c", '. scripts/lib/config.sh && config_get "$1" /dev/stdin', "_", key],
                               input=before_cfg.encode(), capture_output=True, timeout=20)
            return r.stdout.decode("utf-8", "replace").strip()
        except (OSError, subprocess.TimeoutExpired):
            return None
    for key, now in (("mode.risk_by", os.environ.get("RISK_BY", "")), ("mode.contained_max_lines", raw_cmax),
                     ("mode.risk_terms", os.environ.get("RISK_TERMS", ""))):
        if cfg_before(key) != now.strip():
            reasons.append(f"- harness.config.yml changes {key}: how the risk check judges a change")

counted = [p for p in files if not is_record(p)]
if len(counted) > max_files:
    reasons.append(f"- {len(counted)} files change, more than mode.plain_max_files ({max_files}), documentation not counted")

only_unwritten = bool(unwritten_code) and not unwritten and len(reasons) == len(unwritten_code)
auto = "full" if reasons else "plain"
if auto == "full" or force == "full":
    # anything else already needs full mode, or the owner chose it: the database files are risk paths again
    reasons = [r for r, _ in additions + contained_lines] + reasons
    additions, contained_lines = [], []
if force and force != auto:
    print(f"Mode: {force} (the owner chose {force}; without that: {auto})")
elif force:
    print(f"Mode: {force} (the owner chose {force})")
elif auto == "plain" and not counted:
    print("Mode: plain (documentation only)")
elif auto == "plain" and additions:
    print(f"Mode: plain ({len(counted)} file{'s' if len(counted) != 1 else ''}, database changes that only add)")
elif auto == "plain" and contained_lines:
    print(f"Mode: plain ({len(counted)} file{'s' if len(counted) != 1 else ''}, risk-path changes that stay contained)")
elif auto == "plain":
    print(f"Mode: plain ({len(counted)} file{'s' if len(counted) != 1 else ''}, none on a risk path)")
else:
    print("Mode: full")
for r in reasons:
    print(r)
for _, line in additions + contained_lines:
    print(line)
if additions:
    print("Needs: the database tests and one code review before the hand-off (harness/MODES.md § Small mode)")
if contained_lines:
    print("Needs: one code review before the hand-off, and this run again with no files then (harness/MODES.md § Contained change)")
if unwritten and auto == "full":
    print("Note: " + ", ".join(unwritten) + " isn't written yet. A new migration that only adds tables or columns with "
          "row-level security can run in small mode: write it first, then run this again (harness/MODES.md § Choosing mode)")
if only_unwritten and force != "full":
    print("Note: " + ", ".join(unwritten_code) + " isn't changed yet. With mode.risk_by: change, an ordering or paging "
          f"edit there (order, sort, limit or range calls, at most {contained_max} lines) can run in small mode: make it "
          "first, then run this again (harness/MODES.md § Contained change)")
PY
