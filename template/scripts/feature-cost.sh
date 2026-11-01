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
#   --since      only API calls at or after this time (UTC unless it names a zone, e.g. 2026-10-15T09:30
#                or 2026-10-15T13:30+04:00); use it when the session did other work before this feature or task
#   --branch     every session in this repo, counting only calls made on that git branch (a feature
#                worked on across several sessions); calls made before the branch existed are missed
#   --session    these sessions instead of the current one
# A transcript line it can't read (a torn write, a bad byte, a field of the wrong type) is skipped and
# counted on the Cost line, never fatal. Exit 0 with a Cost or "not measured" line; 2 on a bad option;
# 1 when the script itself fails, with a "not measured" line saying so.

. "$(cd "$(dirname "$0")" && pwd)/lib/config.sh" || { echo "Cost: not measured (scripts/lib/config.sh is missing or unreadable)"; exit 1; }
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || { echo "Cost: not measured (cannot enter the project folder)"; exit 1; }

# Config: cost.track (default true) and cost.prices (default harness/MODEL_PRICES.md).
if [ "$(config_get cost.track | tr '[:upper:]' '[:lower:]')" = false ]; then
  echo "Cost: not tracked (cost.track is false in harness.config.yml)"
  exit 0
fi
COST_PRICES="$(config_get cost.prices)"
export COST_PRICES="${COST_PRICES:-harness/MODEL_PRICES.md}"
# loop.feature_budget_usd: the owner's soft cap per feature in dollars; 0, empty or missing means no cap.
FEATURE_BUDGET="$(config_get loop.feature_budget_usd)"
export FEATURE_BUDGET="${FEATURE_BUDGET:-0}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Cost: not measured (python3 not found)"
  exit 0
fi

# -I: a json.py or re.py in the project must not run in place of the standard module.
# -X utf8: write UTF-8 even where the console's default encoding can't hold ≈ (Windows cp1252).
python3 -I -X utf8 - "$@" <<'PY'
import glob, json, os, re, sys
from datetime import datetime, timezone

# A model or agent name from a damaged transcript can hold text UTF-8 can't encode (a lone surrogate).
sys.stdout.reconfigure(errors="replace")

args = sys.argv[1:]
opts = {"since": None, "branch": None, "session": None}
while args:
    flag = args.pop(0)
    key = flag.lstrip("-")
    if key not in opts or not args:
        print(f"usage: feature-cost.sh [--since <ISO time>] [--branch <name>] [--session <id>[,<id>]] (bad option: {flag})")
        sys.exit(2)
    opts[key] = args.pop(0)

prices_path = os.environ["COST_PRICES"]

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

def count(v):
    # A token count: an int, or digits in a string; anything else (null, negative, junk) counts 0.
    if isinstance(v, bool):
        return 0
    if isinstance(v, str):
        v = v.strip()
        if not v.isdigit():
            return 0
    try:
        return max(int(v), 0)
    except (TypeError, ValueError, OverflowError):
        return 0

ISO = re.compile(r"(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}:\d{2})(:\d{2})?(?:[.,](\d+))?)?\s*(Z|[+-]\d{2}:?\d{2})?", re.I)

def parse_time(text):
    # ISO 8601 to an aware datetime, UTC when no zone is given; None when unreadable. The common forms
    # are normalised first, because Python before 3.11 accepts neither "Z" nor a fraction of other than
    # 3 or 6 digits; anything else goes to fromisoformat as written (3.11 and later read more forms).
    if not isinstance(text, str):
        return None
    text = text.strip()
    m = ISO.fullmatch(text)
    if m:
        day, hm, sec, frac, zone = m.groups()
        iso = day + "T" + (hm or "00:00") + (sec or ":00")
        if frac:
            iso += "." + (frac + "000000")[:6]
        if zone:
            iso += "+00:00" if zone.upper() == "Z" else zone if ":" in zone else zone[:3] + ":" + zone[3:]
    else:
        iso = text[:-1] + "+00:00" if text[-1:] in ("Z", "z") else text
    try:
        when = datetime.fromisoformat(iso)
    except ValueError:
        return None
    return when if when.tzinfo else when.replace(tzinfo=timezone.utc)

def rates_for(model):
    # Longest table entry that the model id starts with (ids may carry a date or [1m] suffix).
    best = max((k for k in prices if model.startswith(k)), key=len, default=None)
    return best

def folder_name(path):
    # Claude Code's own rule: every character that isn't an ASCII letter or digit becomes "-". It runs in
    # JavaScript, which counts a character outside the BMP (an emoji) as two, so that becomes "--".
    return "".join(c if c.isascii() and c.isalnum() else "--" if ord(c) > 0xFFFF else "-" for c in path)

def first_cwd(path):
    try:
        with open(path, encoding="utf-8-sig", errors="replace") as fh:
            for line in fh:
                if '"cwd"' in line:
                    try:
                        cwd = json.loads(line).get("cwd")
                    except (ValueError, AttributeError, RecursionError):
                        continue
                    if isinstance(cwd, str):
                        return cwd
    except OSError:
        pass
    return None

# Transcripts: <config dir>/projects/<repo path with every non-alphanumeric as ->/
config_dir = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
repo = os.getcwd()
real = os.path.realpath(repo)
folder = os.path.join(config_dir, "projects", folder_name(repo))
if not os.path.isdir(folder):
    folder = ""
    # Long paths are shortened in the folder name, a session may start in a subfolder, and a recorded
    # cwd may go through a symlink (/tmp is /private/tmp on macOS): fall back to the folder of the
    # newest transcript that ran inside this repo.
    def inside(cwd):
        try:
            cwd = os.path.realpath(cwd)
        except (ValueError, OSError):   # a NUL in a damaged transcript's cwd
            return False
        return cwd == real or cwd.startswith(real.rstrip(os.sep) + os.sep)
    cands = glob.glob(os.path.join(config_dir, "projects", "*", "*.jsonl"))
    for cand in sorted(cands, key=lambda p: os.path.getmtime(p) if os.path.exists(p) else 0, reverse=True):
        cwd = first_cwd(cand)
        if cwd and inside(cwd):
            folder = os.path.dirname(cand)
            break
if not folder or not os.path.isdir(folder):
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
            meta = json.load(open(sub[:-6] + ".meta.json", encoding="utf-8-sig", errors="replace"))
            if isinstance(meta.get("agentType"), str) and meta["agentType"]:
                role = meta["agentType"]
        except (OSError, ValueError, AttributeError):
            pass
        files.append((sub, role))

since = None
if opts["since"]:
    since = parse_time(opts["since"])
    if since is None:
        print(f"Cost: not measured (--since {opts['since']} is not an ISO time)")
        sys.exit(0)

# Each API call is written once per content block: keep the last entry per message id. The id is
# unique per call, so a call copied into a second session file (a resumed or forked session) counts once.
calls, undated = {}, set()
skipped = 0
first_ts = last_ts = None
for path, role in files:
    try:
        # A bad byte (a torn write, a file saved in another encoding) becomes U+FFFD, never a crash.
        lines = open(path, encoding="utf-8-sig", errors="replace")
    except OSError:
        continue
    with lines:
        for line in lines:
            if not line.strip():
                continue
            try:
                entry = json.loads(line)
                if not isinstance(entry, dict):
                    raise ValueError("not an object")
                msg = entry.get("message")
                if not isinstance(msg, dict) or not isinstance(msg.get("usage"), dict):
                    continue
                model = msg.get("model")
                if not isinstance(model, str) or not model.startswith("claude-"):
                    continue
                if opts["branch"] and entry.get("gitBranch") != opts["branch"]:
                    continue
                # A call that is in two files (a resumed session, or a main and a subagent transcript)
                # counts once, on the row of the file read last (subagent files come after their session's).
                mid = msg.get("id")
                key = ("id", mid) if isinstance(mid, str) and mid else (path, str(entry.get("requestId") or entry.get("uuid")))
                when = parse_time(entry.get("timestamp"))
                if since and when is None:
                    undated.add(key)
                    continue
                if since and when < since:
                    continue
            except (ValueError, TypeError, AttributeError, RecursionError):
                skipped += 1
                continue
            calls[key] = (role, model, msg["usage"], path, when)
            if when:
                first_ts = when if first_ts is None or when < first_ts else first_ts
                last_ts = when if last_ts is None or when > last_ts else last_ts

notes = []
if missing:
    notes.append(f"sessions not found: {', '.join(missing)}")
if skipped:
    notes.append(f"{skipped} unreadable transcript line{'s' if skipped != 1 else ''} skipped")
undated -= calls.keys()
if undated:
    notes.append(f"{len(undated)} call{'s' if len(undated) != 1 else ''} with no readable time left out by --since")
if not calls:
    note = f" ({'; '.join(notes)})" if notes else ""
    print(f"Cost: not measured (no API calls found in scope){note}")
    sys.exit(0)

# One row for the Technical Lead per model, one per subagent run (each run has its own transcript),
# so the rows line up with the retro's Dev round / QA round rows.
rows = {}  # (role, model, run) -> totals
unpriced = set()
for role, model, u, path, when in calls.values():
    inp = count(u.get("input_tokens"))
    out = count(u.get("output_tokens"))
    read = count(u.get("cache_read_input_tokens"))
    cc = u.get("cache_creation") if isinstance(u.get("cache_creation"), dict) else None
    if cc:
        w5 = count(cc.get("ephemeral_5m_input_tokens"))
        w1 = count(cc.get("ephemeral_1h_input_tokens"))
    else:
        w5, w1 = count(u.get("cache_creation_input_tokens")), 0
    stu = u.get("server_tool_use") if isinstance(u.get("server_tool_use"), dict) else {}
    searches = count(stu.get("web_search_requests"))
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
extra += "".join(f"; {n}" for n in notes)
try:
    budget = float(os.environ.get("FEATURE_BUDGET") or 0)
except ValueError:
    budget = 0.0
    print(f"Budget: loop.feature_budget_usd is not a number ({os.environ['FEATURE_BUDGET']}); no cap applied")
if budget > 0:
    # Printed before the Cost line, which stays last for the retro and hand-off to paste.
    over = "OVER, stop and ask the owner" if total > budget else "within"
    print(f"Budget: ${total:.2f} of ${budget:.2f} ({total / budget * 100:.0f}%), {over}")
print(f"Cost ≈ ${total:.2f} ({split}); API list prices as of {as_of}{extra}")
PY
rc=$?
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "Cost: not measured (feature-cost.sh failed with exit $rc; the error is above)"
  exit 1
fi
exit "$rc"
