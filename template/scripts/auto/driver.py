#!/usr/bin/env python3
"""Driver for the autonomous module (harness/modules/autonomous/README.md). Started through scripts/auto/run.sh,
never by an agent. It keeps the run state in _harness/auto/state.json, starts one headless Claude Code session
per step (director, feature, prune), checks each feature's card against the feature's own records, merges passed
features into the run branch, and redraws the tracker. Standard library only.

Commands (run.sh passes them through):
  start      check the brief and budgets, create the run branch, run the director, check the order
  approve    record the owner's approval of docs/product/ and set the run going
  run        build features until the run ends or exits (start and approve don't run features)
  resume     after an exit: fresh tries for the stopped feature, then run
  status     print the tracker and spend
  stop       ask a running driver to exit after the current feature
  card FILE  check one card file and print its header as JSON (card.sh)
  tracker    redraw _harness/auto/tracker.md from state.json (tracker.sh)
Exit codes: 0 done or waiting for the owner's next step; 1 the run exited (see _harness/auto/exit.md); 2 a usage
error or a check that refused to start.
"""
import datetime
import hashlib
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
FEATURE_STATUSES = ("todo", "running", "passed", "waiting_owner", "exited", "split", "skipped")
USAGE_LIMIT = re.compile(r"usage limit|rate limit|limit reached|429|overloaded", re.I)


class Refuse(Exception):
    """A check that stops the driver before it changes anything (exit 2)."""


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
    tmp = p + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, p)


def git(*args, check=True):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)
    if check and r.returncode:
        raise RuntimeError(f"git {' '.join(args)} failed: {r.stderr.strip()[-400:]}")
    return r.stdout.strip()


def config(key, default=""):
    """Reads harness.config.yml with the kit's own reader, so the driver and the scripts agree on every value."""
    r = subprocess.run(["bash", "-c", '. scripts/lib/config.sh && config_get "$1"', "_", key],
                       cwd=ROOT, capture_output=True, text=True)
    value = r.stdout.strip()
    return value if value else default


def config_list(key):
    value = config(key)
    return [v.strip() for v in value.strip("[]").split(",") if v.strip()]


def number(key, default):
    try:
        return float(config(key, str(default)))
    except ValueError:
        raise Refuse(f"harness.config.yml {key} is not a number")


# ---- state -----------------------------------------------------------------------------------------------
def live_dir():
    """The live state lives in the git folder, outside every branch, so a feature session can never commit it;
    commit() copies a snapshot to _harness/auto/state.json on the run branch."""
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


def stop_requested():
    return any(os.path.exists(p) for p in (path(f"{AUTO}/STOP"), os.path.join(live_dir(), "STOP")))


def clear_stop():
    for p in (path(f"{AUTO}/STOP"), os.path.join(live_dir(), "STOP")):
        if os.path.exists(p):
            os.remove(p)


def on_run_branch(st):
    return git("rev-parse", "--abbrev-ref", "HEAD") == st["base"]["branch"]


def feature(st, slug):
    for f in st["features"]:
        if f["slug"] == slug:
            return f
    return None


def new_feature(row, inserted_by=None):
    return {"slug": row["slug"], "title": row.get("title", row["slug"]), "milestone": row.get("milestone", ""),
            "depends_on": list(row.get("depends_on", [])), "risk": row.get("risk", "low"), "status": "todo",
            "mode": "", "tries": {"crashes": 0, "qa_rounds": 0, "last_try": False}, "branch": f"feature/{row['slug']}",
            "merge_commit": "", "cost_usd": 0.0, "sessions": 0, "waiting_on": "", "inserted_by": inserted_by}


# ---- the order file --------------------------------------------------------------------------------------
def parse_order(text):
    """docs/product/order.md: one table | # | Slug | Title | Milestone | Depends on | Risk |. Returns rows or raises
    ValueError with every problem found, so the director's retry can fix them all at once."""
    rows, problems, header = [], [], None
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
        slug = rec.get("slug", "").strip("` ")
        deps = rec.get("depends on", "-").strip()
        rows.append({"slug": slug, "title": rec.get("title", ""), "milestone": rec.get("milestone", ""),
                     "depends_on": [] if deps in ("", "-", "none") else [d.strip("` ") for d in deps.split(",") if d.strip()],
                     "risk": rec.get("risk", "low").lower() or "low"})
    if header is None or not rows:
        problems.append("no feature table found")
    elif not {"slug", "title", "depends on"} <= set(header):
        problems.append(f"the table needs Slug, Title and Depends on columns, found {header}")
    seen = set()
    for r in rows:
        if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", r["slug"]):
            problems.append(f"slug {r['slug']!r} is not kebab-case")
        if r["slug"] in seen:
            problems.append(f"slug {r['slug']} is listed twice")
        seen.add(r["slug"])
        if r["risk"] not in ("low", "medium", "high"):
            problems.append(f"{r['slug']}: risk {r['risk']!r} is not low, medium or high")
    for r in rows:
        for d in r["depends_on"]:
            if d not in seen:
                problems.append(f"{r['slug']} depends on unknown {d}")
    if not problems and cycle(rows):
        problems.append(f"dependency cycle through {cycle(rows)}")
    if problems:
        raise ValueError("; ".join(problems))
    return rows


def cycle(rows):
    deps = {r["slug"]: r["depends_on"] for r in rows}
    state = {}

    def visit(s):
        if state.get(s) == 1:
            return s
        if state.get(s) == 2:
            return None
        state[s] = 1
        for d in deps.get(s, []):
            hit = visit(d)
            if hit:
                return hit
        state[s] = 2
        return None

    for s in deps:
        hit = visit(s)
        if hit:
            return hit
    return None


def docs_hash():
    h = hashlib.sha256()
    base = path("docs/product")
    for dirpath, _, files in sorted(os.walk(base)):
        for name in sorted(files):
            full = os.path.join(dirpath, name)
            h.update(os.path.relpath(full, base).encode())
            with open(full, "rb") as f:
                h.update(f.read())
    return h.hexdigest()[:16]


# ---- cards -----------------------------------------------------------------------------------------------
def flow_yaml(text):
    """The card header's values: scalars, [lists] and { maps } in YAML flow style, on one line each."""
    tokens = re.findall(r'"[^"]*"|\'[^\']*\'|[\[\]{},:]|[^\[\]{},:\s][^\[\]{},:]*', text)
    pos = 0

    def scalar(t):
        t = t.strip()
        if t[:1] in "\"'":
            return t[1:-1]
        low = t.lower()
        if low in ("true", "yes"):
            return True
        if low in ("false", "no"):
            return False
        if re.fullmatch(r"-?\d+", t):
            return int(t)
        return t

    def value():
        nonlocal pos
        t = tokens[pos]
        pos += 1
        if t == "[":
            out = []
            while tokens[pos] != "]":
                out.append(value())
                if tokens[pos] == ",":
                    pos += 1
            pos += 1
            return out
        if t == "{":
            out = {}
            while tokens[pos] != "}":
                k = scalar(tokens[pos])
                pos += 2  # key and ':'
                out[k] = value()
                if tokens[pos] == ",":
                    pos += 1
            pos += 1
            return out
        return scalar(t)

    if not tokens:
        return ""
    v = value()
    if pos != len(tokens):
        raise ValueError(f"unexpected {''.join(tokens[pos:])!r}")
    return v


def parse_card(text):
    m = re.match(r"\A---\n(.*?)\n---\n?(.*)\Z", text, re.S)
    if not m:
        raise ValueError("no YAML header between --- lines")
    head = {}
    for line in m.group(1).splitlines():
        line = re.sub(r"\s+#.*$", "", line).rstrip()
        if not line.strip():
            continue
        k, sep, v = line.partition(":")
        if not sep:
            raise ValueError(f"header line without a key: {line!r}")
        try:
            head[k.strip()] = flow_yaml(v.strip())
        except (ValueError, IndexError) as e:
            raise ValueError(f"{k.strip()}: {e}")
    body = m.group(2).strip()
    problems = []
    if head.get("status") not in CARD_STATUSES:
        problems.append(f"status {head.get('status')!r} is not one of {', '.join(CARD_STATUSES)}")
    for key in ("split_into", "bugs_found", "v1_items"):
        head.setdefault(key, [])
        if not isinstance(head[key], list):
            problems.append(f"{key} is not a list")
    head["departure"] = head.get("departure") in (True, "yes")
    if head.get("status") == "split":
        if not head["split_into"] or not all(isinstance(p, dict) and p.get("slug") for p in head["split_into"]):
            problems.append("status split needs split_into parts, each with a slug")
    for b in head["bugs_found"]:
        if not isinstance(b, dict) or not b.get("in") or not b.get("what"):
            problems.append(f"bugs_found item {b!r} needs in and what")
    if len(body.splitlines()) > 40:
        problems.append(f"the body has {len(body.splitlines())} lines, over 40")
    if problems:
        raise ValueError("; ".join(problems))
    head["body"] = body
    return head


def records_say_passed(slug, mode):
    """A passed card counts only when the mode's own record agrees (README § The card and the ledger)."""
    base = path(f"_harness/features/{slug}")
    versions = sorted((int(v) for v in os.listdir(base) if v.isdigit()), reverse=True) if os.path.isdir(base) else []
    if mode in ("light", "plain") or (not versions and mode in ("", "small-bug")):
        return True, "light mode: the merge's checks decide"
    if not versions:
        return False, f"no _harness/features/{slug}/<version>/ folder"
    v = f"_harness/features/{slug}/{versions[0]}"
    plan = read(f"{v}/Plan/plan.md", "")
    if not re.search(r"^\*\*Status:\*\*\s*passed\b", plan, re.M):
        return False, f"{v}/Plan/plan.md Status is not passed"
    if mode == "small":
        check = plan.split("## Check", 1)[1] if "## Check" in plan else ""
        return (bool(re.search(r"\S", re.sub(r"\*[^*]*\*", "", check))), f"{v}/Plan/plan.md § Check is empty")
    qa = read(f"{v}/QA/qa-result.md", "")
    results = re.findall(r"\*\*Result:\*\*\s*(pass|fail)\b", qa)
    if not results or results[-1] != "pass":
        return False, f"{v}/QA/qa-result.md verdict is not pass"
    return True, "records agree"


# ---- sessions --------------------------------------------------------------------------------------------
def claude_bin():
    return os.environ.get("MORPH_AUTO_CLAUDE", "claude")


def fill(template, values):
    text = read(f"{TEMPLATES}/{template}")
    text = re.sub(r"\A<!--.*?-->\n*", "", text, flags=re.S)
    for k, v in values.items():
        text = text.replace(f"%{k}%", str(v))
    return text


def session(st, kind, prompt, label, model="", budget=None):
    """One headless session. Returns (outcome, cost, result text). outcome: ok | crash | usage | budget."""
    logs = os.path.join(live_dir(), "logs")
    os.makedirs(logs, exist_ok=True)
    cap = budget if budget is not None else st["limits"]["session_cap_usd"]
    cmd = [claude_bin(), "-p", prompt, "--output-format", "json", "--permission-prompts", "none",
           "--max-budget-usd", f"{cap:.2f}"]
    if model:
        cmd += ["--model", model]
    env = dict(os.environ, MORPH_AUTO="1", MORPH_AUTO_FEATURE=label if kind == "feature" else "",
               MORPH_AUTO_SESSION=kind)
    log = os.path.join(logs, f"{label}-{st.get('session_count', 0) + 1}.json")
    st["session_count"] = st.get("session_count", 0) + 1
    try:
        r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, env=env)
    except OSError as e:
        return "crash", 0.0, f"could not start {claude_bin()}: {e}"
    with open(log, "w", encoding="utf-8") as f:
        f.write(r.stdout)
        if r.stderr:
            f.write("\n--- stderr ---\n" + r.stderr[-4000:])
    out = {}
    for candidate in (r.stdout.strip(), (r.stdout.strip().splitlines() or [""])[-1]):
        try:
            out = json.loads(candidate)
            break
        except json.JSONDecodeError:
            continue
    if not isinstance(out, dict):
        out = {}
    cost = float(out.get("total_cost_usd") or 0.0)
    text = str(out.get("result") or r.stderr[-400:])
    st["spend_usd"] = round(st.get("spend_usd", 0.0) + cost, 4)
    subtype = str(out.get("subtype", ""))
    if "budget" in subtype:
        return "budget", cost, text
    if r.returncode or out.get("is_error"):
        if USAGE_LIMIT.search(text) or USAGE_LIMIT.search(subtype):
            return "usage", cost, text
        return "crash", cost, text
    return "ok", cost, text


def with_usage_wait(st, run_once):
    """Runs run_once() again after a usage limit, waiting auto.usage_wait_minutes, doubling up to 4 hours."""
    wait = max(1.0, number("auto.usage_wait_minutes", 30))
    while True:
        outcome, cost, text = run_once()
        if outcome != "usage":
            return outcome, cost, text
        say(f"usage limit; waiting {wait:.0f} minutes (this try doesn't count)")
        save_state(st)
        time.sleep(wait * 60 * float(os.environ.get("MORPH_AUTO_WAIT_SCALE", "1")))
        wait = min(wait * 2, 240)


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
    if need_clean and git("status", "--porcelain"):
        raise Refuse("the working tree has changes: commit or stash them first")
    if shutil.which(claude_bin()) is None and not os.path.isfile(claude_bin()):
        raise Refuse(f"{claude_bin()} is not on PATH")
    help_text = subprocess.run([claude_bin(), "--help"], capture_output=True, text=True).stdout
    if "--permission-prompts" not in help_text or "--max-budget-usd" not in help_text:
        raise Refuse("this Claude Code has no --permission-prompts or --max-budget-usd: update it first")


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
    vdir = config("roadmap.versions_dir", "docs/versions")
    roadmap = read(config("roadmap.file", "docs/ROADMAP.md"), "")
    for line in roadmap.splitlines():
        if "**NEXT**" in line:
            m = re.search(r"\]\(([^)]*?)/[^/)]+\.md\)", line)
            if m:
                return os.path.normpath(os.path.join(os.path.dirname(config("roadmap.file", "docs/ROADMAP.md")), m.group(1)))
            ids = re.findall(r"`([^`]+)`", line)
            if ids:
                return f"{vdir}/{ids[0]}"
    return f"{vdir}/<id>"


def checklist_path():
    vdir = version_dir()
    return f"{vdir}/checklist.md" if "<id>" not in vdir else None


# ---- commands --------------------------------------------------------------------------------------------
def cmd_start():
    preflight()
    lim = limits()
    if not os.path.isfile(path("docs/brief.md")):
        raise Refuse("no docs/brief.md: write it from harness/templates/auto/brief.md first")
    st = load_state()
    if st and st["status"] not in ("done", "done_waiting"):
        raise Refuse(f"a run is already {st['status']} ({STATE}); use approve, run, resume or status")
    run_branch = config("auto.branch", "auto/v1")
    protected = {config("branches.integration"), config("branches.production")} | set(env_branches())
    if run_branch in protected:
        raise Refuse(f"auto.branch {run_branch} is the integration, production or an environment branch")
    base = config("branches.integration") or git("rev-parse", "--abbrev-ref", "HEAD")
    if git("rev-parse", "--verify", "--quiet", run_branch, check=False):
        raise Refuse(f"branch {run_branch} already exists: delete it or set another auto.branch")
    git("checkout", "-b", run_branch, base)
    st = {"schema": 1, "status": "docs", "started": now(), "limits": lim,
          "base": {"branch": run_branch, "from": base, "commit": git("rev-parse", "HEAD")},
          "approval": None, "spend_usd": 0.0, "hours": 0.0, "exit": None, "features": [], "replans": []}
    save_state(st)
    prompt = fill("director-prompt.md", {"ROADMAP_FILE": config("roadmap.file", "docs/ROADMAP.md"),
                                         "VERSION_DIR": version_dir()})
    rows, error = None, ""
    for attempt in (1, 2):
        outcome, _, text = with_usage_wait(st, lambda: session(st, "director", prompt + error, "director",
                                                               model=config("auto.director_model", "opus"),
                                                               budget=lim["session_cap_usd"]))
        if outcome != "ok":
            return finish(st, "exited", f"the director session ended with {outcome}: {text[:300]}")
        try:
            rows = parse_order(read("docs/product/order.md", ""))
            break
        except ValueError as e:
            error = f"\n\nYour docs/product/order.md had these problems; fix them and keep everything else: {e}"
            say(f"order check failed ({e}); asking the director once more" if attempt == 1 else f"order check failed: {e}")
    if rows is None:
        return finish(st, "exited", f"docs/product/order.md failed its check twice: {error.strip()}")
    st["features"] = [new_feature(r) for r in rows]
    st["status"] = "awaiting_approval"
    save_state(st)
    render_tracker(st)
    commit(st, "auto: product docs, order and run state for approval")
    full = sum(1 for f in st["features"] if f["risk"] != "low")
    estimate = full * 6 + (len(st["features"]) - full) * 1 + 3
    say(f"{len(st['features'])} features in docs/product/order.md ({full} likely full mode). Estimate about "
        f"${estimate}, budget ${lim['budget_usd']:.0f}. Read docs/product/, edit what you want, commit, then run: "
        "bash scripts/auto/run.sh approve")
    return 0


def env_branches():
    text = read("harness.config.yml", "")
    return re.findall(r"branch:\s*([A-Za-z0-9._/-]+)", text.split("environments:", 1)[1].split("\n\n", 1)[0]) \
        if "environments:" in text else []


def cmd_approve():
    preflight()
    st = load_state()
    if not st or st["status"] != "awaiting_approval":
        raise Refuse(f"nothing awaits approval (status {st and st['status']})")
    rows = parse_order(read("docs/product/order.md"))
    known = {f["slug"]: f for f in st["features"]}
    st["features"] = [known.get(r["slug"]) or new_feature(r) for r in rows]
    for f, r in zip(st["features"], rows):
        f.update({"title": r["title"], "milestone": r["milestone"], "depends_on": r["depends_on"], "risk": r["risk"]})
    owner = git("config", "user.name", check=False) or os.environ.get("USER", "the owner")
    st["approval"] = {"by": owner, "at": now()[:10], "product_doc_sha": docs_hash()}
    st["status"] = "running"
    st["limits"] = limits()
    save_state(st)
    render_tracker(st)
    commit(st, f"auto: product docs approved by {owner}")
    say("approved. Start the build with: bash scripts/auto/run.sh run")
    return 0


def cmd_stop():
    with open(os.path.join(live_dir(), "STOP"), "w", encoding="utf-8") as f:
        f.write(f"stop requested {now()}\n")
    say("stop requested: the run exits after the current feature")
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
    if not st or st["status"] != "exited":
        raise Refuse(f"nothing to resume (status {st and st['status']})")
    reason = (st.get("exit") or {}).get("reason", "")
    for f in st["features"]:
        if f["status"] in ("exited", "running"):
            f["status"] = "todo"
            f["tries"] = {"crashes": 0, "qa_rounds": f["tries"].get("qa_rounds", 0), "last_try": True,
                          "resume": reason, "escalated": reason.startswith("escalated")}
    st["limits"] = limits()
    st["status"], st["exit"] = "running", None
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
    run_branch = st["base"]["branch"]
    if git("rev-parse", "--abbrev-ref", "HEAD") != run_branch:
        git("checkout", run_branch)
    started = time.time() - st.get("hours", 0.0) * 3600
    while True:
        st["hours"] = round((time.time() - started) / 3600, 3)
        if stop_requested():
            clear_stop()
            return finish(st, "exited", "stop file: the owner asked the run to stop")
        lim = st["limits"]
        costs = [f["cost_usd"] for f in st["features"] if f["status"] == "passed" and f["cost_usd"]]
        next_cost = statistics.median(costs) if costs else lim["feature_budget_usd"]
        if st["spend_usd"] + next_cost > lim["budget_usd"]:
            return finish(st, "exited", f"run budget: ${st['spend_usd']:.2f} spent, the next feature would pass "
                                        f"${lim['budget_usd']:.2f}")
        if st["hours"] >= lim["max_hours"]:
            return finish(st, "exited", f"max hours: {st['hours']:.1f} of {lim['max_hours']}")
        if sum(1 for f in st["features"] if f["sessions"]) >= lim["max_features"] and next_todo(st) and \
                not next_todo(st)["sessions"]:
            return finish(st, "exited", f"max features: {lim['max_features']} started")
        if st["approval"] and docs_hash() != st["approval"]["product_doc_sha"]:
            replan(st, "the owner edited docs/product/ during the run", "")
        f = next_todo(st)
        if f is None:
            done = {x["slug"] for x in st["features"] if x["status"] in ("passed", "skipped")}
            for x in st["features"]:
                if x["status"] == "todo":  # its dependencies will never pass in this run
                    blocked = [d for d in x["depends_on"] if d not in done]
                    x["status"], x["waiting_on"] = "waiting_owner", f"waits on {', '.join(blocked)}"
            waiting = [x for x in st["features"] if x["status"] == "waiting_owner"]
            return finish(st, "done_waiting" if waiting else "done",
                          f"{len(waiting)} features wait on you" if waiting else "every feature passed")
        try:
            result = run_feature(st, f)
        except RuntimeError as e:
            f["status"] = "exited"
            return finish(st, "exited", f"driver error on {f['slug']}: {e}", f)
        if result is not None:
            return result


def next_todo(st):
    passed = {f["slug"] for f in st["features"] if f["status"] in ("passed", "skipped")}
    for f in st["features"]:
        if f["status"] == "todo" and all(d in passed for d in f["depends_on"]):
            return f
    return None


def run_feature(st, f):
    """Runs one feature to a card. Returns None to carry on, or the exit code when the run ends."""
    run_branch = st["base"]["branch"]
    branch = f["branch"]
    exists = git("rev-parse", "--verify", "--quiet", branch, check=False)
    f["status"] = "running"
    save_state(st)
    render_tracker(st)
    commit(st, f"auto: {f['slug']} running")
    git("checkout", branch) if exists else git("checkout", "-b", branch, run_branch)
    resumed = bool(exists) or f["tries"].get("resume")
    while True:
        resumed = resumed or f["tries"]["crashes"] > 0
        values = {"SLUG": f["slug"], "TITLE": f["title"], "MILESTONE": f["milestone"] or "-", "BRANCH": branch,
                  "RUN_BRANCH": run_branch, "OWNER": st["approval"]["by"], "APPROVED_AT": st["approval"]["at"],
                  "DEP_CARDS": ", ".join(f"`{AUTO}/cards/{d}.md`" for d in f["depends_on"]) or "none",
                  "WHY": f["tries"].get("resume") or ("the last session crashed" if f["tries"]["crashes"] else "resume"),
                  "QA_ROUNDS": f["tries"].get("qa_rounds", 0),
                  "NEW_VERSION": ("The last run escalated this feature: read the owner's direction in "
                                  f"`{AUTO}/exit.md` § Owner direction and start the feature's next version folder "
                                  "with it in § Request.") if f["tries"].get("escalated") else ""}
        prompt = fill("resume-prompt.md" if resumed else "feature-prompt.md", values)
        model = config("auto.last_try_model", "opus") if (resumed or f["tries"]["last_try"]) else ""
        outcome, cost, text = with_usage_wait(st, lambda: session(st, "feature", prompt, f["slug"], model=model))
        f["sessions"] += 1
        f["cost_usd"] = round(f["cost_usd"] + cost, 4)
        save_state(st)
        if outcome == "budget" or f["cost_usd"] > st["limits"]["feature_budget_usd"] * 1.5:
            git("checkout", run_branch)
            f["status"] = "exited"
            return finish(st, "exited", f"tries used up: {f['slug']} spent its budget (${f['cost_usd']:.2f})", f)
        card_rel = f"{AUTO}/cards/{f['slug']}.md"
        committed = git("show", f"HEAD:{card_rel}", check=False)
        card, problem = None, ""
        if outcome == "ok" and committed:
            try:
                card = parse_card(committed)
            except ValueError as e:
                problem = f"card {card_rel} is not valid: {e}"
        else:
            problem = text[:300] if outcome != "ok" else f"no committed {card_rel}"
        if git("status", "--porcelain"):
            git("stash", "push", "--include-untracked", "-m", f"auto: {f['slug']} uncommitted work after a session",
                check=False)
        if card is None:
            f["tries"]["crashes"] += 1
            if f["tries"]["crashes"] > st["limits"]["crash_retries"]:
                git("checkout", run_branch)
                f["status"] = "exited"
                return finish(st, "exited", f"tries used up: {f['slug']} crashed {f['tries']['crashes']} times "
                                            f"({problem})", f)
            say(f"{f['slug']}: crash ({problem}); starting it again from its last commit")
            f["tries"]["resume"] = f"the last session crashed: {problem}"
            save_state(st)
            continue
        return handle_card(st, f, card)


def handle_card(st, f, card):
    run_branch = st["base"]["branch"]
    f["mode"] = str(card.get("mode", ""))
    f["tries"]["qa_rounds"] = int(card.get("qa_rounds") or 0)
    status = card["status"]
    if status == "passed":
        ok, why = records_say_passed(f["slug"], f["mode"])
        if not ok:
            git("checkout", run_branch)
            f["status"] = "exited"
            return finish(st, "exited", f"tries used up: {f['slug']}'s card says passed but {why}", f)
    card_text = git("show", f"{f['branch']}:{AUTO}/cards/{f['slug']}.md")
    git("checkout", run_branch)
    if status in ("passed", "split"):
        shown = f"{AUTO}/cards/{f['slug']}.md"
        if git("ls-files", shown):  # a copy shown after an earlier stop: the branch's own card replaces it
            git("rm", "-q", shown)
            git("commit", "-q", "-m", f"auto: {f['slug']} card comes from its branch")
        git("merge", "--no-ff", "-m", f"auto: merge {f['branch']} ({status})", f["branch"])
        f["merge_commit"] = git("rev-parse", "HEAD")
    else:
        write(f"{AUTO}/cards/{f['slug']}.md", card_text + "\n")  # the work stays on its branch; the card is shown
    if status == "passed":
        failed = run_checks()
        if failed:
            git("reset", "--hard", "HEAD~1")
            f["status"] = "exited"
            return finish(st, "exited", f"tries used up: {f['slug']} passed QA but {failed} failed after the merge", f)
        f["status"] = "passed"
        ledger = read(LEDGER, "# Ledger\n\nPassed cards, in merge order. Features read their dependencies' cards, not this file.\n")
        write(LEDGER, ledger.rstrip() + f"\n\n## {f['slug']} ({f['title']})\n\n{card['body']}\n")
    elif status == "escalated":
        f["status"] = "exited"
        return finish(st, "exited", f"escalated: {f['slug']} failed QA past loop.qa_max_rounds or hit a stop "
                                    "only you can decide", f)
    elif status == "waiting_owner":
        f["status"], f["waiting_on"] = "waiting_owner", "; ".join(map(str, card["v1_items"])) or "see its steps file"
        for d in dependants(st, f["slug"]):
            if d["status"] == "todo":
                d["status"], d["waiting_on"] = "waiting_owner", f"waits on {f['slug']}"
    elif status == "split":
        f["status"] = "split"
        idx = st["features"].index(f)
        parts = []
        for p in card["split_into"]:
            part = new_feature({"slug": p["slug"], "title": p.get("title", p["slug"]), "milestone": f["milestone"],
                                "depends_on": list(p.get("depends_on") or f["depends_on"]), "risk": f["risk"]},
                               inserted_by=f"split:{f['slug']}")
            parts.append(part)
        st["features"][idx + 1:idx + 1] = parts
        last = parts[-1]["slug"]
        for d in st["features"]:
            if f["slug"] in d["depends_on"] and d not in parts:
                d["depends_on"] = [last if x == f["slug"] else x for x in d["depends_on"]]
    for i, b in enumerate(card["bugs_found"], 1):
        insert_fix(st, b, f"fix-{b['in']}-{len([x for x in st['features'] if (x.get('inserted_by') or '').startswith('bug:')]) + 1}")
    copy_v1_items(f, card)
    if card["departure"]:
        replan(st, f"{f['slug']}'s card says the plan departs from docs/product/", f"{AUTO}/cards/{f['slug']}.md")
    after_feature(st, f)
    return None


def dependants(st, slug):
    out, frontier = [], {slug}
    changed = True
    while changed:
        changed = False
        for d in st["features"]:
            if d not in out and frontier & set(d["depends_on"]):
                out.append(d)
                frontier.add(d["slug"])
                changed = True
    return out


def insert_fix(st, bug, slug):
    known = feature(st, bug["in"])
    row = {"slug": slug, "title": f"Fix in {bug['in']}: {bug['what']}"[:80], "milestone": "fix",
           "depends_on": [bug["in"]] if known and known["status"] in ("passed", "todo", "running") else [],
           "risk": "medium"}
    fix = new_feature(row, inserted_by=f"bug:{bug['in']}")
    users = [i for i, x in enumerate(st["features"]) if bug["in"] in x["depends_on"] and x["status"] == "todo"]
    if users:
        st["features"].insert(users[0], fix)
        for x in st["features"]:
            if bug["in"] in x["depends_on"] and x["status"] == "todo" and x is not fix:
                x["depends_on"].append(slug)
    else:
        first_todo = next((i for i, x in enumerate(st["features"]) if x["status"] == "todo"), len(st["features"]))
        st["features"].insert(first_todo, fix)


def copy_v1_items(f, card):
    path_ = checklist_path()
    if not card["v1_items"] or not path_:
        return
    text = read(path_, "")
    for section in ("## Needs you", "## Harness changes"):
        if section not in text:
            text = text.rstrip() + f"\n\n{section}\n"
    for item in card["v1_items"]:
        item = str(item).strip()
        rule = item.lower().startswith(("rule:", "human decides"))
        section = "## Harness changes" if rule else "## Needs you"
        line = f"- [ ] {item} (from `{f['slug']}`)"
        if line in text:
            continue
        head, sep, tail = text.partition(section + "\n")
        nxt = re.search(r"^## ", tail, re.M)
        cut = nxt.start() if nxt else len(tail)
        text = head + sep + tail[:cut].rstrip("\n") + ("\n" if tail[:cut].strip() else "") + line + "\n\n" + tail[cut:]
    write(path_, text.rstrip() + "\n")


def run_checks():
    names = config_list("checks.on_stop")
    if not names or not os.path.isfile(path("scripts/checks.sh")):
        return ""
    r = subprocess.run(["bash", "scripts/checks.sh", "run", *names], cwd=ROOT, capture_output=True, text=True)
    return "" if r.returncode == 0 else f"checks.on_stop ({', '.join(names)})"


def replan(st, reason, card):
    say(f"re-plan: {reason}")
    prompt = fill("replan-prompt.md", {"REASON": reason, "CARD": card or "none"})
    outcome, _, text = with_usage_wait(st, lambda: session(st, "director", prompt, "replan",
                                                           model=config("auto.director_model", "opus")))
    if outcome != "ok":
        say(f"re-plan session ended with {outcome}; keeping the current order")
    else:
        try:
            rows = parse_order(read("docs/product/order.md"))
            known = {f["slug"]: f for f in st["features"]}
            keep = [f for f in st["features"] if f["status"] != "todo"]
            st["features"] = keep + [known.get(r["slug"]) or new_feature(r, inserted_by="replan")
                                     for r in rows if r["slug"] not in {k["slug"] for k in keep}]
            for f in st["features"]:
                r = next((r for r in rows if r["slug"] == f["slug"]), None)
                if r and f["status"] == "todo":
                    f.update({"title": r["title"], "milestone": r["milestone"], "depends_on": r["depends_on"]})
        except ValueError as e:
            say(f"re-planned order.md failed its check ({e}); keeping the current order")
            git("checkout", "HEAD", "--", "docs/product/order.md", check=False)
    st["approval"]["product_doc_sha"] = docs_hash()
    st["replans"].append({"at": now(), "reason": reason})
    save_state(st)
    commit(st, f"auto: re-plan ({reason[:60]})")


def after_feature(st, f):
    r = subprocess.run(["bash", "scripts/prune-counter.sh"], cwd=ROOT, capture_output=True, text=True) \
        if os.path.isfile(path("scripts/prune-counter.sh")) else None
    if r is not None and "Prune is DUE" in r.stdout:
        before = set(os.listdir(path("_harness/prunes"))) if os.path.isdir(path("_harness/prunes")) else set()
        outcome, _, _ = with_usage_wait(st, lambda: session(st, "prune", fill("prune-prompt.md", {}), "prune"))
        after = set(os.listdir(path("_harness/prunes"))) if os.path.isdir(path("_harness/prunes")) else set()
        for name in sorted(after - before):
            copy_v1_items({"slug": "prune"}, {"v1_items": [f"rule: decide the prune proposal `_harness/prunes/{name}`"]})
        if outcome != "ok":
            say("the prune session didn't finish; the next feature's counter will ask again")
    if len(read(LEDGER, "").encode()) > number("auto.ledger_kb", 8) * 1024:
        prompt = (f"Autonomous run: compact `{LEDGER}` into `{AUTO}/ledger.next.md`: group the cards by milestone into "
                  "short summaries that keep every interface, path and decision later features need, and keep the last "
                  "five cards whole. Write only that file; no git.")
        outcome, _, _ = with_usage_wait(st, lambda: session(st, "director", prompt, "ledger",
                                                            model=config("auto.director_model", "opus")))
        if outcome == "ok" and os.path.isfile(path(f"{AUTO}/ledger.next.md")):
            os.replace(path(f"{AUTO}/ledger.next.md"), path(LEDGER))
    save_state(st)
    render_tracker(st)
    commit(st, f"auto: {f['slug']} {f['status']}")
    push(st["base"]["branch"], f["branch"])


def commit(st, message):
    """Commits the run's own files on the run branch, with a snapshot of the live state."""
    if not on_run_branch(st):
        return
    write(STATE, json.dumps(st, indent=2) + "\n")
    paths = [p for p in (AUTO, "docs/product", "docs/brief.md", "_harness/prunes", checklist_path(),
                         config("roadmap.file", "docs/ROADMAP.md"), version_dir()) if p and os.path.exists(path(p))]
    git("add", "--", *paths)
    if git("diff", "--cached", "--name-only"):
        git("commit", "-q", "-m", message)


def push(*branches):
    if not git("remote", check=False):
        return
    protected = {config("branches.integration"), config("branches.production")} | set(env_branches())
    for b in branches:
        if b in protected:
            continue
        r = subprocess.run(["git", "push", "-q", "-u", "origin", b], cwd=ROOT, capture_output=True, text=True)
        if r.returncode:
            say(f"push of {b} failed (the run carries on): {r.stderr.strip()[-200:]}")


def finish(st, status, reason, f=None):
    if not on_run_branch(st):
        if git("status", "--porcelain"):
            git("stash", "push", "--include-untracked", "-m", "auto: uncommitted work at the run's end", check=False)
        git("checkout", st["base"]["branch"])
    st["status"] = status
    st["exit"] = {"reason": reason, "at": now(), "feature": f["slug"] if f else ""}
    save_state(st)
    waiting = sum(1 for x in st["features"] if x["status"] == "waiting_owner")
    passed = sum(1 for x in st["features"] if x["status"] == "passed")
    todo = sum(1 for x in st["features"] if x["status"] == "todo")
    if status == "exited":
        action = {"escalated": "decide how the escalated feature goes on: write it under § Owner direction below",
                  "tries used up": "look at the feature's records and fix or redirect it",
                  "run budget": "raise auto.budget_usd or stop here", "max hours": "resume when ready",
                  "max features": "raise auto.max_features or stop here", "stop file": "resume when ready"}
        what = next((v for k, v in action.items() if reason.startswith(k)), "read the reason and resume when ready")
    elif status == "done_waiting":
        what = "do the items in the checklist's § Needs you, then resume the waiting features"
    else:
        what = "review the run branch and open the PR (bash scripts/auto/run.sh pr, from step 4 on)"
    lines = [f"# Run {status}: {what}", "", f"**You need to:** {what}.", "",
             f"- **Reason:** {reason}"]
    if f:
        v = f"_harness/features/{f['slug']}"
        lines.append(f"- **Feature:** {f['slug']} ({f['title']}), {f['status']}; records under `{v}/`, card "
                     f"`{AUTO}/cards/{f['slug']}.md`, branch `{f['branch']}`")
    lines += [f"- **Spend:** ${st['spend_usd']:.2f} of ${st['limits']['budget_usd']:.2f}"
              + (f"; this feature ${f['cost_usd']:.2f}" if f else ""),
              f"- **Progress:** {passed} passed, {waiting} waiting on you, {todo} to do",
              "- **Resume:** `bash scripts/auto/run.sh resume`" if status == "exited" else "", ""]
    if status == "exited" and reason.startswith("escalated"):
        lines += ["## Owner direction", "", "Write how the feature should go on; resume starts its next version with it.", ""]
    write(f"{AUTO}/exit.md", "\n".join(l for l in lines if l is not None).rstrip() + "\n")
    render_tracker(st)
    commit(st, f"auto: run {status}")
    push(st["base"]["branch"])
    say(f"run {status}: {reason}. See {AUTO}/exit.md")
    return 1 if status == "exited" else 0


# ---- tracker ---------------------------------------------------------------------------------------------
COLOURS = {"todo": "fill:#e5e7eb,stroke:#6b7280,color:#111827", "running": "fill:#bfdbfe,stroke:#1d4ed8,color:#1e3a8a",
           "passed": "fill:#bbf7d0,stroke:#15803d,color:#14532d", "waiting_owner": "fill:#fde68a,stroke:#b45309,color:#78350f",
           "exited": "fill:#fecaca,stroke:#b91c1c,color:#7f1d1d", "split": "fill:#e9d5ff,stroke:#7e22ce,color:#581c87",
           "skipped": "fill:#e9d5ff,stroke:#7e22ce,color:#581c87"}


def render_tracker(st, write_file=True):
    node = lambda s: "f_" + re.sub(r"[^A-Za-z0-9]", "_", s)
    rows = ["| # | Feature | Milestone | Status | Mode | QA rounds | Cost | Card |", "|---|---|---|---|---|---|---|---|"]
    for i, f in enumerate(st["features"], 1):
        card = f"[card](./cards/{f['slug']}.md)" if os.path.exists(path(f"{AUTO}/cards/{f['slug']}.md")) else "-"
        status = f["status"] + (f" ({f['waiting_on']})" if f["waiting_on"] and f["status"] == "waiting_owner" else "")
        rows.append(f"| {i} | `{f['slug']}` {f['title']} | {f['milestone'] or '-'} | {status} | {f['mode'] or '-'} | "
                    f"{f['tries'].get('qa_rounds', 0)} | ${f['cost_usd']:.2f} | {card} |")
    chart = ["```mermaid", "flowchart TD"]
    for f in st["features"]:
        label = f["title"].replace('"', "'")
        chart.append(f'  {node(f["slug"])}["{label}<br/>{f["status"]}"]:::{f["status"]}')
    for f in st["features"]:
        for d in f["depends_on"]:
            chart.append(f"  {node(d)} --> {node(f['slug'])}")
    chart += [f"  classDef {k} {v}" for k, v in COLOURS.items()] + ["```"]
    counts = {s: sum(1 for f in st["features"] if f["status"] == s) for s in FEATURE_STATUSES}
    summary = ", ".join(f"{n} {s.replace('_', ' ')}" for s, n in counts.items() if n)
    text = "\n".join([f"# Autonomous run: {st['status']}", "",
                      f"Branch `{st['base']['branch']}` from `{st['base']['from']}`. Spend ${st['spend_usd']:.2f} of "
                      f"${st['limits']['budget_usd']:.2f}, {st.get('hours', 0):.1f} h. {summary or 'no features yet'}."
                      + (f" Exit: {st['exit']['reason']}." if st.get("exit") else ""),
                      "", "Grey to do, blue running, green passed, amber waiting on you, red exited, purple split or skipped.",
                      "", *chart, "", *rows, ""])
    if write_file:
        if on_run_branch(st):
            write(f"{AUTO}/tracker.md", text)
    else:
        print(text)


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
        return commands[cmd]()
    except Refuse as e:
        print(f"auto: {e}", file=sys.stderr)
        return 2
    except ValueError as e:
        print(f"auto: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
