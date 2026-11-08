#!/usr/bin/env python3
"""Driver for the autonomous module (harness/modules/autonomous/README.md). Started through scripts/auto/run.sh,
never by an agent. It keeps the live run state in the git folder (.git/morphness/auto/), starts one headless
Claude Code session per step (director, feature, prune), checks each feature's card against the feature's own
records, merges passed features into the run branch, and redraws the tracker. Standard library only.

Commands (run.sh passes them through):
  start      check the brief and budgets, create the run branch, run the director, check the order
             (after a failed director, start tries again on the same branch)
  approve    record the owner's approval of docs/product/
  run        build features until the run ends or exits
  resume     after an exit, or with features waiting on the owner: fresh tries, budget and clock, then run
  status     print the tracker and spend
  stop       ask a running driver to exit after the current step
  card FILE  check one card file and print it as JSON (card.sh)
  tracker    redraw _harness/auto/tracker.md (tracker.sh)
Exit codes: 0 done or waiting for the owner's next step; 1 the run exited (see _harness/auto/exit.md) or the
driver hit an error; 2 a usage error or a check that refused to start.
"""
import datetime
import json
import os
import re
import shutil
import statistics
import subprocess
import sys
import time

ROOT = os.getcwd()
AUTO = "_harness/auto"
STATE = f"{AUTO}/state.json"
LEDGER = f"{AUTO}/ledger.md"
TEMPLATES = "harness/templates/auto"
CARD_STATUSES = ("passed", "escalated", "waiting_owner", "split")
MODES = ("full", "bug", "small", "light", "small-bug")
FEATURE_STATUSES = ("todo", "running", "passed", "waiting_owner", "exited", "split", "skipped")
SETTLED = ("passed", "skipped", "split")
SLUG = re.compile(r"[a-z0-9]+(-[a-z0-9]+)*")
# A usage limit is told from the session's own error, not from what the work talked about: only the start of an
# error result, or the result subtype, counts.
USAGE_LIMIT = re.compile(r"^\W*(claude( ai)? usage limit|usage limit reached|.{0,40}rate_limit_error|api error: 429)",
                         re.I)
MAX_USAGE_WAITS = 12


class Refuse(Exception):
    """A check that stops the driver before it changes anything (exit 2)."""


class RunExit(Exception):
    """Ends the run with status exited and the reason, from anywhere inside a step."""

    def __init__(self, reason, feature=None):
        super().__init__(reason)
        self.reason, self.feature = reason, feature


# ---- small helpers ---------------------------------------------------------------------------------------
def now():
    return datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def say(msg):
    print(f"auto: {msg}", flush=True)


def path(rel):
    return os.path.join(ROOT, rel)


def read(rel, default=None):
    try:
        with open(path(rel), encoding="utf-8") as f:
            return f.read()
    except OSError:
        if default is None:
            raise
        return default


def write(rel, text):
    p = path(rel)
    os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
    with open(p + ".tmp", "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(p + ".tmp", p)


def git(*args, check=True):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    if check and r.returncode:
        raise RuntimeError(f"git {' '.join(args)} failed: {r.stderr.strip()[-400:]}")
    return r.stdout.strip()


def ref(name):
    return git("rev-parse", "--verify", "--quiet", f"refs/heads/{name}", check=False)


def head_branch():
    return git("rev-parse", "--abbrev-ref", "HEAD", check=False)


def config(key, default=""):
    """Reads harness.config.yml with the kit's own reader, so the driver and the scripts agree on every value."""
    r = subprocess.run(["bash", "-c", '. scripts/lib/config.sh && config_get "$1"', "_", key],
                       cwd=ROOT, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    value = r.stdout.strip()
    return value if value else default


def config_list(key):
    return [v.strip() for v in config(key).strip("[]").split(",") if v.strip()]


def number(key, default):
    try:
        return float(config(key, str(default)))
    except ValueError:
        raise Refuse(f"harness.config.yml {key} is not a number")


def protected_branches():
    r = subprocess.run(["bash", "-c", ". scripts/lib/config.sh && config_env_branches"], cwd=ROOT,
                       capture_output=True, text=True, stdin=subprocess.DEVNULL)
    names = {b.strip() for b in r.stdout.split() if b.strip()}
    return names | {b for b in (config("branches.integration"), config("branches.production"), "main", "master") if b}


# ---- state -----------------------------------------------------------------------------------------------
def live_dir():
    """The live state, session logs, lock and stop request live in the git folder, outside every branch, so no
    session can commit them; commit() copies a snapshot of the state to _harness/auto/state.json on the run branch."""
    d = os.path.join(git("rev-parse", "--path-format=absolute", "--git-common-dir"), "morphness", "auto")
    os.makedirs(d, exist_ok=True)
    return d


def load_state():
    for p in (os.path.join(live_dir(), "state.json"), path(STATE)):
        try:
            with open(p, encoding="utf-8") as f:
                return json.load(f)
        except (OSError, json.JSONDecodeError):
            continue
    return None


def save_state(st):
    p = os.path.join(live_dir(), "state.json")
    with open(p + ".tmp", "w", encoding="utf-8") as f:
        f.write(json.dumps(st, indent=2) + "\n")
    os.replace(p + ".tmp", p)


def lock():
    """One driver per repository: a second one would work on the same branches."""
    p = os.path.join(live_dir(), "lock")
    try:
        pid = int(open(p).read().strip())
        os.kill(pid, 0)
        if pid != os.getpid():
            raise Refuse(f"another driver (pid {pid}) is running here; `run.sh stop` asks it to exit")
    except (OSError, ValueError):
        pass
    with open(p, "w") as f:
        f.write(str(os.getpid()))


def unlock():
    try:
        os.remove(os.path.join(live_dir(), "lock"))
    except OSError:
        pass


def stop_requested():
    tree = path(f"{AUTO}/STOP")
    if os.path.exists(tree):  # moved out of the tree, so no stash or session commit takes it away
        shutil.move(tree, os.path.join(live_dir(), "STOP"))
    return os.path.exists(os.path.join(live_dir(), "STOP"))


def clear_stop():
    for p in (path(f"{AUTO}/STOP"), os.path.join(live_dir(), "STOP")):
        if os.path.exists(p):
            os.remove(p)


def feature(st, slug):
    return next((f for f in st["features"] if f["slug"] == slug), None)


def new_feature(row, inserted_by=None, what=""):
    return {"slug": row["slug"], "title": row.get("title") or row["slug"], "milestone": row.get("milestone", ""),
            "depends_on": list(row.get("depends_on", [])), "risk": row.get("risk", "low"), "status": "todo",
            "mode": "", "tries": {"crashes": 0, "qa_rounds": 0, "last_try": False}, "branch": f"feature/{row['slug']}",
            "branch_made": False, "merge_commit": "", "cost_usd": 0.0, "budget_base": 0.0, "sessions": 0,
            "waiting_on": "", "inserted_by": inserted_by, "what": what}


# ---- the order file --------------------------------------------------------------------------------------
def parse_order(text, existing=()):
    """docs/product/order.md: one table | # | Slug | Title | Milestone | Depends on | Risk |. Returns the rows or
    raises ValueError naming every problem, so the director's retry can fix them all at once."""
    rows, header = [], None
    for line in text.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header is None:
            header = [c.lower() for c in cells]
            continue
        if all(set(c) <= set("-: ") for c in cells):
            continue
        rec = dict(zip(header, cells))
        deps = rec.get("depends on", "-").strip()
        rows.append({"slug": rec.get("slug", "").strip("` "), "title": rec.get("title", ""),
                     "milestone": rec.get("milestone", ""),
                     "depends_on": [] if deps in ("", "-", "none") else [d.strip("` ") for d in deps.split(",") if d.strip()],
                     "risk": (rec.get("risk", "low") or "low").lower()})
    problems = []
    if header is None or not rows:
        problems.append("no feature table found")
    elif not {"slug", "title", "depends on"} <= set(header):
        problems.append(f"the table needs Slug, Title and Depends on columns, found {header}")
    problems += check_rows(rows, existing)
    if problems:
        raise ValueError("; ".join(problems))
    return rows


def check_rows(rows, existing=()):
    """The rules every list of features meets: kebab-case slugs, unique, known dependencies, no cycle."""
    problems, seen = [], set()
    for r in rows:
        if not SLUG.fullmatch(r["slug"]):
            problems.append(f"slug {r['slug']!r} is not kebab-case")
        if r["slug"] in seen:
            problems.append(f"slug {r['slug']} is listed twice")
        seen.add(r["slug"])
        if r.get("risk", "low") not in ("low", "medium", "high"):
            problems.append(f"{r['slug']}: risk {r['risk']!r} is not low, medium or high")
    known = seen | set(existing)
    for r in rows:
        for d in r["depends_on"]:
            if d not in known:
                problems.append(f"{r['slug']} depends on unknown {d}")
    if not problems:
        hit = cycle(rows)
        if hit:
            problems.append(f"dependency cycle through {hit}")
    return problems


def cycle(rows):
    deps = {r["slug"]: r["depends_on"] for r in rows}
    mark = {}

    def visit(s):
        if mark.get(s) == 1:
            return s
        if mark.get(s) == 2:
            return None
        mark[s] = 1
        for d in deps.get(s, []):
            hit = visit(d)
            if hit:
                return hit
        mark[s] = 2
        return None

    return next((h for h in (visit(s) for s in deps) if h), None)


def docs_tree():
    """The committed docs/product/ on the run branch: an owner edit is a commit, a .DS_Store or a draft is not."""
    return git("rev-parse", "--verify", "--quiet", "HEAD:docs/product", check=False)


# ---- cards -----------------------------------------------------------------------------------------------
def parse_card(text):
    """A card: a header of plain `key: value` lines between --- lines, then a Markdown body. The lists the driver
    acts on are body sections with one `- ` line per item, so colons and commas in an item are just text:
    § Owner items (a rule item starts `rule:`), § Bugs found (`- <slug> | what | where`) and § Split into
    (`- <slug> | title | depends on, comma separated`)."""
    m = re.match(r"\A---\r?\n(.*?)\r?\n---\r?\n?(.*)\Z", text, re.S)
    if not m:
        raise ValueError("no header between --- lines")
    head = {}
    for line in m.group(1).splitlines():
        line = re.sub(r"\s+#\s.*$", "", line).rstrip()
        if not line.strip():
            continue
        k, sep, v = line.partition(":")
        if not sep or not re.fullmatch(r"[a-z_]+", k.strip()):
            raise ValueError(f"header line {line!r} is not `key: value`")
        head[k.strip()] = v.strip().strip("\"'")
    body = m.group(2).strip()
    sections = {}
    for chunk in re.split(r"^## ", body, flags=re.M)[1:]:
        title, _, rest = chunk.partition("\n")
        sections[title.strip().lower()] = [l.strip()[2:].strip() for l in rest.splitlines()
                                           if l.strip().startswith("- ") and not re.match(r"(none\b|$)", l.strip()[2:].strip().lower())]
    card = {"status": head.get("status", ""), "slug": head.get("slug", ""), "mode": head.get("mode", ""),
            "departure": head.get("departure", "no").lower() in ("yes", "true")}
    problems = []
    try:
        card["qa_rounds"] = int(head.get("qa_rounds") or 0)
    except ValueError:
        problems.append(f"qa_rounds {head.get('qa_rounds')!r} is not a number")
    if card["status"] not in CARD_STATUSES:
        problems.append(f"status {card['status']!r} is not one of {', '.join(CARD_STATUSES)}")
    if card["status"] in ("passed", "escalated") and card["mode"] not in MODES:
        problems.append(f"mode {card['mode']!r} is not one of {', '.join(MODES)}")
    card["v1_items"] = sections.get("owner items", [])
    card["bugs_found"], card["split_into"] = [], []
    for item in sections.get("bugs found", []):
        parts = [p.strip() for p in item.split("|")]
        if len(parts) < 2 or not SLUG.fullmatch(parts[0].strip("`")):
            problems.append(f"bug line {item!r} is not `<feature-slug> | what | where`")
            continue
        card["bugs_found"].append({"in": parts[0].strip("`"), "what": parts[1], "where": parts[2] if len(parts) > 2 else ""})
    for item in sections.get("split into", []):
        parts = [p.strip() for p in item.split("|")]
        deps = [d.strip("` ") for d in (parts[2] if len(parts) > 2 else "").split(",") if d.strip() and d.strip() != "-"]
        card["split_into"].append({"slug": parts[0].strip("`"), "title": parts[1] if len(parts) > 1 else parts[0],
                                   "depends_on": deps})
    if card["status"] == "split" and not card["split_into"]:
        problems.append("status split needs § Split into with the parts")
    if len(body.splitlines()) > 40:
        problems.append(f"the body has {len(body.splitlines())} lines, over 40")
    if problems:
        raise ValueError("; ".join(problems))
    card["body"] = body
    return card


def records_say_passed(st, f, card, since):
    """A passed card counts only when the feature's own records agree (README § The card and the ledger)."""
    changed = [p for p in git("diff", "--name-only", f"{since}..{f['branch']}").splitlines() if p]
    if f"{AUTO}/cards/{f['slug']}.md" not in changed:
        return False, "the card wasn't written in this session (it is an old one)"
    work = [p for p in git("diff", "--name-only", f"{st['base']['commit']}..{f['branch']}").splitlines()
            if p and not p.startswith(f"{AUTO}/")]
    if not work:
        return False, "the branch changes nothing but the card"
    mode = card["mode"]
    if mode in ("light", "small-bug"):
        if not config_list("checks.on_stop") or not os.path.isfile(path("scripts/checks.sh")):
            return False, f"{mode} mode leaves no record, and checks.on_stop is empty, so nothing would check it"
        return True, "checked by checks.on_stop after the merge"
    base = f"_harness/features/{f['slug']}"
    listing = git("ls-tree", "--name-only", f"{f['branch']}:{base}", check=False).splitlines()
    versions = sorted((int(v) for v in listing if v.isdigit()), reverse=True)
    if not versions:
        return False, f"no {base}/<version>/ folder"
    v = f"{base}/{versions[0]}"
    plan = git("show", f"{f['branch']}:{v}/Plan/plan.md", check=False)
    if not re.search(r"^\*\*Status:\*\*\s*passed\b", plan, re.M):
        return False, f"{v}/Plan/plan.md Status is not passed"
    if mode == "small":
        check = plan.split("## Check", 1)[1] if "## Check" in plan else ""
        if not re.search(r"\S", re.sub(r"\*[^*\n]*\*", "", check)):
            return False, f"{v}/Plan/plan.md § Check is empty"
        return True, "plan passed with § Check"
    qa = git("show", f"{f['branch']}:{v}/QA/qa-result.md", check=False)
    results = re.findall(r"\*\*Result:\*\*\s*(pass|fail)\b", qa)
    if not results or results[-1] != "pass":
        return False, f"{v}/QA/qa-result.md verdict is not pass"
    return True, "plan and QA result agree"


# ---- sessions --------------------------------------------------------------------------------------------
def claude_bin():
    return os.environ.get("MORPH_AUTO_CLAUDE", "claude")


def fill(template, values):
    text = re.sub(r"\A<!--.*?-->\n*", "", read(f"{TEMPLATES}/{template}"), flags=re.S)
    for k, v in values.items():
        text = text.replace(f"%{k}%", str(v))
    return text


def remaining(st):
    return st["limits"]["budget_usd"] - st["spend_usd"]


def session(st, kind, prompt, label, model="", on_branch=None):
    """One headless session. Returns (outcome, cost, text): ok | crash | usage | budget. Afterwards HEAD must be
    on the branch it started on and no protected branch may have moved; a run that sees either exits."""
    on_branch = on_branch or head_branch()
    guarded = {b: ref(b) for b in protected_branches() | {st["base"]["branch"]} if b != on_branch}
    cap = min(st["limits"]["session_cap_usd"], remaining(st))
    if cap < 0.5:
        raise RunExit(f"run budget: ${st['spend_usd']:.2f} spent of ${st['limits']['budget_usd']:.2f}, too little "
                      "left for another session")
    cmd = [claude_bin(), "-p", prompt, "--output-format", "json", "--permission-prompts", "none",
           "--max-budget-usd", f"{cap:.2f}"]
    if model:
        cmd += ["--model", model]
    env = dict(os.environ, MORPH_AUTO="1", MORPH_AUTO_FEATURE=label if kind == "feature" else "",
               MORPH_AUTO_SESSION=kind, MORPH_AUTO_BRANCH=st["base"]["branch"])
    logs = os.path.join(live_dir(), "logs")
    os.makedirs(logs, exist_ok=True)
    st["session_count"] = st.get("session_count", 0) + 1
    log = os.path.join(logs, f"{st['session_count']:04d}-{label}.json")
    timeout = number("auto.session_hours", 4) * 3600
    try:
        r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, env=env, stdin=subprocess.DEVNULL,
                           timeout=timeout)
        stdout, stderr, code = r.stdout, r.stderr, r.returncode
    except subprocess.TimeoutExpired as e:
        stdout = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        stderr, code = f"the session ran past auto.session_hours ({timeout / 3600:g} h) and was stopped", -1
    except OSError as e:
        stdout, stderr, code = "", f"could not start {claude_bin()}: {e}", -1
    with open(log, "w", encoding="utf-8") as fh:
        fh.write(stdout + ("\n--- stderr ---\n" + stderr[-4000:] if stderr else ""))
    out = {}
    for candidate in (stdout.strip(), (stdout.strip().splitlines() or [""])[-1]):
        try:
            out = json.loads(candidate)
            break
        except json.JSONDecodeError:
            continue
    out = out if isinstance(out, dict) else {}
    cost = float(out.get("total_cost_usd") or 0.0)
    text = str(out.get("result") or stderr[-400:])
    st["spend_usd"] = round(st.get("spend_usd", 0.0) + cost, 4)
    save_state(st)
    moved = [b for b, sha in guarded.items() if ref(b) != sha]
    if moved:
        raise RunExit(f"a {kind} session changed branch {', '.join(moved)}; the driver stopped (log {log})")
    if head_branch() != on_branch:
        if git("status", "--porcelain"):
            stash(st, f"{label}: left on {head_branch()}")
        git("checkout", on_branch)
        say(f"the {kind} session left HEAD off {on_branch}; switched back")
    subtype = str(out.get("subtype", ""))
    if "budget" in subtype:
        return "budget", cost, text
    if code or out.get("is_error"):
        if "rate" in subtype.lower() or "usage" in subtype.lower() or USAGE_LIMIT.search(text[:200]):
            return "usage", cost, text
        return "crash", cost, text
    return "ok", cost, text


def with_usage_wait(st, run_once):
    """Runs run_once() again after a usage limit, waiting auto.usage_wait_minutes, doubling up to 4 hours, at
    most MAX_USAGE_WAITS times in a row. A stop request or a spent budget ends the wait."""
    wait = max(1.0, number("auto.usage_wait_minutes", 30))
    for _ in range(MAX_USAGE_WAITS + 1):
        outcome, cost, text = run_once()
        if outcome != "usage":
            return outcome, cost, text
        say(f"usage limit; waiting {wait:.0f} minutes (the try doesn't count)")
        deadline = time.time() + wait * 60 * float(os.environ.get("MORPH_AUTO_WAIT_SCALE", "1"))
        while time.time() < deadline:
            if stop_requested():
                raise RunExit("stop file: the owner asked the run to stop (during a usage-limit wait)")
            time.sleep(min(30, max(0, deadline - time.time())))
        wait = min(wait * 2, 240)
    raise RunExit(f"usage limit: still limited after {MAX_USAGE_WAITS} waits; resume when the limit resets")


def stash(st, why):
    git("stash", "push", "--include-untracked", "-m", f"auto: {why}", check=False)
    st.setdefault("stashes", []).append(f"{git('rev-parse', '--short', 'stash@{0}', check=False)} {why}")


# ---- checks before anything runs -------------------------------------------------------------------------
def preflight(need_clean=True):
    if os.environ.get("CLAUDECODE") and not os.environ.get("MORPH_AUTO_ALLOW_NESTED"):
        raise Refuse("run this from a terminal, not inside a Claude Code session: the sessions it starts would "
                     "inherit this one's environment")
    if os.environ.get("MORPH_AUTO"):
        raise Refuse("MORPH_AUTO is set: a session the driver started can't start the driver")
    if not os.path.isfile(path("harness.config.yml")):
        raise Refuse("no harness.config.yml here: run from the repository root")
    if "autonomous" not in config_list("modules"):
        raise Refuse("the autonomous module is not in harness.config.yml → modules (/morph-module add autonomous)")
    if "roadmap" not in config_list("modules"):
        raise Refuse("the autonomous module needs the roadmap module")
    if need_clean and git("status", "--porcelain", "--untracked-files=no"):
        raise Refuse("the working tree has changes: commit or stash them first")
    if os.path.exists(path(".git/MERGE_HEAD")) or os.path.exists(path(".git/rebase-merge")):
        raise Refuse("a merge or rebase is in progress: finish or abort it first")
    if shutil.which(claude_bin()) is None and not os.path.isfile(claude_bin()):
        raise Refuse(f"{claude_bin()} is not on PATH")
    help_text = subprocess.run([claude_bin(), "--help"], capture_output=True, text=True,
                               stdin=subprocess.DEVNULL).stdout
    if "--permission-prompts" not in help_text or "--max-budget-usd" not in help_text:
        raise Refuse("this Claude Code has no --permission-prompts or --max-budget-usd: update it first")
    lock()


def limits():
    budget = number("auto.budget_usd", 0)
    per_feature = number("loop.feature_budget_usd", 0)
    if config("auto.enabled", "false") != "true":
        raise Refuse("auto.enabled is not true in harness.config.yml (the owner turns it on)")
    if budget <= 0:
        raise Refuse("auto.budget_usd is 0: set the run's budget first")
    if per_feature <= 0:
        raise Refuse("loop.feature_budget_usd is 0: set a per-feature budget first (15 is a fair start)")
    return {"budget_usd": budget, "feature_budget_usd": per_feature, "session_cap_usd": round(per_feature * 1.5, 2),
            "max_features": int(number("auto.max_features", 30)), "max_hours": number("auto.max_hours", 24),
            "crash_retries": int(number("auto.crash_retries", 1))}


def version_dir():
    roadmap_file = config("roadmap.file", "docs/ROADMAP.md")
    for line in read(roadmap_file, "").splitlines():
        if "**NEXT**" in line:
            m = re.search(r"\]\(([^)]*?)/[^/)]+\.md\)", line)
            if m:
                return os.path.normpath(os.path.join(os.path.dirname(roadmap_file), m.group(1)))
    return ""


def checklist_path():
    vdir = version_dir()
    return f"{vdir}/checklist.md" if vdir else f"{AUTO}/owner-items.md"


def to_run_branch(st):
    if head_branch() != st["base"]["branch"]:
        git("checkout", st["base"]["branch"])


# ---- commands --------------------------------------------------------------------------------------------
def cmd_start():
    preflight()
    lim = limits()
    if not os.path.isfile(path("docs/brief.md")):
        raise Refuse("no docs/brief.md: write it from harness/templates/auto/brief.md first")
    st = load_state()
    run_branch = config("auto.branch", "auto/v1")
    if run_branch in protected_branches():
        raise Refuse(f"auto.branch {run_branch} is the integration, production or an environment branch")
    if st and st["status"] in ("docs", "docs_failed") and st["base"]["branch"] == run_branch and ref(run_branch):
        git("checkout", run_branch)  # the director didn't finish last time: try again on the same branch
        st["limits"] = lim
    elif st and st["status"] not in ("done", "done_waiting"):
        raise Refuse(f"a run is {st['status']}; use approve, run, resume or status (README § Starting over "
                     "says how to drop a run)")
    else:
        if ref(run_branch):
            raise Refuse(f"branch {run_branch} already exists: delete it or set another auto.branch")
        base = config("branches.integration") or head_branch()
        git("checkout", "-b", run_branch, base)
        st = {"schema": 1, "status": "docs", "started": now(), "limits": lim,
              "base": {"branch": run_branch, "from": base, "commit": git("rev-parse", "HEAD")},
              "approval": None, "spend_usd": 0.0, "hours": 0.0, "exit": None, "features": [], "replans": []}
    st["status"] = "docs"
    save_state(st)
    if not version_dir():
        say("the roadmap has no NEXT row with a link: the director creates the version, owner items go to "
            f"{AUTO}/owner-items.md until it exists")
    prompt = fill("director-prompt.md", {"ROADMAP_FILE": config("roadmap.file", "docs/ROADMAP.md"),
                                         "VERSION_DIR": version_dir() or "the version the roadmap marks next"})
    rows, error = None, ""
    try:
        for attempt in (1, 2):
            outcome, _, text = with_usage_wait(st, lambda: session(st, "director", prompt + error, "director",
                                                                   model=config("auto.director_model", "opus")))
            if outcome != "ok":
                raise RunExit(f"the director session ended with {outcome}: {text[:300]}")
            try:
                rows = parse_order(read("docs/product/order.md", ""))
                break
            except ValueError as e:
                error = f"\n\nYour docs/product/order.md had these problems; fix them and keep everything else: {e}"
                say(f"order check failed ({e})" + ("; asking the director once more" if attempt == 1 else ""))
        if rows is None:
            raise RunExit(f"docs/product/order.md failed its check twice: {error.strip()}")
    except RunExit as e:
        st["status"] = "docs_failed"
        save_state(st)
        commit(st, "auto: product docs draft (director didn't finish)")
        say(f"{e.reason}. Fix what it says, then run start again: it retries on {run_branch}")
        return 1
    st["features"] = [new_feature(r) for r in rows]
    st["status"] = "awaiting_approval"
    save_state(st)
    render_tracker(st)
    commit(st, "auto: product docs, order and run state for approval")
    full = sum(1 for f in st["features"] if f["risk"] != "low")
    estimate = full * 6 + (len(st["features"]) - full) + 3
    say(f"{len(st['features'])} features in docs/product/order.md ({full} likely full mode). Estimate about "
        f"${estimate}, budget ${lim['budget_usd']:.0f}. Read docs/product/, edit and commit what you want on "
        f"{run_branch}, then run: bash scripts/auto/run.sh approve")
    return 0


def cmd_approve():
    preflight()
    st = load_state()
    if not st or st["status"] != "awaiting_approval":
        raise Refuse(f"nothing awaits approval (status {st and st['status']})")
    to_run_branch(st)
    rows = parse_order(read("docs/product/order.md"))
    taken = [r["slug"] for r in rows if ref(f"feature/{r['slug']}")]
    if taken:
        raise Refuse(f"branches already exist for {', '.join('feature/' + s for s in taken)}: rename those features "
                     "in order.md or delete the branches")
    known = {f["slug"]: f for f in st["features"]}
    st["features"] = [known.get(r["slug"]) or new_feature(r) for r in rows]
    for f, r in zip(st["features"], rows):
        f.update({"title": r["title"], "milestone": r["milestone"], "depends_on": r["depends_on"], "risk": r["risk"]})
    owner = git("config", "user.name", check=False) or os.environ.get("USER", "the owner")
    st["approval"] = {"by": owner, "at": now()[:10], "docs_tree": docs_tree()}
    st["status"], st["limits"] = "running", limits()
    save_state(st)
    render_tracker(st)
    commit(st, f"auto: product docs approved by {owner}")
    st["approval"]["docs_tree"] = docs_tree()
    save_state(st)
    say("approved. Start the build with: bash scripts/auto/run.sh run")
    return 0


def cmd_stop():
    with open(os.path.join(live_dir(), "STOP"), "w", encoding="utf-8") as f:
        f.write(f"stop requested {now()}\n")
    say("stop requested: the run exits after the current step")
    return 0


def cmd_status():
    st = load_state()
    if not st:
        say("no run here")
        return 0
    render_tracker(st, write_file=False)
    return 0


def cmd_resume():
    preflight()
    st = load_state()
    if not st or st["status"] not in ("exited", "done_waiting"):
        raise Refuse(f"nothing to resume (status {st and st['status']})")
    if not st.get("approval"):
        raise Refuse("the product docs were never approved: run start (it retries the director) and approve")
    to_run_branch(st)
    exit_info = st.get("exit") or {}
    direction = ""
    if exit_info.get("reason", "").startswith("escalated"):
        note = read(f"{AUTO}/exit.md", "")
        direction = note.split("## Owner direction", 1)[1].strip() if "## Owner direction" in note else ""
        direction = re.sub(r"^Write how the feature should go on.*$", "", direction, flags=re.M).strip()
        if not direction:
            raise Refuse(f"write how the escalated feature should go on under § Owner direction in {AUTO}/exit.md, "
                         "commit it, then resume")
    for f in st["features"]:
        if f["status"] in ("exited", "running") or (st["status"] == "done_waiting" and f["status"] == "waiting_owner"):
            why = ("the owner did the items it waited on" if f["status"] == "waiting_owner"
                   else f"resumed after: {exit_info.get('reason', 'a stop')}")
            f["status"], f["waiting_on"] = "todo", ""
            f["tries"] = {"crashes": 0, "qa_rounds": f["tries"].get("qa_rounds", 0), "last_try": True,
                          "resume": why, "direction": direction if exit_info.get("feature") == f["slug"] else ""}
            f["budget_base"] = f["cost_usd"]
    st["limits"] = limits()
    st["status"], st["exit"], st["hours"] = "running", None, 0.0
    clear_stop()
    save_state(st)
    commit(st, "auto: resume")
    return cmd_run(already_checked=True)


def cmd_run(already_checked=False):
    if not already_checked:
        preflight()
    st = load_state()
    if not st or st["status"] != "running":
        raise Refuse(f"the run isn't running (status {st and st['status']}): start, approve or resume first")
    if not st.get("approval"):
        raise Refuse("the product docs were never approved: run approve first")
    to_run_branch(st)
    for f in st["features"]:  # a driver that was killed mid-feature: that try counts as a crash
        if f["status"] == "running":
            f["status"] = "todo"
            f["tries"]["crashes"] += 1
            f["tries"]["resume"] = "the driver stopped during the last session"
    started = time.time() - st.get("hours", 0.0) * 3600
    try:
        while True:
            st["hours"] = round((time.time() - started) / 3600, 3)
            save_state(st)
            if stop_requested():
                clear_stop()
                raise RunExit("stop file: the owner asked the run to stop")
            lim = st["limits"]
            costs = [f["cost_usd"] for f in st["features"] if f["status"] == "passed" and f["cost_usd"]]
            next_cost = statistics.median(costs) if costs else lim["feature_budget_usd"]
            if st["spend_usd"] + next_cost > lim["budget_usd"]:
                raise RunExit(f"run budget: ${st['spend_usd']:.2f} spent, the next feature (about ${next_cost:.2f}) "
                              f"would pass ${lim['budget_usd']:.2f}")
            if st["hours"] >= lim["max_hours"]:
                raise RunExit(f"max hours: {st['hours']:.1f} of {lim['max_hours']:g}")
            if st["approval"]["docs_tree"] != docs_tree():
                replan(st, "the owner committed a change to docs/product/", "")
            f = next_todo(st)
            if f is None:
                return end_without_todo(st)
            if not f["sessions"] and sum(1 for x in st["features"] if x["sessions"]) >= lim["max_features"]:
                raise RunExit(f"max features: {lim['max_features']} started")
            run_feature(st, f)
    except RunExit as e:
        return finish(st, "exited", e.reason, e.feature)
    finally:
        unlock()


def next_todo(st):
    settled = {f["slug"] for f in st["features"] if f["status"] in SETTLED}
    return next((f for f in st["features"] if f["status"] == "todo" and all(d in settled for d in f["depends_on"])), None)


def end_without_todo(st):
    settled = {x["slug"] for x in st["features"] if x["status"] in SETTLED}
    for x in st["features"]:
        if x["status"] == "todo":  # its dependencies won't settle in this run
            x["status"] = "waiting_owner"
            x["waiting_on"] = "waits on " + ", ".join(d for d in x["depends_on"] if d not in settled)
    open_ = [x for x in st["features"] if x["status"] not in SETTLED + ("waiting_owner",)]
    if open_:
        raise RunExit(f"features left in an unexpected state: {', '.join(x['slug'] + ' ' + x['status'] for x in open_)}")
    waiting = [x for x in st["features"] if x["status"] == "waiting_owner"]
    return finish(st, "done_waiting" if waiting else "done",
                  f"{len(waiting)} features wait on you" if waiting else "every feature passed")


def what_to_build(st, f):
    if (f.get("inserted_by") or "").startswith("bug:"):
        return f"a fix for a bug found during the run: {f['what']} Run it in bug mode if it touches a risk path."
    if (f.get("inserted_by") or "").startswith("split:"):
        parent = f["inserted_by"][len("split:"):]
        return (f"part of `{parent}`, split as its card `{AUTO}/cards/{parent}.md` says: {f['title']}. Build only "
                "this part.")
    return f"the `{f['slug']}` row of `docs/product/order.md` and what `docs/product/` says about it."


def run_feature(st, f):
    run_branch = st["base"]["branch"]
    branch = f["branch"]
    if ref(branch) and not f["branch_made"]:
        raise RunExit(f"branch {branch} exists but this run didn't make it: rename or delete it, then resume", f)
    f["status"] = "running"
    save_state(st)
    render_tracker(st)
    commit(st, f"auto: {f['slug']} running")
    if not ref(branch):
        git("branch", branch, run_branch)
        f["branch_made"] = True
    while True:
        git("checkout", branch)
        since = git("rev-parse", "HEAD")
        resumed = bool(f["tries"].get("resume")) or f["tries"]["crashes"] > 0
        values = {"SLUG": f["slug"], "TITLE": f["title"], "MILESTONE": f["milestone"] or "-", "BRANCH": branch,
                  "RUN_BRANCH": run_branch, "OWNER": st["approval"]["by"], "APPROVED_AT": st["approval"]["at"],
                  "WHAT": what_to_build(st, f),
                  "DEP_CARDS": ", ".join(f"`{AUTO}/cards/{d}.md`" for d in f["depends_on"]) or "none",
                  "WHY": f["tries"].get("resume") or "resume", "QA_ROUNDS": f["tries"].get("qa_rounds", 0),
                  "NEW_VERSION": ("The last run escalated this feature. The owner's direction: " + f["tries"]["direction"]
                                  + " Start the feature's next version folder with it in § Request.")
                  if f["tries"].get("direction") else ""}
        prompt = fill("resume-prompt.md" if resumed else "feature-prompt.md", values)
        model = config("auto.last_try_model", "opus") if (resumed or f["tries"]["last_try"]) else ""
        outcome, cost, text = with_usage_wait(st, lambda: session(st, "feature", prompt, f["slug"], model=model,
                                                                  on_branch=branch))
        f["sessions"] += 1
        f["cost_usd"] = round(f["cost_usd"] + cost, 4)
        card_rel = f"{AUTO}/cards/{f['slug']}.md"
        committed = git("show", f"{branch}:{card_rel}", check=False)
        card, problem = None, ""
        if outcome in ("ok", "budget") and committed:
            try:
                card = parse_card(committed)
                if card["status"] == "split":
                    taken = {x["slug"] for x in st["features"]}
                    bad = check_rows(card["split_into"], taken) + [f"part {p['slug']} reuses an existing slug"
                                                                    for p in card["split_into"] if p["slug"] in taken]
                    if bad:
                        raise ValueError("; ".join(bad))
            except ValueError as e:
                card, problem = None, f"card {card_rel} is not valid: {e}"
        else:
            problem = text[:300] if outcome != "ok" else f"no committed {card_rel}"
        if git("status", "--porcelain"):
            stash(st, f"{f['slug']} uncommitted work after a session")
        save_state(st)
        if card is None and (outcome == "budget" or f["cost_usd"] - f["budget_base"] > st["limits"]["session_cap_usd"]):
            to_run_branch(st)
            f["status"] = "exited"
            raise RunExit(f"tries used up: {f['slug']} spent its budget (${f['cost_usd'] - f['budget_base']:.2f} "
                          f"since its start or resume)", f)
        if card is None:
            f["tries"]["crashes"] += 1
            if f["tries"]["crashes"] > st["limits"]["crash_retries"]:
                to_run_branch(st)
                f["status"] = "exited"
                raise RunExit(f"tries used up: {f['slug']} crashed {f['tries']['crashes']} times ({problem})", f)
            say(f"{f['slug']}: crash ({problem}); starting it again from its last commit")
            f["tries"]["resume"] = f"the last session crashed: {problem}"
            continue
        handle_card(st, f, card, since)
        return


def handle_card(st, f, card, since):
    run_branch = st["base"]["branch"]
    f["mode"], f["tries"]["qa_rounds"] = card["mode"], card["qa_rounds"]
    status = card["status"]
    if status == "passed":
        ok, why = records_say_passed(st, f, card, since)
        if not ok:
            to_run_branch(st)
            f["status"] = "exited"
            raise RunExit(f"tries used up: {f['slug']}'s card says passed but {why}", f)
    card_text = git("show", f"{f['branch']}:{AUTO}/cards/{f['slug']}.md")
    to_run_branch(st)
    if status in ("passed", "split"):
        shown = f"{AUTO}/cards/{f['slug']}.md"
        if git("ls-files", shown):  # a copy shown after an earlier stop: the branch's own card replaces it
            git("rm", "-q", shown)
            git("commit", "-q", "-m", f"auto: {f['slug']} card comes from its branch")
        r = subprocess.run(["git", "merge", "--no-ff", "-m", f"auto: merge {f['branch']} ({status})", f["branch"]],
                           cwd=ROOT, capture_output=True, text=True, stdin=subprocess.DEVNULL)
        if r.returncode:
            git("merge", "--abort", check=False)
            f["status"] = "exited"
            raise RunExit(f"merge conflict merging {f['branch']} into {run_branch}: {r.stdout.strip()[-200:]}", f)
        f["merge_commit"] = git("rev-parse", "HEAD")
    else:
        write(f"{AUTO}/cards/{f['slug']}.md", card_text + "\n")  # the work stays on its branch; the card is shown
    if status == "passed":
        failed = run_checks()
        if failed:
            git("reset", "-q", "--hard", "HEAD~1")
            f["status"] = "exited"
            raise RunExit(f"tries used up: {f['slug']} passed QA but {failed} failed after the merge", f)
        f["status"] = "passed"
        ledger = read(LEDGER, "# Ledger\n\nPassed cards, in merge order. Features read their dependencies' cards, "
                              "not this file.\n")
        write(LEDGER, ledger.rstrip() + f"\n\n## {f['slug']} ({f['title']})\n\n{card['body']}\n")
    elif status == "waiting_owner":
        f["status"] = "waiting_owner"
        f["waiting_on"] = "; ".join(card["v1_items"]) or "see its steps file"
        for d in dependants(st, f["slug"]):
            if d["status"] == "todo":
                d["status"], d["waiting_on"] = "waiting_owner", f"waits on {f['slug']}"
    elif status == "split":
        f["status"] = "split"
        idx = st["features"].index(f)
        parts = [new_feature({"slug": p["slug"], "title": p["title"], "milestone": f["milestone"],
                              "depends_on": p["depends_on"] or list(f["depends_on"]), "risk": f["risk"]},
                             inserted_by=f"split:{f['slug']}") for p in card["split_into"]]
        st["features"][idx + 1:idx + 1] = parts
        names = [p["slug"] for p in parts]
        for d in st["features"]:
            if f["slug"] in d["depends_on"] and d not in parts:
                d["depends_on"] = [x for x in d["depends_on"] if x != f["slug"]] + names
    for b in card["bugs_found"]:
        insert_fix(st, b)
    copy_v1_items(f, card["v1_items"])
    f["docs_after"] = docs_tree()
    st["approval"]["docs_tree"] = docs_tree()  # the run's own merge: not an owner edit
    if status == "escalated":
        f["status"] = "exited"
        save_state(st)
        raise RunExit(f"escalated: {f['slug']} failed QA past loop.qa_max_rounds or hit a stop only you can "
                      "decide", f)
    if card["departure"]:
        replan(st, f"{f['slug']}'s card says the plan departs from docs/product/", f"{AUTO}/cards/{f['slug']}.md")
    after_feature(st, f)


def dependants(st, slug):
    out, frontier, changed = [], {slug}, True
    while changed:
        changed = False
        for d in st["features"]:
            if d not in out and frontier & set(d["depends_on"]):
                out.append(d)
                frontier.add(d["slug"])
                changed = True
    return out


def insert_fix(st, bug):
    target = feature(st, bug["in"])
    if target is None:
        copy_v1_items({"slug": "run"}, [f"A bug a feature found in unknown `{bug['in']}`: {bug['what']} ({bug['where']})"])
        return
    n = 1 + sum(1 for x in st["features"] if x.get("inserted_by") == f"bug:{bug['in']}")
    slug = f"fix-{bug['in']}-{n}"
    what = f"{bug['what']}" + (f" (at {bug['where']})" if bug["where"] else "") + f", in `{bug['in']}`."
    fix = new_feature({"slug": slug, "title": f"Fix in {bug['in']}: {bug['what']}"[:80], "milestone": "fix",
                       "depends_on": [bug["in"]] if target["status"] in ("passed", "todo", "running") else [],
                       "risk": "medium"}, inserted_by=f"bug:{bug['in']}", what=what)
    users = [i for i, x in enumerate(st["features"]) if bug["in"] in x["depends_on"] and x["status"] == "todo"]
    at = users[0] if users else next((i for i, x in enumerate(st["features"]) if x["status"] == "todo"),
                                     len(st["features"]))
    st["features"].insert(at, fix)
    for x in st["features"]:
        if x is not fix and bug["in"] in x["depends_on"] and x["status"] == "todo":
            x["depends_on"].append(slug)
            x.setdefault("driver_deps", []).append(slug)


def copy_v1_items(f, items):
    if not items:
        return
    target = checklist_path()
    text = read(target, "# Owner items\n" if target.startswith(AUTO) else "")
    for heading in ("Needs you", "Harness changes"):
        if not re.search(rf"^## {heading}\b", text, re.M):
            text = text.rstrip() + f"\n\n## {heading}\n"
    for item in items:
        rule = item.lower().startswith(("rule:", "human decides"))
        line = f"- [ ] {item} (from `{f['slug']}`)"
        if line in text:
            continue
        heading = re.search(rf"^## {'Harness changes' if rule else 'Needs you'}\b.*\n", text, re.M)
        nxt = re.search(r"^## ", text[heading.end():], re.M)
        cut = heading.end() + (nxt.start() if nxt else len(text) - heading.end())
        section = text[heading.end():cut].rstrip("\n")
        text = text[:heading.end()] + (section + "\n" if section.strip() else "") + line + "\n\n" + text[cut:].lstrip("\n")
    write(target, text.rstrip() + "\n")


def run_checks():
    names = config_list("checks.on_stop")
    if not names or not os.path.isfile(path("scripts/checks.sh")):
        return ""
    r = subprocess.run(["bash", "scripts/checks.sh", "run", *names], cwd=ROOT, capture_output=True, text=True,
                       stdin=subprocess.DEVNULL)
    return "" if r.returncode == 0 else f"checks.on_stop ({', '.join(names)})"


def replan(st, reason, card):
    say(f"re-plan: {reason}")
    pending = [f for f in st["features"] if f["status"] == "todo"]
    listing = "\n".join(f"- `{f['slug']}` {f['title']}" + (f" (added by the run: {f['inserted_by']})" if f.get("inserted_by") else "")
                        for f in pending) or "- none"
    save_state(st)
    commit(st, "auto: state before re-plan")
    prompt = fill("replan-prompt.md", {"REASON": reason, "CARD": card or "none", "PENDING": listing})
    outcome, _, _ = with_usage_wait(st, lambda: session(st, "director", prompt, "replan",
                                                        model=config("auto.director_model", "opus")))
    ok = outcome == "ok"
    if ok:
        try:
            done = {f["slug"] for f in st["features"] if f["status"] != "todo"}
            rows = parse_order(read("docs/product/order.md"), existing=done | {f["slug"] for f in pending})
            known = {f["slug"]: f for f in st["features"]}
            keep = [f for f in st["features"] if f["status"] != "todo"]
            listed = {r["slug"] for r in rows}
            new_todo = []
            for r in rows:
                if r["slug"] in done:
                    continue
                f = known.get(r["slug"]) or new_feature(r, inserted_by="replan")
                f.update({"title": r["title"], "milestone": r["milestone"], "risk": r["risk"],
                          "depends_on": r["depends_on"] + [d for d in f.get("driver_deps", []) if d not in r["depends_on"]]})
                new_todo.append(f)
            carried = [f for f in pending if f.get("inserted_by") and f["slug"] not in listed]  # fixes and parts
            st["features"] = keep + carried + new_todo
        except ValueError as e:
            say(f"the re-planned order failed its check ({e})")
            ok = False
    if not ok:
        say("re-plan didn't finish; keeping the current order and docs")
        git("checkout", "HEAD", "--", "docs/product", check=False)
        git("clean", "-fdq", "--", "docs/product", check=False)
    st["replans"].append({"at": now(), "reason": reason, "ok": ok})
    save_state(st)
    commit(st, f"auto: re-plan ({reason[:60]})")
    st["approval"]["docs_tree"] = docs_tree()
    save_state(st)


def after_feature(st, f):
    r = subprocess.run(["bash", "scripts/prune-counter.sh"], cwd=ROOT, capture_output=True, text=True,
                       stdin=subprocess.DEVNULL) if os.path.isfile(path("scripts/prune-counter.sh")) else None
    if r is not None and "Prune is DUE" in r.stdout and not st.get("prune_open"):
        prunes = path("_harness/prunes")
        before = set(os.listdir(prunes)) if os.path.isdir(prunes) else set()
        outcome, _, _ = with_usage_wait(st, lambda: session(st, "prune", fill("prune-prompt.md", {}), "prune"))
        after = set(os.listdir(prunes)) if os.path.isdir(prunes) else set()
        new = sorted(after - before)
        copy_v1_items({"slug": "prune"}, [f"rule: decide the prune proposal `_harness/prunes/{n}`" for n in new])
        st["prune_open"] = bool(new)
        if outcome != "ok":
            say("the prune session didn't finish; the next feature's counter asks again")
    elif r is not None and "Prune is DUE" not in r.stdout:
        st["prune_open"] = False
    size = len(read(LEDGER, "").encode())
    if size > number("auto.ledger_kb", 8) * 1024 and size > st.get("ledger_compacted_at", 0) + 2048:
        prompt = (f"Autonomous run: compact `{LEDGER}` into `{AUTO}/ledger.next.md`: group the cards by milestone into "
                  "short summaries that keep every interface, path and decision later features need, and keep the last "
                  "five cards whole. Write only that file; no git.")
        outcome, _, _ = with_usage_wait(st, lambda: session(st, "director", prompt, "ledger",
                                                            model=config("auto.director_model", "opus")))
        if outcome == "ok" and os.path.isfile(path(f"{AUTO}/ledger.next.md")):
            os.replace(path(f"{AUTO}/ledger.next.md"), path(LEDGER))
        st["ledger_compacted_at"] = len(read(LEDGER, "").encode())
    save_state(st)
    render_tracker(st)
    commit(st, f"auto: {f['slug']} {f['status']}")
    push(st, st["base"]["branch"], f["branch"])


def commit(st, message):
    """Commits the run's own files on the run branch, with a snapshot of the live state. Anything else a session
    left behind is stashed and named in the exit note, never committed by the driver."""
    if head_branch() != st["base"]["branch"]:
        return
    write(STATE, json.dumps(st, indent=2) + "\n")
    paths = [p for p in (AUTO, "docs/product", "docs/brief.md", "_harness/prunes", checklist_path(),
                         config("roadmap.file", "docs/ROADMAP.md"), version_dir()) if p and os.path.exists(path(p))]
    git("add", "--", *paths)
    if git("diff", "--cached", "--name-only"):
        git("commit", "-q", "-m", message)
    if git("status", "--porcelain"):
        stash(st, f"files outside the run's own paths after: {message}")
        save_state(st)


def push(st, *branches):
    if not git("remote", check=False):
        return
    protected = protected_branches()
    for b in branches:
        if b in protected or not ref(b):
            continue
        r = subprocess.run(["git", "push", "-q", "origin", f"refs/heads/{b}:refs/heads/{b}"], cwd=ROOT,
                           capture_output=True, text=True, stdin=subprocess.DEVNULL)
        if r.returncode:
            say(f"push of {b} failed (the run carries on): {r.stderr.strip()[-200:]}")


ACTIONS = [("escalated", "write how the escalated feature should go on under § Owner direction below, commit, then resume"),
           ("tries used up", "read the feature's records and its log, fix or redirect it, then resume"),
           ("merge conflict", "resolve the conflict between the feature branch and the run branch, then resume"),
           ("run budget", "raise auto.budget_usd and resume, or stop here"),
           ("max hours", "resume when ready (resume starts a fresh clock)"),
           ("max features", "raise auto.max_features and resume, or stop here"),
           ("stop file", "resume when ready"), ("usage limit", "resume when your usage limit resets")]


def finish(st, status, reason, f=None):
    if head_branch() != st["base"]["branch"]:
        if git("status", "--porcelain"):
            stash(st, "uncommitted work at the run's end")
        git("checkout", st["base"]["branch"], check=False)
    if f and f["status"] == "running":
        f["status"] = "exited"
    st["status"] = status
    st["exit"] = {"reason": reason, "at": now(), "feature": f["slug"] if f else ""}
    save_state(st)
    count = {s: sum(1 for x in st["features"] if x["status"] == s) for s in FEATURE_STATUSES}
    if status == "exited":
        what = next((v for k, v in ACTIONS if reason.startswith(k)), "read the reason, then resume")
    elif status == "done_waiting":
        what = "do the items in the version checklist's § Needs you, then run resume: the waiting features run again"
    else:
        what = (f"review `{st['base']['branch']}` and open one PR from it to `{st['base']['from']}` (a later release "
                "adds /morph-auto pr)")
    lines = [f"# Run {status}: {what.split(',')[0]}", "", f"**You need to:** {what}.", "", f"- **Reason:** {reason}"]
    if f:
        lines.append(f"- **Feature:** `{f['slug']}` ({f['title']}), {f['status']}; records under "
                     f"`_harness/features/{f['slug']}/`, card `{AUTO}/cards/{f['slug']}.md`, branch `{f['branch']}`")
    lines.append(f"- **Spend:** ${st['spend_usd']:.2f} of ${st['limits']['budget_usd']:.2f}"
                 + (f"; this feature ${f['cost_usd']:.2f}" if f else ""))
    lines.append(f"- **Progress:** {count['passed']} passed, {count['waiting_owner']} waiting on you, "
                 f"{count['todo']} to do")
    if st.get("stashes"):
        lines.append("- **Stashed work** (`git stash list`): " + "; ".join(st["stashes"]))
    if status != "done":
        lines.append("- **Resume:** `bash scripts/auto/run.sh resume`")
    lines.append(f"- **Session logs:** `{os.path.relpath(os.path.join(live_dir(), 'logs'), ROOT)}/`")
    if status == "exited" and reason.startswith("escalated"):
        lines += ["", "## Owner direction", "", "Write how the feature should go on; resume starts its next version with it."]
    write(f"{AUTO}/exit.md", "\n".join(lines) + "\n")
    render_tracker(st)
    commit(st, f"auto: run {status}")
    push(st, st["base"]["branch"])
    say(f"run {status}: {reason}. See {AUTO}/exit.md")
    return 1 if status == "exited" else 0


# ---- tracker ---------------------------------------------------------------------------------------------
COLOURS = {"todo": "fill:#e5e7eb,stroke:#6b7280,color:#111827", "running": "fill:#bfdbfe,stroke:#1d4ed8,color:#1e3a8a",
           "passed": "fill:#bbf7d0,stroke:#15803d,color:#14532d", "waiting_owner": "fill:#fde68a,stroke:#b45309,color:#78350f",
           "exited": "fill:#fecaca,stroke:#b91c1c,color:#7f1d1d", "split": "fill:#e9d5ff,stroke:#7e22ce,color:#581c87",
           "skipped": "fill:#e9d5ff,stroke:#7e22ce,color:#581c87"}


def render_tracker(st, write_file=True):
    def node(s):
        return "f_" + re.sub(r"[^A-Za-z0-9]", "_", s)

    rows = ["| # | Feature | Milestone | Status | Mode | QA rounds | Cost | Card |", "|---|---|---|---|---|---|---|---|"]
    for i, f in enumerate(st["features"], 1):
        card = f"[card](./cards/{f['slug']}.md)" if os.path.exists(path(f"{AUTO}/cards/{f['slug']}.md")) else "-"
        status = f["status"] + (f" ({f['waiting_on']})" if f["waiting_on"] and f["status"] == "waiting_owner" else "")
        rows.append(f"| {i} | `{f['slug']}` {f['title'].replace('|', '/')} | {f['milestone'] or '-'} | "
                    f"{status.replace('|', '/')} | {f['mode'] or '-'} | {f['tries'].get('qa_rounds', 0)} | "
                    f"${f['cost_usd']:.2f} | {card} |")
    chart = ["```mermaid", "flowchart TD"]
    for f in st["features"]:
        label = re.sub(r'["<>]', "'", f["title"])
        chart.append(f'  {node(f["slug"])}["{label}<br/>{f["status"]}"]:::{f["status"]}')
    for f in st["features"]:
        chart += [f"  {node(d)} --> {node(f['slug'])}" for d in f["depends_on"]]
    chart += [f"  classDef {k} {v}" for k, v in COLOURS.items()] + ["```"]
    counts = {s: sum(1 for f in st["features"] if f["status"] == s) for s in FEATURE_STATUSES}
    summary = ", ".join(f"{n} {s.replace('_', ' ')}" for s, n in counts.items() if n)
    text = "\n".join([f"# Autonomous run: {st['status']}", "",
                      f"Branch `{st['base']['branch']}` from `{st['base']['from']}`. Spend ${st['spend_usd']:.2f} of "
                      f"${st['limits']['budget_usd']:.2f}, {st.get('hours', 0):.1f} h. {summary or 'no features yet'}."
                      + (f" Exit: {st['exit']['reason']}." if st.get("exit") else ""),
                      "", "Grey to do, blue running, green passed, amber waiting on you, red exited, purple split or skipped.",
                      "", *chart, "", *rows, ""])
    if not write_file:
        print(text)
    elif head_branch() == st["base"]["branch"]:
        write(f"{AUTO}/tracker.md", text)


# ---- entry -----------------------------------------------------------------------------------------------
def main(argv):
    if not argv:
        print(__doc__.strip())
        return 2
    cmd, rest = argv[0], argv[1:]
    try:
        if cmd == "card":
            if len(rest) != 1:
                raise Refuse("usage: card FILE")
            card = parse_card(open(rest[0], encoding="utf-8").read())
            print(json.dumps({k: v for k, v in card.items() if k != "body"}))
            return 0
        if cmd == "tracker":
            st = load_state()
            if not st:
                raise Refuse("no run state here")
            render_tracker(st)
            return 0
        commands = {"start": cmd_start, "approve": cmd_approve, "run": cmd_run, "resume": cmd_resume,
                    "status": cmd_status, "stop": cmd_stop}
        if cmd not in commands or rest:
            raise Refuse(f"unknown command {' '.join(argv)!r}; one of: {', '.join(commands)}, card FILE, tracker")
        try:
            return commands[cmd]()
        finally:
            if cmd in ("start", "approve"):
                unlock()
    except (Refuse, ValueError) as e:
        print(f"auto: {e}", file=sys.stderr)
        return 2
    except (RuntimeError, OSError) as e:
        print(f"auto: the driver stopped on an error: {e}. The run state is in .git/morphness/auto/state.json; fix "
              "the cause and run resume (or run, if the run still shows running).", file=sys.stderr)
        unlock()
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
