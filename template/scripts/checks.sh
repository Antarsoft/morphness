#!/usr/bin/env bash
# Runs named checks as code and records their results, so a run where every check passes costs no model
# turn (harness/CONTROLS.md § End-of-task checks).
#
# Usage: bash scripts/checks.sh run <check> ...   run these named checks now and record them
#        bash scripts/checks.sh status            the recorded results for the working tree as it is now
#        bash scripts/checks.sh hook              the end-of-task hook (.claude/settings.json → Stop, and
#                                                 SubagentStop for the Full-stack agents); reads its JSON on stdin
#
# The hook runs the checks in harness.config.yml → checks.on_stop when the code differs from the integration
# branch and from the last tree they ran on. Documentation-only changes (harness/CONTROLS.md § Documentation
# paths) don't count, so the Technical Lead's record edits never rerun them. When every check passes it exits 0
# and prints nothing: the turn ends with no model turn spent. When one fails it exits 2 with the check, its exit
# code and the end of its log, which sends the agent back to fix it. A fix that still fails sends it back again, at
# most checks.stop_retries times in a row; a stop with no code change since the failure (the agent says the failure
# isn't its change, or another agent already got it) isn't sent back. Either way the failure stays on record. A main chat Stop while background tasks still run is
# skipped: their own end runs the checks on the finished code.
#
# Commands come from project/CONTROLS.md § Named checks as committed on the integration branch (origin/<branch>
# first), never from the working copy: the hook runs outside the guard, so a command it runs has been merged by
# the human first. A check whose cell is not one plain `command`, or that has no row, is recorded as not run.
# § End-of-task checks → **Run through:** names a wrapper or lock command each check runs inside.
#
# Results live in the git folder (<git common dir>/morphness/checks/<code key>/), keyed by the content of every
# file that isn't documentation, so a record is found again from any worktree with the same code. A secret
# scan's log is never printed.
# Exit codes: run and status: 0 when every check named (status: every on_stop check) passed on this code, 1
# otherwise; hook: 0, or 2 to send the agent back; 2 also for a usage error. A missing tool or an unreadable
# config makes the hook exit 0 silently: these checks are evidence, not a guard, and the merge gate still
# needs a pass on record.

case "${1:-}" in
  run|status|hook) ;;
  *) echo "usage: bash scripts/checks.sh run <check> ... | status | hook" >&2; exit 2 ;;
esac
mode="$1"; shift
if [ "$mode" = run ] && [ $# -eq 0 ]; then
  echo "usage: bash scripts/checks.sh run <check> ...   (names from harness.config.yml → checks)" >&2; exit 2
fi
quiet_exit() { [ "$mode" = hook ] && exit 0; echo "Checks: $1" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || quiet_exit "python3 is missing"
command -v git >/dev/null 2>&1 || quiet_exit "git is missing"
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib/config.sh" 2>/dev/null || quiet_exit "scripts/lib/config.sh is missing or unreadable"
hook_input=""
if [ "$mode" = hook ]; then
  hook_input="$(cat)"
  # Run where the agent worked: a Full-stack agent in its own worktree ends with its cwd there.
  hook_cwd="$(printf '%s' "$hook_input" | python3 -I -c 'import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("cwd", "") if isinstance(d, dict) else "")
except Exception:
    pass' 2>/dev/null)"
  if [ -n "$hook_cwd" ] && [ -d "$hook_cwd" ]; then cd "$hook_cwd" 2>/dev/null || true; fi
fi
export GIT_OPTIONAL_LOCKS=0   # never take the index lock another agent's commit may need
root="$(git rev-parse --show-toplevel 2>/dev/null)" || quiet_exit "not inside a git repository"
cd "$root" || quiet_exit "cannot enter the project folder"

CHECKS_MODE="$mode" CHECKS_HOOK_INPUT="$hook_input" \
CHECKS_ON_STOP="$(config_get checks.on_stop)" CHECKS_RETRIES="$(config_get checks.stop_retries)" \
CHECKS_INTEGRATION="$(config_get branches.integration)" \
CHECKS_DOC_ADD="$(config_get checks.doc_paths_add)" CHECKS_DOC_REMOVE="$(config_get checks.doc_paths_remove)" \
  python3 -I - "$@" <<'PY'
import fcntl, hashlib, json, os, re, shutil, signal, subprocess, sys, tempfile, time

mode = os.environ["CHECKS_MODE"]
argv = sys.argv[1:]
started = time.time()
HOOK_BUDGET = 850     # seconds; the hook's own timeout in .claude/settings.json is 900
CHECK_TIMEOUT = 600   # seconds for one check; a check that hangs (a watch mode) is a fail, not a stuck turn

def git(*args, env=None, raw=False):
    try:
        r = subprocess.run(["git", *args], capture_output=True, timeout=120, env=env)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if r.returncode:
        return None
    return r.stdout if raw else r.stdout.decode("utf-8", "replace")

def give_up(why):
    if mode == "hook":
        sys.exit(0)
    print(f"Checks: {why}", file=sys.stderr)
    sys.exit(1)

def names(value):
    value = (value or "").strip()
    if value.startswith("[") and value.endswith("]"):
        value = value[1:-1]
    return [n.strip().strip("\"'") for n in value.split(",") if n.strip().strip("\"'")]

hook = {}
if mode == "hook":
    try:
        hook = json.loads(os.environ.get("CHECKS_HOOK_INPUT") or "{}")
    except ValueError:
        hook = {}
    if not isinstance(hook, dict):
        hook = {}

on_stop = names(os.environ.get("CHECKS_ON_STOP"))
raw_retries = os.environ.get("CHECKS_RETRIES", "").strip()
retries = int(raw_retries, 10) if raw_retries.isdigit() else 2
integ = os.environ.get("CHECKS_INTEGRATION", "").strip() or "dev"
wanted = argv if mode == "run" else on_stop
event = hook.get("hook_event_name", "")
if mode == "hook":
    if not on_stop:
        sys.exit(0)  # checks.on_stop is empty: the owner turned the hook off
    if event == "Stop" and hook.get("background_tasks"):
        sys.exit(0)  # background work is still changing the tree; its own end runs the checks

# A secret scan reads every file, documentation included (harness/CONTROLS.md § Scoping by what changed, item 3).
SECRET_CHECKS = {"secrets"}

# Documentation, as harness/CONTROLS.md § Documentation paths lists it. Files that run or set permissions never count.
DOC_DIRS = ("_harness/", "docs/", "harness/", "project/", ".claude/agents/", ".claude/rules/")
CI_PREFIXES = (".github/workflows/", ".github/actions/", ".gitlab-ci", ".circleci/", ".buildkite/")
# The project's own changes to that list, set in harness.config.yml (checks.doc_paths_add, checks.doc_paths_remove:
# folders ending in `/`, or single files, from the repository root). They live in the config, which agents can't
# write, and not in project/CONTROLS.md, so an edit to a document can't switch a check off for the next change.
def path_list(value):
    return tuple((n[2:] if n.startswith("./") else n).lstrip("/") for n in names(value) if ".." not in n.split("/"))
DOC_ADD = path_list(os.environ.get("CHECKS_DOC_ADD"))
DOC_REMOVE = path_list(os.environ.get("CHECKS_DOC_REMOVE"))
def under(p, listed):
    return any(p == l or (l.endswith("/") and p.startswith(l)) for l in listed)

def is_doc(p):
    if "/../" in "/" + p + "/" or p == "..":
        return False
    if p == ".claude/settings.json" or p.startswith(("scripts/", ".claude/skills/", ".agents/", ".claude/hooks/")):
        return False
    if under(p, DOC_REMOVE):
        return False
    if under(p, DOC_ADD):
        return True
    if p.startswith(DOC_DIRS):
        return True
    if p.split("/")[0].upper().split(".")[0] in ("README", "LICENSE") and "/" not in p:
        return True
    return p.lower().endswith(".md") and not p.startswith(CI_PREFIXES)

def tree_key(tree, docs):
    """A hash of the files in `tree`: every file when `docs`, else every file that isn't documentation."""
    listing = git("ls-tree", "-r", "-z", "--full-tree", tree, raw=True)
    if listing is None:
        return None
    h = hashlib.sha256(b"all\0" if docs else b"code\0")
    for entry in listing.split(b"\0"):
        if not entry:
            continue
        meta, _, path = entry.partition(b"\t")
        if docs or not is_doc(path.decode("utf-8", "replace")):
            h.update(meta + b"\t" + path + b"\0")
    return h.hexdigest()[:20]

def working_tree():
    """The tree the working copy would commit (untracked files included, ignored ones not), without touching the index."""
    index = git("rev-parse", "--git-path", "index")
    tmp = tempfile.mkdtemp(prefix="morph-checks-")
    try:
        tmp_index = os.path.join(tmp, "index")
        if index and os.path.exists(index.strip()):
            shutil.copyfile(index.strip(), tmp_index)
        env = dict(os.environ, GIT_INDEX_FILE=tmp_index)
        if git("add", "-A", "--", ".", env=env) is None:
            return None
        tree = git("write-tree", env=env)
        return tree.strip() if tree else None
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

if git("rev-parse", "-q", "--verify", "HEAD") is None:
    give_up("no commit yet")
tree = working_tree()
keys = {False: tree_key(tree, False), True: tree_key(tree, True)} if tree else {}
if not tree or not all(keys.values()):
    give_up("git could not read the working tree")
def key_of(name):
    return keys[name in SECRET_CHECKS]
head = (git("rev-parse", "HEAD") or "").strip()
porcelain = git("status", "--porcelain", "--untracked-files=normal")
clean = porcelain is not None and porcelain.strip() == ""   # git failing counts as dirty; empty output is clean

ref = None
for cand in (f"origin/{integ}", integ):
    if git("rev-parse", "-q", "--verify", cand + "^{commit}"):
        ref = cand
        break
unchanged = set()   # checks whose files match the integration branch: nothing to check
if mode == "hook":
    base = (git("merge-base", "HEAD", ref) or "").strip() if ref else ""
    if base:
        for docs in (False, True):
            if tree_key(base + "^{tree}", docs) == keys[docs]:
                unchanged |= {n for n in wanted if (n in SECRET_CHECKS) == docs}
    if all(n in unchanged for n in wanted):
        sys.exit(0)

common = (git("rev-parse", "--git-common-dir") or "").strip()
if not common:
    give_up("no git folder")
store = os.path.join(os.path.abspath(common), "morphness", "checks")
try:
    os.makedirs(store, exist_ok=True)
except OSError:
    give_up(f"cannot write {store}")

def rec_path(name, ext):
    return os.path.join(store, key_of(name), name + ext)

def load(name):
    try:
        with open(rec_path(name, ".json"), encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return None

def commands():
    """Named check → command, from project/CONTROLS.md as committed on the integration branch."""
    if not ref:
        return {}, None, f"no branch {integ} or origin/{integ} (harness.config.yml → branches.integration)"
    text = git("show", f"{ref}:project/CONTROLS.md")
    if text is None:
        return {}, None, f"project/CONTROLS.md is not on {ref} yet"
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    cmds = {}
    section = re.search(r"^## Named checks[ \t]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    # A table cell spells a `|` as `\|`, inside backticks too (GitHub tables need it), so `a \|\| b` is `a || b`.
    for m in re.finditer(r"^\|\s*`([a-z0-9-]+)`\s*\|((?:[^|\\\n]|\\.)*)\|", section.group(1) if section else "", re.M):
        cell = m.group(2).strip().replace("\\|", "|")
        plain = re.fullmatch(r"`([^`]+)`", cell)
        cmds[m.group(1)] = plain.group(1) if plain and "{{" not in plain.group(1) else None
    through = None
    sec = re.search(r"^## End-of-task checks[ \t]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    if sec:
        t = re.search(r"^\*\*Run through:\*\*[ \t]*`([^`\n]+)`[ \t]*$", sec.group(1), re.M)
        through = t.group(1).strip() if t else None
    return cmds, through, None

cmds, through, why_none = commands()

def full_command(name):
    cmd = cmds.get(name)
    return (f"{through} {cmd}" if through else cmd) if cmd else None

def current(rec, name):
    """A record counts only while its command is the one the integration branch has now."""
    if rec is None or rec.get("result") == "not run":
        return None
    return rec if rec.get("command") == full_command(name) else None

def write_json(path, data):
    tmp = path + f".{os.getpid()}.tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data, fh)
    os.replace(tmp, path)

def run_check(name):
    rec = {"check": name, "head": head, "clean": clean, "at": time.strftime("%Y-%m-%d %H:%M"), "from": ref}
    cmd = full_command(name)
    os.makedirs(os.path.join(store, key_of(name)), exist_ok=True)
    if why_none:
        rec.update(result="not run", why=why_none)
    elif name not in cmds:
        rec.update(result="not run", why=f"no row for `{name}` in project/CONTROLS.md § Named checks on {ref}")
    elif not cmd:
        rec.update(result="not run", why=f"the `{name}` cell in project/CONTROLS.md is not one plain command")
    else:
        log = rec_path(name, ".log")
        limit = CHECK_TIMEOUT if mode != "hook" else max(1, min(CHECK_TIMEOUT, HOOK_BUDGET - (time.time() - started)))
        start = time.time()
        with open(log + ".part", "wb") as fh:
            try:
                p = subprocess.Popen(["bash", "-c", cmd], stdout=fh, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                                     start_new_session=True)
                try:
                    code = p.wait(timeout=limit)
                except subprocess.TimeoutExpired:
                    os.killpg(p.pid, signal.SIGKILL)
                    p.wait()
                    fh.write(f"\nchecks.sh: stopped after {round(limit)}s (a check that waits forever, such as a watch mode, fails)\n".encode())
                    code = 124
            except OSError as e:
                fh.write(f"could not start: {e}\n".encode())
                code = 127
        os.replace(log + ".part", log)
        rec.update(result="pass" if code == 0 else "fail", exit=code, command=cmd,
                   seconds=round(time.time() - start), log=log)
    write_json(rec_path(name, ".json"), rec)
    return rec

def tail(rec, n=20):
    if rec["check"] in SECRET_CHECKS:
        return "(log not shown: it may hold a secret. Open it only to find the file, line and rule; never paste the value.)"
    try:
        with open(rec["log"], encoding="utf-8", errors="replace") as fh:
            lines = fh.read().splitlines()
    except (OSError, KeyError):
        return "(no log)"
    return "\n".join(lines[-n:])

def shown_path(p):
    rel = os.path.relpath(p, os.getcwd()) if p else ""
    return rel if rel and not rel.startswith("..") else p

def describe(rec):
    if rec is None:
        return "not recorded"
    if rec["result"] == "not run":
        return f"not run: {rec.get('why', '')}"
    return f"{rec['result']} (exit {rec['exit']}, {rec.get('seconds', 0)}s, {rec.get('at', '')}, log {shown_path(rec.get('log', ''))})"

if mode == "status":
    state = "clean" if clean else "uncommitted changes"
    print(f"Checks for code {keys[False]} (HEAD {head[:7]}, {state}; commands from {ref or 'nowhere'}):")
    seen = []
    for k in dict.fromkeys(keys.values()):
        d = os.path.join(store, k)
        seen += sorted(f[:-5] for f in os.listdir(d) if f.endswith(".json") and not f.startswith(".")) if os.path.isdir(d) else []
    shown = list(dict.fromkeys(on_stop + seen))
    width = max([len(n) for n in shown] + [5])
    ok = True
    for n in shown:
        raw = load(n)
        rec = current(raw, n) or (raw if raw and raw.get("result") == "not run" else None)
        note = "" if rec or raw is None else " (an older command ran; it reruns at the next end of task)"
        print(f"  {n.ljust(width)}  {describe(rec)}{note}")
        if n in on_stop and (rec is None or rec["result"] != "pass"):
            ok = False
        if rec and rec.get("changed"):
            print(f"  {' ' * width}  note: the run changed {', '.join(rec['changed'][:5])}; ignore them in .gitignore or the key moves")
    if not shown:
        print("  nothing recorded (harness.config.yml → checks.on_stop is empty)")
    sys.exit(0 if ok and shown else 1)

lock_fh = open(os.path.join(store, ".lock"), "w")
fcntl.flock(lock_fh, fcntl.LOCK_EX)   # one run at a time: two agents ending on the same code share one result

def note_changes(recs):
    """A check that writes files git doesn't ignore moves the key. Name them, and file the results under the new
    key too (they ran on this code plus their own output), so the next end of task doesn't run them again."""
    after = working_tree()
    if not after or after == tree:
        return
    moved = [p for p in (git("diff", "--name-only", "--no-renames", tree, after) or "").splitlines() if p]
    new_keys = {False: tree_key(after, False), True: tree_key(after, True)}
    for r in recs:
        if r.get("result") in ("pass", "fail"):
            r["changed"] = moved
            write_json(rec_path(r["check"], ".json"), r)
            k = new_keys[r["check"] in SECRET_CHECKS]
            if k:
                os.makedirs(os.path.join(store, k), exist_ok=True)
                write_json(os.path.join(store, k, r["check"] + ".json"), r)

if mode == "run":
    odd = [n for n in wanted if not re.fullmatch(r"[a-z0-9-]+", n)]
    if odd:
        # A path after the check names (run unit src/a.test.ts) is not a check. A record is for the whole check, so
        # a run on part of it can't count; say how to run part of it instead.
        unit = cmds.get("unit") or "<the unit command>"
        print(f"checks.sh: {', '.join(odd)} is not a check name; run takes only named checks (harness.config.yml → "
              f"checks, project/CONTROLS.md § Named checks), and runs each one whole. To run one test file, run the "
              f"named command with the path (`{unit} -- {odd[0]}`) or the test runner's own form (`npx jest "
              f"{odd[0]}`); that run is not a record for the merge gate.", file=sys.stderr)
        sys.exit(2)
    ok, ran = True, []
    for n in wanted:
        rec = run_check(n)
        ran.append(rec)
        print(f"{n}: {describe(rec)}")
        if rec["result"] != "pass":
            ok = False
            if rec["result"] == "fail":
                print(tail(rec, 30))
    note_changes(ran)
    sys.exit(0 if ok else 1)

# mode == "hook": run what this code has no current record for, then pass or send the agent back.
recs, ran, fresh = [], [], False
for n in wanted:
    if n in unchanged:
        continue
    rec = current(load(n), n)
    if rec is None:
        rec = run_check(n)
        ran.append(rec)
        fresh = fresh or rec["result"] == "fail"
    recs.append(rec)
note_changes(ran)
failed = [r for r in recs if r["result"] == "fail"]
who = re.sub(r"[^A-Za-z0-9_.-]", "_", f"{hook.get('session_id', 'session')}-{hook.get('agent_id') or 'main'}")
counter = os.path.join(store, ".blocks-" + who)
def clear():
    try:
        os.remove(counter)
    except OSError:
        pass
summary = ", ".join(f"{r['check']} ({'timed out' if r['exit'] == 124 else 'exit ' + str(r['exit'])})" for r in failed)
on_record = (f"End-of-task checks fail: {summary}. The failure is on record (bash scripts/checks.sh status); "
             "the merge gate needs it fixed.")
if not failed:
    clear()
    sys.exit(0)
if not fresh:
    # The same code failed before: this agent stopped again without a change, or another agent already got the
    # failure. Sending it back again would only repeat the message.
    if hook.get("stop_hook_active"):
        print(json.dumps({"systemMessage": on_record}))
    clear()
    sys.exit(0)
count = 0
if hook.get("stop_hook_active"):
    try:
        with open(counter, encoding="utf-8") as fh:
            count = int(fh.read().strip() or 0)
    except (OSError, ValueError):
        count = 0
count += 1
if count > retries:
    clear()
    print(json.dumps({"systemMessage": f"{on_record} It still failed after {retries} fixes."}))
    sys.exit(0)
with open(counter, "w", encoding="utf-8") as fh:
    fh.write(str(count))
fix = ("Fix the cause, or in full mode hand it to Full-stack (harness/TECHNICAL_LEAD.md), and finish again"
       if event == "Stop" else "Fix the cause and finish again")
msg = [f"End-of-task checks failed: {summary} (scripts/checks.sh, harness/CONTROLS.md § End-of-task checks).",
       f"{fix}: the checks rerun once the code changes. When the failure is not this change's (it fails the same "
       "way on the integration branch), say so in your reply with the check and the log line; finishing with no "
       "code change doesn't send you back again."]
for r in failed:
    msg.append(f"--- {r['check']}: `{r['command']}`, log {shown_path(r['log'])} ---")
    msg.append(tail(r))
print("\n".join(msg), file=sys.stderr)
sys.exit(2)
PY
