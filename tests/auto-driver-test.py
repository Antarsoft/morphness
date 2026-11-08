#!/usr/bin/env python3
"""Self-test for the autonomous module's driver (template/scripts/auto/). Each scenario builds a small repo with
the module on, puts a stub `claude` in MORPH_AUTO_CLAUDE that acts out a session (writes the docs, the feature
records and the card, then commits, or crashes, hits a usage limit, ...), runs the driver and checks the state,
the git history and the files it leaves. No network, no real claude. Prints one FAIL line per problem and exits 1
when there is any. Usage: python3 tests/auto-driver-test.py [scenario ...]"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(ROOT, "template")
failures = []

STUB = r'''#!/usr/bin/env python3
import json, os, subprocess, sys
args = sys.argv[1:]
if "--help" in args:
    print("--permission-prompts <target>\n--max-budget-usd <amount>\n--output-format <format>\n--model <model>")
    sys.exit(0)
plan = json.load(open(os.environ["STUB_PLAN"]))
calls_file = os.environ["STUB_CALLS"]
calls = json.load(open(calls_file)) if os.path.exists(calls_file) else []
# What Claude Code printed when its sign-in had expired (a real director log, 68 ms, nothing spent).
SIGNED_OUT = {"type": "result", "subtype": "success", "is_error": True, "duration_ms": 68, "num_turns": 0,
              "result": "Failed to authenticate: OAuth session expired and could not be refreshed",
              "terminal_reason": "api_error", "total_cost_usd": 0}
if args[:2] == ["auth", "status"]:
    calls.append({"key": "auth-status", "kind": "auth-status", "auto": ""})
    json.dump(calls, open(calls_file, "w"))
    print(json.dumps({"loggedIn": plan.get("logged_in", True), "authMethod": "claude.ai"}))
    sys.exit(0)
prompt = args[args.index("-p") + 1]
kind = os.environ.get("MORPH_AUTO_SESSION", "")
slug = os.environ.get("MORPH_AUTO_FEATURE", "")
key = slug or kind
n = sum(1 for c in calls if c["key"] == key)
model = args[args.index("--model") + 1] if "--model" in args else ""
calls.append({"key": key, "kind": kind, "model": model, "resume": "started again" in prompt,
              "auto": os.environ.get("MORPH_AUTO", ""), "budget": args[args.index("--max-budget-usd") + 1],
              "stream": "stream-json" in args})
json.dump(calls, open(calls_file, "w"))
steps = plan.get(key, ["ok" if kind == "preflight" else "pass"])
act = steps[min(n, len(steps) - 1)]
cost = plan.get("costs", {}).get(key, plan.get("cost", 1.0))

def out(is_error=False, subtype="success", result="done", code=0):
    print(json.dumps({"type": "result", "subtype": subtype, "is_error": is_error, "total_cost_usd": cost, "result": result}))
    sys.exit(code)

if act == "auth":
    print(json.dumps(SIGNED_OUT))
    sys.exit(1)
if kind == "preflight":
    out(result="OK")
if "stream-json" in args:   # one tool call before the work, as a streamed session shows it
    print(json.dumps({"type": "assistant", "message": {"content": [
        {"type": "tool_use", "name": "Write", "input": {"file_path": os.path.join(os.getcwd(), "docs/product/tech.md")}}]}}))
    sys.stdout.flush()

def w(p, text):
    os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
    open(p, "w").write(text)

def git(*a):
    subprocess.run(["git", *a], check=True, capture_output=True)

if act == "usage":
    out(True, "error_during_execution", "Claude usage limit reached", 1)
if act == "budget":
    out(True, "error_max_budget_usd", "budget")
if act == "crash":
    out(True, "error_during_execution", "boom", 1)
if kind in ("director",) and slug == "" and "re-planning" not in prompt and "compact" not in prompt:
    order = plan["order"] if act != "cycle" else "| # | Slug | Title | Milestone | Depends on | Risk |\n|---|---|---|---|---|---|\n| 1 | a | A | M1 | b | low |\n| 2 | b | B | M1 | a | low |\n"
    for d in ("product", "tech", "design", "finance"):
        w(f"docs/product/{d}.md", f"# {d}\n")
    w("docs/product/order.md", order)
    out()
if kind == "director":
    if act == "replan-add":
        w("docs/product/order.md", open("docs/product/order.md").read() + "| 9 | z | Z | M2 | - | low |\n")
    out()
if kind == "prune":
    w("_harness/prunes/2026-01-01-prune.md", "# Prune\n")
    out()
card = {"pass": "passed", "fakepass": "passed", "waiting": "waiting_owner", "escalate": "escalated", "split": "split",
        "splitbad": "split", "bug": "passed", "depart": "passed", "bugdepart": "passed", "nomode": "passed",
        "verdict": "passed", "verdictfail": "passed", "checkout-dev": "passed", "rate-crash": "passed"}[act]
if act == "rate-crash":
    out(True, "error_during_execution", "Implemented the 429 rate limit handler, then a test runner crashed", 1)
if act == "checkout-dev":
    git("checkout", "-q", "dev")
    w("oops.txt", "x\n")
    git("add", "oops.txt")
    git("commit", "-q", "-m", "oops")
    out()
lists = {"owner": [], "bugs": [], "split": []}
if act in ("waiting", "pass"):
    lists["owner"] = ["Sign in to the store account, e.g. App Store Connect: team ABC", "rule: decide the copy rule"]
if act == "split":
    lists["split"] = [f"{slug}-1 | First half | -", f"{slug}-2 | Second half | -"]
if act == "splitbad":
    lists["split"] = ["Bad_Slug | Nope | -"]
if act in ("bug", "bugdepart"):
    lists["bugs"] = ["a-1 | total is off by one | src/a-1.txt:42"] if slug != "b" else ["a | total is off | src/a.txt:7"]
mode = "" if act == "nomode" else "full"
departure = "yes" if act in ("depart", "bugdepart") else "no"
if act in ("pass", "bug", "depart", "bugdepart", "nomode"):
    w(f"_harness/features/{slug}/1/Plan/plan.md", "# Plan\n\n**Status:** passed  \n")
    w(f"_harness/features/{slug}/1/QA/qa-result.md", "## Verdict\n\n- **Result:** pass\n")
    w(f"src/{slug}.txt", f"{slug}\n")
if act in ("verdict", "verdictfail"):
    # QA wrote the verdict as a header line; verdictfail: round 1 passed, round 2 failed
    w(f"_harness/features/{slug}/1/Plan/plan.md", "# Plan\n\n**Status:** passed  \n")
    w(f"_harness/features/{slug}/1/QA/qa-result.md", "# QA result\n\n**Round:** 1\n**Verdict:** pass\n"
      + ("\n## Round 2\n\n**Verdict:** `fail`\n" if act == "verdictfail" else ""))
    w(f"src/{slug}.txt", f"{slug}\n")
if act == "fakepass":
    w(f"_harness/features/{slug}/1/Plan/plan.md", "# Plan\n\n**Status:** approved  \n")
    w(f"src/{slug}.txt", f"{slug}\n")
if os.path.exists("_harness/auto/exit.md"):
    calls[-1]["saw_exit"] = True
    json.dump(calls, open(calls_file, "w"))
calls[-1]["prompt_has_direction"] = "owner's direction" in prompt.lower()
json.dump(calls, open(calls_file, "w"))
body = "\n".join(["## Built", "", f"{slug} works.", "", "## Owner items", ""] + [f"- {i}" for i in lists["owner"] or ["none"]]
                 + ["", "## Bugs found", ""] + [f"- {i}" for i in lists["bugs"] or ["none"]]
                 + ["", "## Split into", ""] + [f"- {i}" for i in lists["split"] or ["none"]])
w(f"_harness/auto/cards/{slug}.md", f"---\nslug: {slug}\nstatus: {card}\nmode: {mode}\nqa_rounds: 1\ndeparture: {departure}\n---\n\n{body}\n")
git("add", "-A")
git("commit", "-q", "--allow-empty", "-m", f"{slug}: {act}")
out()
'''

ORDER = "| # | Slug | Title | Milestone | Depends on | Risk |\n|---|---|---|---|---|---|\n"


def order(*rows):
    return ORDER + "".join(f"| {i} | {s} | {s.upper()} | M1 | {', '.join(d) or '-'} | low |\n" for i, (s, d) in enumerate(rows, 1))


def make_repo(plan, budget=50, feature_budget=10):
    t = tempfile.mkdtemp(prefix="morph-auto-")
    for rel in ("scripts/lib/config.sh", "scripts/auto", "harness/templates/auto"):
        src, dst = os.path.join(TEMPLATE, rel), os.path.join(t, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        (shutil.copytree if os.path.isdir(src) else shutil.copy)(src, dst)
    files = {
        "harness.config.yml": textwrap.dedent(f"""\
            branches: {{ integration: dev, production: main }}
            roadmap:
              enabled: true
              file: docs/ROADMAP.md
              versions_dir: docs/versions
            modules: [roadmap, autonomous]
            checks:
              on_stop: []
            loop:
              feature_budget_usd: {feature_budget}
            auto:
              enabled: true
              branch: auto/v1
              budget_usd: {budget}
              max_features: 30
              max_hours: 24
              crash_retries: 1
              director_model: opus
              last_try_model: opus
              ledger_kb: 8
              usage_wait_minutes: 30
            """),
        "docs/brief.md": "# Brief\n",
        "docs/ROADMAP.md": "| Order | Version | Goal | Status | Marker | Document | Checklist |\n|---|---|---|---|---|---|---|\n"
                           "| 1 | v1 | First | next | **NEXT** | [v1](versions/v1/v1.md) | [checklist](versions/v1/checklist.md) |\n",
        "docs/versions/v1/v1.md": "# v1\n",
        "docs/versions/v1/checklist.md": "# v1 checklist\n\n## Code items\n",
        ".gitignore": "_harness/auto/logs/\n",
        "stub-claude": STUB,
    }
    for rel, text in files.items():
        p = os.path.join(t, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, "w").write(text)
    os.chmod(os.path.join(t, "stub-claude"), 0o755)
    json.dump(plan, open(os.path.join(t, ".stub-plan.json"), "w"))
    with open(os.path.join(t, ".git-info-exclude"), "w") as f:
        f.write(".stub-plan.json\n.stub-calls.json\nstub-claude\n")
    for cmd in (["git", "init", "-q", "-b", "dev"], ["git", "config", "user.name", "Owner Test"],
                ["git", "config", "user.email", "owner@example.com"], ["git", "config", "commit.gpgsign", "false"]):
        subprocess.run(cmd, cwd=t, check=True)
    os.makedirs(os.path.join(t, ".git/info"), exist_ok=True)
    shutil.move(os.path.join(t, ".git-info-exclude"), os.path.join(t, ".git/info/exclude"))
    subprocess.run(["git", "add", "-A"], cwd=t, check=True)
    subprocess.run(["git", "commit", "-q", "-m", "init"], cwd=t, check=True)
    return t


def drive(t, *args, extra_env=None):
    env = {k: v for k, v in os.environ.items() if not k.startswith(("CLAUDE", "MORPH_AUTO"))}
    env.update({"MORPH_AUTO_CLAUDE": os.path.join(t, "stub-claude"), "STUB_PLAN": os.path.join(t, ".stub-plan.json"),
                "STUB_CALLS": os.path.join(t, ".stub-calls.json"), "MORPH_AUTO_WAIT_SCALE": "0"})
    env.update(extra_env or {})
    return subprocess.run(["bash", "scripts/auto/run.sh", *args], cwd=t, capture_output=True, text=True, env=env)


def state(t):
    common = subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"], cwd=t,
                            capture_output=True, text=True).stdout.strip()
    return json.load(open(os.path.join(common, "morphness/auto/state.json")))


def calls(t):
    p = os.path.join(t, ".stub-calls.json")
    return json.load(open(p)) if os.path.exists(p) else []


def check(name, cond, msg):
    if not cond:
        failures.append(f"FAIL auto {name}: {msg}")


def statuses(t):
    return {f["slug"]: f["status"] for f in state(t)["features"]}


def full_run(t):
    r1, r2, r3 = drive(t, "start"), drive(t, "approve"), drive(t, "run")
    return r1, r2, r3


def scenario_happy():
    t = make_repo({"order": order(("a", []), ("b", ["a"]))})
    r1, r2, r3 = full_run(t)
    check("happy", r1.returncode == 0 and r2.returncode == 0, f"start/approve exit {r1.returncode}/{r2.returncode}: {r1.stderr}{r2.stderr}")
    check("happy", r3.returncode == 0, f"run exit {r3.returncode}: {r3.stdout[-300:]}{r3.stderr[-300:]}")
    st = state(t)
    check("happy", st["status"] == "done", f"status {st['status']}")
    check("happy", statuses(t) == {"a": "passed", "b": "passed"}, f"features {statuses(t)}")
    log = subprocess.run(["git", "log", "--oneline", "auto/v1"], cwd=t, capture_output=True, text=True).stdout
    check("happy", "merge feature/a" in log and "merge feature/b" in log, f"no merge commits on auto/v1: {log}")
    dev = subprocess.run(["git", "log", "--oneline", "dev"], cwd=t, capture_output=True, text=True).stdout
    check("happy", len(dev.splitlines()) == 1, "the integration branch changed")
    tracker = open(os.path.join(t, "_harness/auto/tracker.md")).read()
    check("happy", "flowchart TD" in tracker and "classDef passed" in tracker and "f_a --> f_b" in tracker, "tracker lacks the flowchart")
    check("happy", "approved by Owner Test" in log, "approval commit missing")
    ledger = open(os.path.join(t, "_harness/auto/ledger.md")).read()
    check("happy", "## a (A)" in ledger and "## b (B)" in ledger, "ledger misses a card")
    checklist = open(os.path.join(t, "docs/versions/v1/checklist.md")).read()
    check("happy", "## Needs you" in checklist and "Sign in to the store account, e.g. App Store Connect: team ABC (from `a`)" in checklist
          and "## Harness changes" in checklist and "rule: decide the copy rule" in checklist.split("## Harness changes")[1],
          f"v1_items not copied: {checklist}")
    committed = json.loads(subprocess.run(["git", "show", "auto/v1:_harness/auto/state.json"], cwd=t,
                                          capture_output=True, text=True).stdout)
    check("happy", committed["status"] == "done", "committed state snapshot is stale")
    cs = calls(t)
    check("happy", all(c["auto"] == "1" for c in cs if c["kind"] not in ("preflight", "auth-status")),
          "a session ran without MORPH_AUTO=1")
    check("happy", any(c["kind"] == "preflight" for c in cs) and all(c.get("stream", True) for c in cs
          if c["kind"] not in ("preflight", "auth-status")), "no sign-in check, or a session that isn't streamed")
    check("happy", [c for c in cs if c["kind"] == "director"][0]["model"] == "opus", "director not on director_model")
    check("happy", all(c["budget"] == "15.00" for c in cs if c["kind"] == "feature"), "session cap isn't 1.5 x feature budget")
    check("happy", not subprocess.run(["git", "status", "--porcelain"], cwd=t, capture_output=True, text=True).stdout.strip(),
          "the run left the tree dirty")
    check("happy", os.path.exists(os.path.join(t, "_harness/auto/exit.md")), "no exit note at done")


def scenario_waiting():
    t = make_repo({"order": order(("a", []), ("b", ["a"]), ("c", [])), "a": ["waiting"]})
    full_run(t)
    st = state(t)
    check("waiting", st["status"] == "done_waiting", f"status {st['status']}")
    check("waiting", statuses(t) == {"a": "waiting_owner", "b": "waiting_owner", "c": "passed"}, f"features {statuses(t)}")
    log = subprocess.run(["git", "log", "--oneline", "auto/v1"], cwd=t, capture_output=True, text=True).stdout
    check("waiting", "merge feature/a" not in log, "a waiting feature was merged")
    check("waiting", os.path.exists(os.path.join(t, "_harness/auto/cards/a.md")), "the waiting card isn't on the run branch")


def scenario_crash():
    t = make_repo({"order": order(("a", [])), "a": ["crash", "pass"]})
    *_, r = full_run(t)
    check("crash", r.returncode == 0 and statuses(t) == {"a": "passed"}, f"exit {r.returncode}, {statuses(t)}")
    cs = [c for c in calls(t) if c["key"] == "a"]
    check("crash", len(cs) == 2 and cs[1]["resume"] and cs[1]["model"] == "opus" and not cs[0]["model"],
          f"retry wasn't a resume on the last-try model: {cs}")


def scenario_two_crashes():
    t = make_repo({"order": order(("a", [])), "a": ["crash", "crash"]})
    *_, r = full_run(t)
    check("two-crashes", r.returncode == 1 and state(t)["status"] == "exited", f"exit {r.returncode}")
    check("two-crashes", "crashed 2 times" in open(os.path.join(t, "_harness/auto/exit.md")).read(), "exit note lacks the reason")


def scenario_escalate():
    t = make_repo({"order": order(("a", [])), "a": ["escalate", "pass"]})
    *_, r = full_run(t)
    note = open(os.path.join(t, "_harness/auto/exit.md")).read()
    check("escalate", r.returncode == 1 and "## Owner direction" in note and "**You need to:**" in note, f"exit {r.returncode}: {note}")
    r = drive(t, "resume")
    check("escalate", r.returncode == 2 and "Owner direction" in r.stderr, f"resume without a direction: {r.stderr}")
    p = os.path.join(t, "_harness/auto/exit.md")
    open(p, "a").write("Keep the old layout and drop the animation.\n")
    subprocess.run(["git", "commit", "-qam", "direction"], cwd=t, check=True)
    r = drive(t, "resume")
    cs = [c for c in calls(t) if c["key"] == "a"]
    check("escalate", r.returncode == 0 and statuses(t) == {"a": "passed"} and cs[-1]["resume"]
          and cs[-1]["prompt_has_direction"], f"resume: {r.stdout[-300:]} {cs[-1]}")


def scenario_budget():
    t = make_repo({"order": order(("a", []), ("b", [])), "cost": 1.0, "costs": {"director": 0}}, budget=1.5, feature_budget=1)
    *_, r = full_run(t)
    check("budget", r.returncode == 1 and statuses(t) == {"a": "passed", "b": "todo"}, f"exit {r.returncode} {statuses(t)}")
    check("budget", "run budget" in state(t)["exit"]["reason"], f"reason {state(t)['exit']}")


def scenario_feature_budget():
    t = make_repo({"order": order(("a", [])), "a": ["budget"]})
    *_, r = full_run(t)
    check("feature-budget", r.returncode == 1 and "spent its budget" in state(t)["exit"]["reason"], f"{state(t)['exit']}")
    check("feature-budget", len([c for c in calls(t) if c["key"] == "a"]) == 1, "a budget stop was retried as a crash")


def scenario_usage():
    t = make_repo({"order": order(("a", [])), "a": ["usage", "pass"]})
    *_, r = full_run(t)
    f = state(t)["features"][0]
    check("usage", r.returncode == 0 and f["status"] == "passed" and f["tries"]["crashes"] == 0, f"{f}")


def scenario_refusals():
    t = make_repo({"order": order(("a", []))})
    r = drive(t, "start", extra_env={"CLAUDECODE": "1"})
    check("refuse", r.returncode == 2 and "terminal" in r.stderr, f"inside a session: {r.returncode} {r.stderr}")
    brief = os.path.join(t, "docs/brief.md")
    open(brief, "a").write("draft\n")
    r = drive(t, "start")
    check("refuse", r.returncode == 2 and "working tree" in r.stderr, f"dirty tree: {r.stderr}")
    subprocess.run(["git", "checkout", "--", "docs/brief.md"], cwd=t, check=True)
    cfg = os.path.join(t, "harness.config.yml")
    text = open(cfg).read()
    open(cfg, "w").write(text.replace("budget_usd: 50", "budget_usd: 0"))
    subprocess.run(["git", "commit", "-qam", "zero"], cwd=t, check=True)
    r = drive(t, "start")
    check("refuse", r.returncode == 2 and "budget_usd is 0" in r.stderr, f"zero budget: {r.stderr}")
    r = drive(t, "run")
    check("refuse", r.returncode == 2, "run without a started run didn't refuse")


def scenario_bad_order():
    t = make_repo({"order": "", "director": ["cycle"]})
    r = drive(t, "start")
    check("bad-order", r.returncode == 1 and state(t)["status"] == "docs_failed" and "cycle" in r.stdout,
          f"{r.returncode} {r.stdout[-200:]}")
    check("bad-order", len([c for c in calls(t) if c["kind"] == "director"]) == 2, "the director got no second try")


def scenario_fake_pass():
    t = make_repo({"order": order(("a", [])), "a": ["fakepass"]})
    *_, r = full_run(t)
    check("fake-pass", r.returncode == 1 and "Status is not passed" in state(t)["exit"]["reason"], f"{state(t)['exit']}")


def scenario_verdict_shapes():
    sys.path.insert(0, os.path.join(TEMPLATE, "scripts/auto"))
    import driver
    cases = [("## Verdict\n\n- **Result:** pass\n- **Deferred to local run:** none\n\n### Blocking issues (if fail)\n", "pass"),
             ("## Verdict\n\n**pass.** All 5 ACs pass.\n", "pass"),
             ("**Round:** 1\n**Verdict:** pass\n\n## Acceptance criteria\n\n| 1 | fail |\n", "pass"),
             ("**Verdict:** pass\n\n## Round 2\n\n**Verdict:** fail\n", "fail"),
             ("## Verdict\n\n- **Result:** fail\n\n## Notes\n\npass later\n", "fail"),
             ("- **Result:** reproduced.\n", None)]
    for text, want in cases:
        got = driver.qa_verdict(text)
        check("verdict-shapes", got == want, f"{text!r}: {got} != {want}")


def scenario_verdict_header():
    t = make_repo({"order": order(("a", [])), "a": ["verdict"]})
    *_, r = full_run(t)
    check("verdict-header", r.returncode == 0 and state(t)["features"][0]["status"] == "passed", f"{r.stderr[-300:]}")
    t = make_repo({"order": order(("a", [])), "a": ["verdictfail"]})
    *_, r = full_run(t)
    check("verdict-header-fail", r.returncode == 1 and "verdict is not pass" in state(t)["exit"]["reason"], f"{state(t)['exit']}")


def scenario_split_and_bug():
    t = make_repo({"order": order(("a", []), ("b", ["a"])), "a": ["split"], "a-2": ["bug"]})
    *_, r = full_run(t)
    st = statuses(t)
    check("split", r.returncode == 0 and st.get("a") == "split" and st.get("a-1") == "passed" and st.get("a-2") == "passed"
          and st.get("b") == "passed", f"exit {r.returncode} {st}")
    b = next(f for f in state(t)["features"] if f["slug"] == "b")
    check("split", {"a-1", "a-2"} <= set(b["depends_on"]) and "a" not in b["depends_on"], f"b's dependencies: {b['depends_on']}")
    fixes = [f for f in state(t)["features"] if (f.get("inserted_by") or "").startswith("bug:")]
    check("bug", len(fixes) == 1 and fixes[0]["status"] == "passed", f"fix items {fixes}")


def scenario_departure():
    t = make_repo({"order": order(("a", []), ("b", [])), "a": ["depart"], "director": ["pass", "replan-add"]})
    *_, r = full_run(t)
    st = state(t)
    check("departure", r.returncode == 0 and len(st["replans"]) == 1 and "z" in statuses(t), f"{st['replans']} {statuses(t)}")


def scenario_stop():
    t = make_repo({"order": order(("a", []), ("b", []))})
    drive(t, "start")
    drive(t, "approve")
    drive(t, "stop")
    r = drive(t, "run")
    check("stop", r.returncode == 1 and "stop file" in state(t)["exit"]["reason"] and statuses(t)["a"] == "todo", f"{state(t)['exit']}")


def scenario_killed_driver():
    t = make_repo({"order": order(("a", []), ("b", []))})
    drive(t, "start"); drive(t, "approve")
    common = subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"], cwd=t,
                            capture_output=True, text=True).stdout.strip()
    sp = os.path.join(common, "morphness/auto/state.json")
    st = json.load(open(sp))
    st["features"][0]["status"] = "running"
    json.dump(st, open(sp, "w"))
    r = drive(t, "run")
    a = [c for c in calls(t) if c["key"] == "a"]
    check("killed", r.returncode == 0 and statuses(t) == {"a": "passed", "b": "passed"} and a and a[0]["resume"],
          f"{r.returncode} {statuses(t)} {a}")


def scenario_director_fails():
    t = make_repo({"order": order(("a", [])), "director": ["crash", "pass"]})
    r = drive(t, "start")
    check("director-fails", r.returncode == 1 and state(t)["status"] == "docs_failed", f"{r.returncode} {state(t)['status']}")
    r = drive(t, "resume")
    check("director-fails", r.returncode == 2, "resume accepted a run that was never approved")
    r = drive(t, "start")
    check("director-fails", r.returncode == 0 and state(t)["status"] == "awaiting_approval", f"retry: {r.stdout}{r.stderr}")


def scenario_budget_resume():
    t = make_repo({"order": order(("a", [])), "a": ["budget", "pass"], "costs": {"a": 14, "director": 0}}, budget=100)
    *_, r = full_run(t)
    check("budget-resume", r.returncode == 1 and "spent its budget" in state(t)["exit"]["reason"], f"{state(t)['exit']}")
    r = drive(t, "resume")
    check("budget-resume", r.returncode == 0 and statuses(t) == {"a": "passed"}, f"{r.stdout[-300:]} {statuses(t)}")


def scenario_replan_keeps_fixes():
    t = make_repo({"order": order(("a", []), ("b", ["a"]), ("c", ["a"])), "b": ["bugdepart"]})
    *_, r = full_run(t)
    fixes = [f for f in state(t)["features"] if (f.get("inserted_by") or "").startswith("bug:")]
    check("replan-fixes", r.returncode == 0 and len(state(t)["replans"]) == 1 and len(fixes) == 1
          and fixes[0]["status"] == "passed", f"{r.returncode} {statuses(t)} {state(t)['replans']}")


def scenario_rate_text_is_a_crash():
    t = make_repo({"order": order(("a", [])), "a": ["rate-crash", "pass"]})
    *_, r = full_run(t)
    f = state(t)["features"][0]
    check("rate-text", r.returncode == 0 and f["tries"]["crashes"] == 1, f"{f['tries']}")


def scenario_stop_file_in_tree():
    t = make_repo({"order": order(("a", [])), })
    drive(t, "start"); drive(t, "approve")
    os.makedirs(os.path.join(t, "_harness/auto"), exist_ok=True)
    open(os.path.join(t, "_harness/auto/STOP"), "w").write("stop\n")
    r = drive(t, "run")
    check("stop-tree", r.returncode == 1 and "stop file" in state(t)["exit"]["reason"], f"{state(t)['exit']}")


def scenario_session_moves_branch():
    t = make_repo({"order": order(("a", [])), "a": ["checkout-dev"]})
    *_, r = full_run(t)
    check("moves-branch", r.returncode == 1 and "changed branch dev" in state(t)["exit"]["reason"], f"{state(t)['exit']}")


def scenario_done_waiting_resume():
    t = make_repo({"order": order(("a", []), ("b", ["a"])), "a": ["waiting", "pass"]})
    full_run(t)
    r = drive(t, "resume")
    check("waiting-resume", r.returncode == 0 and statuses(t) == {"a": "passed", "b": "passed"}, f"{r.stdout[-200:]} {statuses(t)}")


def scenario_bad_cards():
    t = make_repo({"order": order(("a", []), ("b", [])), "a": ["nomode", "nomode"]})
    *_, r = full_run(t)
    check("bad-card", r.returncode == 1 and "mode" in state(t)["exit"]["reason"], f"{state(t)['exit']}")
    t = make_repo({"order": order(("a", [])), "a": ["splitbad", "splitbad"]})
    *_, r = full_run(t)
    check("bad-split", r.returncode == 1 and "kebab" in state(t)["exit"]["reason"], f"{state(t)['exit']}")


def scenario_existing_branch():
    t = make_repo({"order": order(("a", []))})
    drive(t, "start")
    subprocess.run(["git", "branch", "feature/a", "dev"], cwd=t, check=True)
    r = drive(t, "approve")
    check("existing-branch", r.returncode == 2 and "feature/a" in r.stderr, f"{r.returncode} {r.stderr}")


def scenario_card_cli():
    t = make_repo({"order": order(("a", []))})
    p = os.path.join(t, "card.md")
    open(p, "w").write("---\nslug: a\nstatus: passed\nmode: full\nqa_rounds: 2\ndeparture: no\n---\n\n## Owner items\n\n"
                       "- Buy a domain, e.g. example.com, and set DNS\n- rule: keep copy short\n\n## Bugs found\n\n"
                       "- b | off by one | src/b.ts:42\n")
    r = subprocess.run(["bash", "scripts/auto/card.sh", p], cwd=t, capture_output=True, text=True)
    out = json.loads(r.stdout or "{}")
    check("card-cli", r.returncode == 0 and len(out.get("v1_items", [])) == 2 and out["bugs_found"][0]["where"] == "src/b.ts:42",
          f"{r.returncode} {r.stdout} {r.stderr}")


def scenario_signed_out_outcome():
    sys.path.insert(0, os.path.join(TEMPLATE, "scripts/auto"))
    import driver
    real = {"type": "result", "subtype": "success", "is_error": True, "terminal_reason": "api_error", "total_cost_usd": 0,
            "result": "Failed to authenticate: OAuth session expired and could not be refreshed"}
    cases = [(1, real, "", "auth"),
             (1, {"is_error": True, "result": "Invalid API key · Please run /login"}, "", "auth"),
             (1, {}, "Error: Not logged in · Please run /login\n", "auth"),
             (1, {"is_error": True, "result": 'API Error: 401 {"type":"error","error":{"type":"authentication_error"}}'}, "", "auth"),
             (1, {"is_error": True, "result": "Added the OAuth login screen and a 401 handler, then the test runner crashed"}, "", "crash"),
             (0, {"is_error": False, "result": "Failed to authenticate users is now handled"}, "", "ok"),
             (1, {"is_error": True, "result": "Claude usage limit reached"}, "", "usage")]
    for code, out, err, want in cases:
        got = driver.outcome_of(code, out, err)
        check("signed-out-outcome", got == want, f"{out} {err!r}: {got} != {want}")
    stream = '{"type":"system"}\n' + json.dumps(real) + "\n"
    check("signed-out-outcome", driver.result_of(stream) == real, "result_of() missed the result line of a stream")


def scenario_signed_out_preflight():
    for plan, why in (({"preflight": ["auth"]}, "probe"), ({"logged_in": False}, "auth status")):
        t = make_repo({"order": order(("a", [])), **plan})
        r = drive(t, "start")
        branches = subprocess.run(["git", "branch", "--list", "auto/v1"], cwd=t, capture_output=True, text=True).stdout
        log = subprocess.run(["git", "log", "--all", "--oneline"], cwd=t, capture_output=True, text=True).stdout
        check("signed-out-preflight", r.returncode == 2 and "/login" in r.stderr and "run.sh start" in r.stderr,
              f"{why}: {r.returncode} {r.stderr}")
        check("signed-out-preflight", not branches.strip() and len(log.splitlines()) == 1, f"{why}: made {branches} {log}")
        check("signed-out-preflight", not [c for c in calls(t) if c["kind"] == "director"], f"{why}: a director ran")
        if why == "auth status":
            check("signed-out-preflight", not [c for c in calls(t) if c["kind"] == "preflight"], "probed after auth status said no")


def scenario_signed_out_director():
    t = make_repo({"order": order(("a", [])), "director": ["auth", "pass"]})
    r = drive(t, "start")
    log = subprocess.run(["git", "log", "--oneline", "auto/v1"], cwd=t, capture_output=True, text=True).stdout
    check("signed-out-director", r.returncode == 1 and state(t)["status"] == "docs_failed" and "/login" in r.stdout,
          f"{r.returncode} {r.stdout[-400:]}")
    check("signed-out-director", len(log.splitlines()) == 1 and "draft" not in log, f"misleading commit: {log}")
    r = drive(t, "start")
    check("signed-out-director", r.returncode == 0 and state(t)["status"] == "awaiting_approval", f"retry: {r.stdout}{r.stderr}")


def scenario_signed_out_feature():
    t = make_repo({"order": order(("a", [])), "a": ["auth", "pass"]})
    *_, r = full_run(t)
    st = state(t)
    f = st["features"][0]
    note = open(os.path.join(t, "_harness/auto/exit.md")).read()
    check("signed-out-feature", r.returncode == 1 and st["exit"]["reason"].startswith("signed out")
          and f["status"] == "todo" and f["tries"]["crashes"] == 0, f"{r.returncode} {st['exit']} {f}")
    check("signed-out-feature", "/login" in note and "run.sh resume" in note, f"exit note: {note}")
    check("signed-out-feature", len([c for c in calls(t) if c["key"] == "a"]) == 1, "the signed-out try was retried")
    r = drive(t, "resume")
    f = state(t)["features"][0]
    check("signed-out-feature", r.returncode == 0 and f["status"] == "passed" and f["tries"]["crashes"] == 0,
          f"resume: {r.stdout[-300:]} {f}")


def scenario_progress():
    t = make_repo({"order": order(("a", []))})
    r = drive(t, "start")
    check("progress", "director: session started" in r.stdout and "Write docs/product/tech.md" in r.stdout,
          f"no progress lines: {r.stdout[-400:]}")


SCENARIOS = {n[len("scenario_"):]: f for n, f in globals().items() if n.startswith("scenario_")}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(SCENARIOS)
    for name in wanted:
        try:
            SCENARIOS[name]()
        except Exception as e:  # a scenario that blows up is a failure, not a crash of the whole test
            failures.append(f"FAIL auto {name}: {type(e).__name__}: {e}")
    for f in failures:
        print(f)
    print(f"auto driver self-test: {len(wanted)} scenario(s), {len(failures)} problem(s)")
    sys.exit(1 if failures else 0)
