#!/usr/bin/env bash
# Prints what a feature's Claude Code work would cost at public API prices: the Technical Lead's
# session and every subagent it ran, split by role and model, then the `Cost ≈ $…` line the
# Technical Lead pastes into the retro, the learnings file and the hand-off (harness/SETUP.md
# § Retrospective → Feature cost). Read-only.
#
# Source: Claude Code's own session transcripts (~/.claude/projects/<repo>/*.jsonl and each
# session's subagents/), which record every API call with its model and tokens by kind. Token
# counts are exact; the dollars are an estimate from the price table (harness/MODEL_PRICES.md).
#
# Usage: bash scripts/feature-cost.sh [--since <ISO time>] [--branch <name>] [--session <id>[,<id>]]
#   (no option)  this session and its subagents (CLAUDE_CODE_SESSION_ID, else the newest transcript)
#   --since      only API calls at or after this time (UTC, e.g. 2026-10-15T09:30); use it when the
#                session did other work before this feature or task
#   --branch     every session in this repo, counting only calls made on that git branch (a feature
#                worked on across several sessions); calls made before the branch existed are missed
#   --session    these sessions instead of the current one

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 0

if ! command -v python3 >/dev/null 2>&1; then
  echo "Cost: not measured (python3 not found)"
  exit 0
fi

python3 - "$@" <<'PY'
import glob, json, os, re, sys
from datetime import datetime

args = sys.argv[1:]
opts = {"since": None, "branch": None, "session": None}
while args:
    flag = args.pop(0)
    key = flag.lstrip("-")
    if key not in opts or not args:
        print(f"usage: feature-cost.sh [--since <ISO time>] [--branch <name>] [--session <id>[,<id>]] (bad option: {flag})")
        sys.exit(0)
    opts[key] = args.pop(0)

# Config: cost: { track: true, prices: harness/MODEL_PRICES.md }
track, prices_path = True, "harness/MODEL_PRICES.md"
try:
    for line in open("harness.config.yml", encoding="utf-8"):
        m = re.match(r"\s*cost:\s*\{(.*)\}", line)
        if m:
            body = m.group(1)
            t = re.search(r"track:\s*(\w+)", body)
            p = re.search(r"prices:\s*([^,}\s]+)", body)
            track = not (t and t.group(1).lower() == "false")
            if p:
                prices_path = p.group(1).strip("\"'")
            break
except OSError:
    pass
if not track:
    print("Cost: not tracked (cost.track is false in harness.config.yml)")
    sys.exit(0)

# Price table: markdown rows `| model | input | output | cache write 5m | cache write 1h | cache read |`
# in $ per million tokens; a model cell like `claude-haiku-5-5 (prompt > 100000)` is the rate for
# requests whose whole prompt is above that many tokens.
prices, long_prices, as_of, fast_mult, search_price = {}, {}, "unknown date", 1.0, 0.0
try:
    for line in open(prices_path, encoding="utf-8"):
        m = re.search(r"Prices as of:\s*([0-9-]+)", line)
        if m:
            as_of = m.group(1)
        m = re.search(r"Fast mode multiplier:\s*([0-9.]+)", line)
        if m:
            fast_mult = float(m.group(1))
        m = re.search(r"Web search per request:\s*\$?([0-9.]+)", line)
        if m:
            search_price = float(m.group(1))
        cells = [c.strip().strip("`") for c in line.strip().strip("|").split("|")]
        if len(cells) >= 6 and cells[0].startswith("claude-"):
            try:
                rates = [float(c.replace("$", "")) for c in cells[1:6]]
            except ValueError:
                continue
            m = re.match(r"(\S+)\s*\(prompt\s*>\s*(\d+)\)", cells[0])
            if m:
                long_prices[m.group(1)] = (int(m.group(2)), rates)
            else:
                prices[cells[0]] = rates
except OSError:
    print(f"Cost: not measured (price table {prices_path} not found)")
    sys.exit(0)

def rates_for(model):
    # Longest table entry that the model id starts with (ids may carry a date or [1m] suffix).
    best = max((k for k in prices if model.startswith(k)), key=len, default=None)
    return best

# Transcripts: <config dir>/projects/<repo path with every non-alphanumeric as ->/
config_dir = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
repo = os.getcwd()
folder = os.path.join(config_dir, "projects", re.sub(r"[^A-Za-z0-9]", "-", repo))
if not os.path.isdir(folder):
    # Long paths are shortened in the folder name, and a session may start in a subfolder:
    # fall back to the folder whose transcripts ran inside this repo.
    for cand in glob.glob(os.path.join(config_dir, "projects", "*", "*.jsonl")):
        try:
            with open(cand, encoding="utf-8") as fh:
                cwd = next((json.loads(l).get("cwd") for l in fh if '"cwd"' in l), None)
        except (OSError, ValueError):
            continue
        if cwd and (cwd == repo or cwd.startswith(repo + os.sep)):
            folder = os.path.dirname(cand)
            break
if not os.path.isdir(folder):
    print(f"Cost: not measured (no Claude Code transcripts for this repo in {config_dir}/projects)")
    sys.exit(0)

mains = sorted(glob.glob(os.path.join(folder, "*.jsonl")), key=os.path.getmtime)
if opts["branch"]:
    sessions = [os.path.basename(p)[:-6] for p in mains]
elif opts["session"]:
    sessions = [s.strip() for s in opts["session"].split(",") if s.strip()]
else:
    current = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not current and mains:
        current = os.path.basename(mains[-1])[:-6]
    sessions = [current] if current else []

files = []  # (path, role)
missing = []
for sid in sessions:
    main = os.path.join(folder, sid + ".jsonl")
    if os.path.exists(main):
        files.append((main, "Technical Lead"))
    else:
        missing.append(sid)
    for sub in glob.glob(os.path.join(folder, sid, "subagents", "*.jsonl")):
        role = "subagent"
        try:
            meta = json.load(open(sub[:-6] + ".meta.json", encoding="utf-8"))
            role = meta.get("agentType") or role
        except (OSError, ValueError):
            pass
        files.append((sub, role))

since = None
if opts["since"]:
    try:
        since = datetime.fromisoformat(opts["since"].replace("Z", "+00:00"))
        if since.tzinfo is None:
            since = since.replace(tzinfo=datetime.now().astimezone().tzinfo).astimezone()
    except ValueError:
        print(f"Cost: not measured (--since {opts['since']} is not an ISO time)")
        sys.exit(0)

# Each API call is written once per content block: keep the last entry per message id.
calls = {}
first_ts = last_ts = None
for path, role in files:
    try:
        lines = open(path, encoding="utf-8")
    except OSError:
        continue
    for line in lines:
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        msg = entry.get("message")
        if not isinstance(msg, dict) or not isinstance(msg.get("usage"), dict):
            continue
        model = msg.get("model") or ""
        if not model.startswith("claude-"):
            continue
        if opts["branch"] and entry.get("gitBranch") != opts["branch"]:
            continue
        ts = entry.get("timestamp")
        when = None
        if ts:
            try:
                when = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            except ValueError:
                pass
        if since and when and when < since:
            continue
        key = msg.get("id") or entry.get("requestId") or entry.get("uuid")
        calls[(path, key)] = (role, model, msg["usage"], path, when)
        if when:
            first_ts = when if first_ts is None or when < first_ts else first_ts
            last_ts = when if last_ts is None or when > last_ts else last_ts

if not calls:
    note = f" (sessions not found: {', '.join(missing)})" if missing else ""
    print(f"Cost: not measured (no API calls found in scope){note}")
    sys.exit(0)

# One row for the Technical Lead per model, one per subagent run (each run has its own transcript),
# so the rows line up with the retro's Dev round / QA round rows.
rows = {}  # (role, model, run) -> totals
unpriced = set()
for role, model, u, path, when in calls.values():
    inp = u.get("input_tokens") or 0
    out = u.get("output_tokens") or 0
    read = u.get("cache_read_input_tokens") or 0
    cc = u.get("cache_creation") if isinstance(u.get("cache_creation"), dict) else None
    if cc:
        w5 = cc.get("ephemeral_5m_input_tokens") or 0
        w1 = cc.get("ephemeral_1h_input_tokens") or 0
    else:
        w5, w1 = u.get("cache_creation_input_tokens") or 0, 0
    stu = u.get("server_tool_use") if isinstance(u.get("server_tool_use"), dict) else {}
    searches = stu.get("web_search_requests") or 0
    run = "" if role == "Technical Lead" else path
    r = rows.setdefault((role, model, run), {"calls": 0, "in": 0, "w": 0, "read": 0, "out": 0, "usd": 0.0, "start": None})
    if when and (r["start"] is None or when < r["start"]):
        r["start"] = when
    r["calls"] += 1; r["in"] += inp; r["w"] += w5 + w1; r["read"] += read; r["out"] += out
    base = rates_for(model)
    if base is None:
        unpriced.add(model)
        continue
    rates = prices[base]
    if base in long_prices and inp + w5 + w1 + read > long_prices[base][0]:
        rates = long_prices[base][1]
    usd = (inp * rates[0] + out * rates[1] + w5 * rates[2] + w1 * rates[3] + read * rates[4]) / 1e6
    if u.get("speed") == "fast":
        usd *= fast_mult
    r["usd"] += usd + searches * search_price

def tok(n):
    return f"{n / 1e6:.2f}M" if n >= 1e6 else f"{n / 1e3:.0f}k" if n >= 1e3 else str(n)

scope = (f"branch {opts['branch']}" if opts["branch"]
         else "sessions " + ", ".join(s[:8] for s in sessions) if len(sessions) > 1
         else f"session {sessions[0][:8]}")
span = ""
if first_ts and last_ts:
    span = f"; {first_ts.strftime('%Y-%m-%d %H:%M')} to {last_ts.strftime('%Y-%m-%d %H:%M')} UTC"
print(f"Feature cost ({scope}{span})")
header = ("Role", "Started (UTC)", "Model", "Calls", "Input", "Cache write", "Cache read", "Output", "Est. $")
table = [header]
by_role = {}
def order(kv):
    (role, model, run), r = kv
    return (role != "Technical Lead", r["start"].timestamp() if r["start"] else 0)
for (role, model, run), r in sorted(rows.items(), key=order):
    usd = "unpriced" if model in unpriced else f"{r['usd']:.2f}"
    start = r["start"].strftime("%m-%d %H:%M") if r["start"] else "?"
    table.append((role, start, model, str(r["calls"]), tok(r["in"]), tok(r["w"]), tok(r["read"]), tok(r["out"]), usd))
    by_role[role] = by_role.get(role, 0.0) + r["usd"]
widths = [max(len(row[i]) for row in table) for i in range(len(header))]
for row in table:
    print("  ".join(cell.ljust(widths[i]) for i, cell in enumerate(row)).rstrip())

total = sum(by_role.values())
split = ", ".join(f"{role} ${usd:.2f}" for role, usd in sorted(by_role.items(), key=lambda kv: (kv[0] != "Technical Lead", -kv[1])))
extra = f"; unpriced models: {', '.join(sorted(unpriced))}" if unpriced else ""
if missing:
    extra += f"; sessions not found: {', '.join(missing)}"
print(f"Cost ≈ ${total:.2f} ({split}); API list prices as of {as_of}{extra}")
PY
exit 0
