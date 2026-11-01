#!/usr/bin/env bash
# PreToolUse hook (.claude/settings.json → hooks): checks each tool call before it runs. The deny
# and ask rules in .claude/settings.json stay as a second layer; this script catches what text
# patterns miss, because it reads a Bash command the way the shell does (every command in a chain,
# inside `$(…)`, `bash -c '…'`, `eval`, after `env`, `sudo` or `git -C <dir>`).
#
# What it denies (exit 2, the reason goes back to the agent), what it asks (the owner answers a
# permission prompt), which `guard:` switches in harness.config.yml turn an ask off, and what it does not
# see are described once, in harness/GUARD.md. This file is the implementation of
# that list: change the two together, and add a case to tests/guard-cases.jsonl for each rule.
# The hook fails closed: without python3, without the config reader (scripts/lib/config.sh), when the
# project folder can't be entered, on input it can't parse, on an internal error and when a check runs
# past 15 s, it exits 2 with the reason, so a broken guard blocks the call instead of passing it. The hook
# command in .claude/settings.json turns any other exit (this file missing, bash missing) into 2 too, and
# its 60 s timeout sits well above the 15 s limit, because Claude Code runs the call when a hook times out.
# A hang the 15 s timer can't end (before the check starts, or inside one long regex call) still reaches that timeout. `guard: { fail_open: true }`
# in harness.config.yml lets calls through when python3 is missing (the owner's choice for a machine
# that can't have it); /morph-doctor reports the gap either way.
#
# Input: the hook's JSON on stdin. Test by hand:
#   echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | bash scripts/guard.sh

guard_closed() {
  echo "Blocked by scripts/guard.sh: $1 The guard fails closed. Fix that, then retry (/morph-doctor lists what is missing)." >&2
  exit 2
}

GUARD_LIB_DIR="$(cd "$(dirname "$0")" && pwd)/lib"
GUARD_SELF="${GUARD_LIB_DIR%/lib}/${0##*/}"
. "$GUARD_LIB_DIR/config.sh" 2>/dev/null || guard_closed "scripts/lib/config.sh is missing or unreadable, so harness.config.yml can't be read."
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" 2>/dev/null || guard_closed "the project folder can't be entered."
command -v awk >/dev/null 2>&1 || guard_closed "awk is not installed, so harness.config.yml can't be read."
if ! command -v python3 >/dev/null 2>&1; then
  case "$(config_get guard.fail_open)" in
    [Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|[Oo][Nn]) echo "scripts/guard.sh: python3 is missing and guard.fail_open is set, so this call is not checked." >&2; exit 0 ;;
  esac
  guard_closed "python3 is not installed, so the call can't be checked. Install python3, or set guard.fail_open: true in harness.config.yml to accept unchecked calls."
fi

# The environment branches, one per line. The Python part checks them and blocks every push when they
# can't be read (file missing, key missing, a value that isn't a branch name), so a broken config never
# leaves the branches unprotected.
GUARD_CONFIG_READABLE=0
[ -f harness.config.yml ] && [ -r harness.config.yml ] && GUARD_CONFIG_READABLE=1
GUARD_INTEGRATION="$(config_get_all branches.integration)"
GUARD_PRODUCTION="$(config_get_all branches.production)"
GUARD_ENV_BRANCHES="$(config_env_branches)"
GUARD_MCP_WRITES="$(config_get guard.mcp_writes)"
GUARD_DEPLOYS="$(config_get guard.deploys)"
GUARD_PUBLISHES="$(config_get guard.publishes)"
GUARD_SCHEMA_PUSHES="$(config_get guard.schema_pushes)"
GUARD_NETWORK="$(config_get guard.network)"
GUARD_INSTALLS="$(config_get guard.installs)"
GUARD_PR_WRITES="$(config_get guard.pr_writes)"
GUARD_ALLOW_HOSTS="$(config_get guard.allow_hosts)"
GUARD_FAIL_OPEN="$(config_get guard.fail_open)"
export GUARD_LIB_DIR GUARD_FAIL_OPEN GUARD_CONFIG_READABLE GUARD_INTEGRATION GUARD_PRODUCTION GUARD_ENV_BRANCHES GUARD_MCP_WRITES GUARD_DEPLOYS GUARD_PUBLISHES GUARD_SCHEMA_PUSHES GUARD_NETWORK GUARD_INSTALLS GUARD_PR_WRITES GUARD_ALLOW_HOSTS

# The checks below run in python3. It reads them from this file (the GUARD_PY block at the end) rather than from a
# `-c` argument, because Linux caps a single argument at 128 KB. Line numbers in a traceback match this file.
python3 -I -c 'import sys; f = sys.argv[1]; t = open(f, encoding="utf-8").read(); s = t.index("\nimport fnmatch") + 1; e = t.rindex("\nGUARD_PY\n"); exec(compile("\n" * t.count("\n", 0, s) + t[s:e], f, "exec"))' "$GUARD_SELF"
rc=$?
# 0 = pass or ask (JSON on stdout), 2 = deny. Anything else is a crash inside the hook: block, don't pass.
[ "$rc" -eq 0 ] || [ "$rc" -eq 2 ] || guard_closed "the guard script crashed (exit $rc), so the call can't be checked."
exit "$rc"

: <<'GUARD_PY'
import fnmatch, glob as globmod, json, os, re, shlex, subprocess, sys, tempfile, threading

# Claude Code lets a call through when a hook runs past its timeout (60 s in .claude/settings.json), so the guard
# stops its own check after 15 s and blocks the call. GUARD_TIME_LIMIT can only lower the limit (the self-test uses it).
def too_slow():
    sys.stderr.write(f"Blocked by scripts/guard.sh: checking this call took longer than {TIME_LIMIT:g} s, so it can\u2019t be "
                     "checked. Split a long command into smaller ones, then retry.\n")
    sys.stderr.flush()
    os._exit(2)
try:
    TIME_LIMIT = min(15.0, float(os.environ.get("GUARD_TIME_LIMIT") or 15))
except ValueError:
    TIME_LIMIT = 15.0
if not TIME_LIMIT > 0:
    TIME_LIMIT = 15.0
_watchdog = threading.Timer(TIME_LIMIT, too_slow)
_watchdog.daemon = True
_watchdog.start()

# What a branch name read from the config may hold: git rules (no `..`, `@{`, spaces, ~^:?*[\\ or control characters, no
# leading `-`) plus the characters the config reader would have kept from YAML syntax (&{}"#,). A YAML null or boolean is no name.
BRANCH_WORD = re.compile(r"^(?!-)(?!.*\.\.)(?!.*@\{)[^\s~^:?*\[\\\x00-\x1f\x7f&{}\x27\",#]+$")
NOT_A_BRANCH = {"null", "~", "true", "false", "yes", "no", "on", "off", "none"}

def config_branches(env=os.environ):
    """The environment branches from harness.config.yml, and what made them unreadable (then every push is blocked)."""
    found, problems = set(), []
    if env.get("GUARD_CONFIG_READABLE") != "1":
        return found, ["harness.config.yml is missing or can\u2019t be read"]
    for key, var in (("branches.integration", "GUARD_INTEGRATION"), ("branches.production", "GUARD_PRODUCTION"),
                     ("environments", "GUARD_ENV_BRANCHES")):
        values = [v.strip().strip("\"\x27") for v in env.get(var, "").splitlines() if v.strip()]
        if not values and key != "environments":
            problems.append(f"`{key}` was not found in harness.config.yml")
        for v in values:
            b = v[len("refs/heads/"):] if v.startswith("refs/heads/") else v
            if BRANCH_WORD.match(b) and b.lower() not in NOT_A_BRANCH:
                found.add(b)
            else:
                problems.append(f"`{key}: {v}` is not a branch name the guard can read")
    return found, problems

PROTECTED, CONFIG_PROBLEMS = config_branches()
PROTECTED_LOW = {b.lower() for b in PROTECTED}
def protected_branch(name):
    # Branch names are case sensitive on the code host but not on every remote or file system, so `Main` counts as `main`.
    return str(name).lower() in PROTECTED_LOW
def switch(name, env=os.environ):
    return env.get(name, "ask").strip().lower() not in ("off", "false", "no")
def pr_allow(env=os.environ):
    return env.get("GUARD_PR_WRITES", "allow").strip().lower() not in ("ask", "no", "false")
def allow_hosts(env=os.environ):
    return {"localhost", "127.0.0.1", "::1"} | set(re.split(r"[\s,]+", env.get("GUARD_ALLOW_HOSTS", "").lower()))
def fail_open(env=os.environ):
    return env.get("GUARD_FAIL_OPEN", "").strip().lower() in ("true", "yes", "on")

MCP_ASK = switch("GUARD_MCP_WRITES")
# `pr_writes: allow` (the default, also when the key is missing) lets a pull request be opened, updated and commented on
# in this project own repo without a prompt; `ask` brings the prompt back for those tools.
PR_ALLOW = pr_allow()
GROUP_ASK = {"deploys": switch("GUARD_DEPLOYS"), "publishes": switch("GUARD_PUBLISHES"),
             "schema_pushes": switch("GUARD_SCHEMA_PUSHES"), "network": switch("GUARD_NETWORK"),
             "installs": switch("GUARD_INSTALLS")}
ALLOW_HOSTS = allow_hosts()

def deny(reason):
    sys.stderr.write("Blocked by scripts/guard.sh: " + reason + " What the guard checks: harness/GUARD.md.\n")
    sys.exit(2)

# While a Bash command is checked, an ask is held until the whole command has been read, so a deny anywhere in it wins:
# `curl -d x https://h; git push --force` must not turn into one prompt whose yes also runs the force-push.
HELD_ASK = []

def ask(reason):
    if HELD_ASK and HELD_ASK[0] is None:
        HELD_ASK[0] = reason
        return
    if HELD_ASK:
        return
    print(json.dumps(ensure_ascii=False, obj={"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": "scripts/guard.sh: " + reason}}))
    sys.exit(0)

try:
    event = json.load(sys.stdin)
except Exception:
    deny("the hook input is not valid JSON, so the call can\u2019t be checked.")
if not isinstance(event, dict):
    deny("the hook input is not a JSON object, so the call can\u2019t be checked.")
if event.get("hook_event_name") == "ConfigChange":
    # The settings files changed while the session runs. A change to settings.local.json (the file an
    # agent could use to grant itself permissions) is blocked; one to settings.json is allowed, and the
    # owner sees the notice because the Edit/Write that made it already asked.
    if event.get("source") == "local_settings":
        deny("settings.local.json changed during the session; it is the owner\u2019s file. Restore it, or the owner confirms the change.")
    sys.exit(0)
tool = event.get("tool_name") or ""
args = event.get("tool_input") or {}
if not isinstance(args, dict):
    deny("the tool input is not a JSON object, so the call can\u2019t be checked.")

# ---- the guard own files -------------------------------------------------------------------------
# One approved write here could switch the guard off for every later call. scripts/guard.sh and scripts/lib/ (the guard
# itself) are never written by a tool call: the owner changes them by hand. .claude/settings.json and harness.config.yml
# change through Edit or Write only, so the guard can work out the result: a change that removes a protection is denied,
# any other change asks. The other files the guard rests on ask; settings.local.json is the owner alone and is denied.
CORE_FILES = ["scripts/guard.sh", "scripts/lib/*"]
HOLDER_DIRS = ["scripts", "scripts/lib", ".claude"]   # the folders that hold the guard and its wiring
SETTINGS_FILES = [".claude/settings.json"]
CONFIG_FILES = ["harness.config.yml"]
GUARD_FILES = ["scripts/session-start.sh", ".git/hooks/*", ".git/config"]
OWNER_FILES = [".claude/settings.local.json"]
# CI definitions run with the repository\u2019s secrets, so a change to one asks (the `deploys` switch turns it off).
CI_FILES = [".github/workflows/*", ".github/actions/*", ".gitlab-ci.yml"]
ROOT = os.getcwd()
CD_DIRS = []   # directories a `cd` in the same command moves to; a relative path is also tried under each

def rels_to_root(word):
    """Where a path word points, relative to the project root, once per directory a `cd` could set."""
    w = expand_home(str(word).strip())
    for var in ("${CLAUDE_PROJECT_DIR}", "$CLAUDE_PROJECT_DIR", "${PWD}", "$PWD"):
        w = w.replace(var, ROOT)
    if not w or any(c in w for c in "$`"):
        return
    root = os.path.realpath(ROOT)
    for full in [w] if os.path.isabs(w) else [os.path.join(ROOT, d, w) for d in [""] + CD_DIRS]:
        full = os.path.normpath(full)
        for cand in (full, os.path.realpath(full)):
            for base in (ROOT, root):
                if cand == base or cand.startswith(base + os.sep):
                    yield os.path.relpath(cand, base)

# ---- files outside the repo: ~/.claude, shell startup files, schedules ----------------------------
HOME = os.path.expanduser("~")
CLAUDE_HOME = os.path.normpath(os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(HOME, ".claude"))
PERSIST_FILES = [os.path.join(HOME, n) for n in (".bashrc", ".bash_profile", ".bash_login", ".bash_logout", ".profile",
                 ".zshrc", ".zprofile", ".zshenv", ".zlogin", ".zlogout", ".config/fish/config.fish")] + [
                 "/etc/profile", "/etc/bash.bashrc", "/etc/environment", "/etc/crontab", "/etc/zshrc", "/etc/zshenv"]
PERSIST_DIRS = [os.path.join(HOME, n) for n in (".config/systemd/user", ".config/autostart", ".config/fish/conf.d",
                "Library/LaunchAgents")] + ["/etc/profile.d", "/etc/cron.d", "/etc/cron.daily", "/etc/cron.hourly",
                "/etc/cron.weekly", "/etc/cron.monthly", "/etc/sudoers.d", "/etc/systemd", "/var/spool/cron"]

def under(path, base):
    return path == base or path.startswith(base + os.sep)

def expand_home(word):
    w = str(word).strip("\"\x27")
    for var in ("${HOME}", "$HOME"):
        if w == var or w.startswith(var + "/"):
            w = HOME + w[len(var):]
    if w == "~" or w.startswith("~/"):
        w = HOME + w[1:]
    return w

def home_kind(word):
    """"home" for a path under ~/.claude, "persist" for a shell startup file or a schedule, "" otherwise."""
    w = expand_home(word)
    if not os.path.isabs(w) or "$" in w or "`" in w:
        return ""
    p = os.path.normpath(w)
    for cand in {p, os.path.realpath(p)}:
        if under(cand, CLAUDE_HOME):
            return "home"
        if cand in PERSIST_FILES or any(under(cand, d) for d in PERSIST_DIRS):
            return "persist"
    return ""

def protected_kind(word):
    """"owner" for settings.local.json, "core" for the guard itself, "settings" and "config" for .claude/settings.json and
    harness.config.yml, "guard" for the other files it rests on, "persist" for shell startup files and schedules, "ci" for
    CI definitions, "" for anything else."""
    # also split on spaces and braces: a one-liner names a path as `copy( \x27/tmp/x\x27, \x27scripts/guard.sh\x27 )` or `q{scripts/guard.sh}`
    for part in re.split(r"[=:<>|,;(){}\s]", str(word)):
        part = part.strip("\"\x27")
        if part and home_kind(part) == "persist":
            return "persist"
        globbed = any(c in part for c in "*?[")
        for rel in rels_to_root(part) if part else ():
            for kind, names in (("owner", OWNER_FILES), ("holder", HOLDER_DIRS), ("core", CORE_FILES), ("settings", SETTINGS_FILES),
                                ("config", CONFIG_FILES), ("guard", GUARD_FILES), ("ci", CI_FILES if GROUP_ASK["deploys"] else [])):
                for name in names:
                    # Without letter case: on macOS and Windows `Scripts/Guard.sh` is the guard itself.
                    low, pat = rel.lower(), name.lower()
                    if fnmatch.fnmatchcase(low, pat) or (globbed and fnmatch.fnmatchcase(pat.replace("/*", "/x"), low)):
                        # a new file in scripts/lib/ changes nothing the guard runs (a `cd` into a monorepo app makes many such paths)
                        if kind == "core" and name.endswith("/*") and not globbed and not os.path.lexists(os.path.join(ROOT, rel)):
                            continue
                        return kind
    return ""

CONFIG_VARS = [("GUARD_INTEGRATION", "config_get_all branches.integration"), ("GUARD_PRODUCTION", "config_get_all branches.production"),
               ("GUARD_ENV_BRANCHES", "config_env_branches")] + [
               (f"GUARD_{k.upper()}", f"config_get guard.{k}") for k in ("mcp_writes", "deploys", "publishes", "schema_pushes",
                                                                        "network", "installs", "pr_writes", "allow_hosts", "fail_open")]

def read_config(text):
    """The values the guard would read from a harness.config.yml holding `text`, through the same reader (scripts/lib/config.sh)."""
    try:
        fd, tmp = tempfile.mkstemp(suffix=".yml")
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
            f.write(text)
        body = "; ".join(f"printf \"%s=%s\\0\" {var} \"$({call} \"$2\")\"" for var, call in CONFIG_VARS)
        r = subprocess.run(["bash", "-c", ". \"$1/config.sh\" || exit 3; " + body, "guard", os.environ.get("GUARD_LIB_DIR", ""), tmp],
                           capture_output=True, text=True, timeout=5)
    except (OSError, UnicodeError, subprocess.SubprocessError):
        r = None
    finally:
        try:
            os.unlink(tmp)
        except (OSError, NameError):
            pass
    if r is None or r.returncode != 0:
        deny("the new harness.config.yml can\u2019t be checked (its reader did not run), so the change is blocked. Retry.")
    env = {"GUARD_CONFIG_READABLE": "1"}
    for record in r.stdout.split("\0"):
        if "=" in record:
            key, value = record.split("=", 1)
            env[key] = value
    return env

SWITCH_WHAT = {"mcp_writes": "a connector write", "deploys": "a deploy or cloud CLI call", "publishes": "a publish or tag push",
               "schema_pushes": "a database client or schema push", "network": "a request that sends data out",
               "installs": "a downloaded package runs"}

def config_lost(after):
    """The protections a harness.config.yml holding `after` would drop, compared with the one the guard reads now."""
    new, lost = read_config(after), []
    for key, what in SWITCH_WHAT.items():
        if switch(f"GUARD_{key.upper()}") and not switch(f"GUARD_{key.upper()}", new):
            lost.append(f"`guard.{key}` goes to off (nothing asks before {what})")
    if not pr_allow() and pr_allow(new):
        lost.append("`guard.pr_writes` goes from ask to allow")
    hosts = ", ".join(sorted(allow_hosts(new) - ALLOW_HOSTS - {""}))
    if hosts:
        lost.append(f"`guard.allow_hosts` adds {hosts} (data can be sent there without a prompt)")
    if fail_open(new) and not fail_open():
        lost.append("`guard.fail_open` turns on (calls run unchecked when python3 is missing)")
    branches, problems = config_branches(new)
    if not problems:
        kept = {b.lower() for b in branches}
        gone = ", ".join(sorted(b for b in PROTECTED if b.lower() not in kept))
        if gone:
            lost.append(f"{gone} would no longer be an environment branch (a push to it would pass)")
    return lost

# Settings that run a command outside the guard: a new or changed one runs code that no check sees.
COMMAND_SETTINGS = ("apiKeyHelper", "awsAuthRefresh", "awsCredentialExport", "otelHeadersHelper", "statusLine")

def guard_hooks(settings):
    """{event: [(matcher, command, timeout)]} for each hook in a settings object that runs scripts/guard.sh."""
    out = {}
    hooks = settings.get("hooks")
    for event, groups in (hooks.items() if isinstance(hooks, dict) else ()):
        for group in (groups if isinstance(groups, list) else ()):
            entries = group.get("hooks") if isinstance(group, dict) else None
            for h in (entries if isinstance(entries, list) else ()):
                if isinstance(h, dict) and "scripts/guard.sh" in str(h.get("command", "")):
                    t = h.get("timeout")
                    out.setdefault(event, []).append((str(group.get("matcher", "")), str(h.get("command")),
                                                      t if isinstance(t, (int, float)) and not isinstance(t, bool) else 60,
                                                      str(h.get("type"))))
    return out

def hook_commands(settings):
    """Every command a settings object runs: hook commands and the helper settings (apiKeyHelper, statusLine ...)."""
    out = set()
    hooks = settings.get("hooks")
    for groups in (hooks.values() if isinstance(hooks, dict) else ()):
        for group in (groups if isinstance(groups, list) else ()):
            entries = group.get("hooks") if isinstance(group, dict) else None
            for h in (entries if isinstance(entries, list) else ()):
                if not (isinstance(h, dict) and "scripts/guard.sh" in str(h.get("command", ""))):   # checked on its own
                    out.add(json.dumps(h, sort_keys=True))
    for key in COMMAND_SETTINGS:
        if key in settings:
            out.add(key + "=" + json.dumps(settings[key], sort_keys=True))
    return out

def matcher_covers(new, old):
    try:
        re.compile(new)
    except re.error:
        return False   # Claude Code drops a hook whose matcher is not a valid pattern
    if new in ("", "*") or new == old:
        return True
    return old not in ("", "*") and set(old.split("|")) <= set(new.split("|"))

def settings_lost(path, after):
    """The protections a .claude/settings.json holding `after` would drop, compared with the file as it is now."""
    def strict(value):
        raise ValueError(value)   # NaN and Infinity: Python reads them, Claude Code does not
    try:
        with open(os.path.join(ROOT, path), encoding="utf-8") as f:
            before = json.loads(f.read(), parse_constant=strict)
    except Exception:
        before = None
    if not isinstance(before, dict):
        # the file as it is can\u2019t be read: the new one must at least wire the guard as the template does
        before = {"hooks": {"PreToolUse": [{"matcher": "Bash|Read|Edit|MultiEdit|Write|NotebookEdit|Grep|WebFetch|mcp__.*",
                                            "hooks": [{"type": "command", "command": "scripts/guard.sh", "timeout": 30}]}],
                            "ConfigChange": [{"hooks": [{"type": "command", "command": "scripts/guard.sh", "timeout": 30}]}]}}
        loose = True
    else:
        loose = False
    try:
        new = json.loads(after, parse_constant=strict)
    except Exception:
        new = None
    if not isinstance(new, dict):
        return ["the file would no longer be a valid settings object, so Claude Code would drop its hooks and rules"]
    lost = []
    if new.get("disableAllHooks") not in (None, False) and before.get("disableAllHooks") in (None, False):
        lost.append("`disableAllHooks` turns every hook off, the guard with it")
    hooks = guard_hooks(new)
    for event, entries in guard_hooks(before).items():
        for matcher, command, timeout, kind in entries:
            # a timeout of 30 s or more is enough: the guard stops itself at 15 s
            if not any((c == command or (loose and "scripts/guard.sh" in c)) and matcher_covers(m, matcher) and t >= min(timeout, 30)
                       and k == kind for m, c, t, k in hooks.get(event, [])):
                lost.append(f"the {event} hook that runs scripts/guard.sh is removed, narrowed or changed")
                break
    added = sorted(hook_commands(new) - hook_commands(before))
    if added and not loose:
        lost.append(f"a hook or helper command is added or changed ({added[0][:80]}), and it would run with no check")
    def rules(settings, key):
        perms = settings.get("permissions")
        values = perms.get(key) if isinstance(perms, dict) else None
        return {str(r) for r in values} if isinstance(values, list) else set()
    # a rule with an unfilled render placeholder is filled or dropped by the render, so it is not a protection yet
    for key in ("deny", "ask"):
        gone = sorted(r for r in rules(before, key) - rules(new, key) if "{{" not in r)
        if gone:
            lost.append(f"{key} rule " + ", ".join(f"`{r}`" for r in gone[:5]) + (f" and {len(gone) - 5} more" if len(gone) > 5 else "") + " removed")
    def mode(settings):
        perms = settings.get("permissions")
        return perms.get("defaultMode") if isinstance(perms, dict) else None
    if mode(new) == "bypassPermissions" and mode(before) != "bypassPermissions":
        lost.append("`defaultMode: bypassPermissions` skips every permission prompt")
    # every `env` variable reaches the hook too (PATH, BASH_ENV, an exported bash function named like python3 ...)
    env_before = before.get("env") if isinstance(before.get("env"), dict) else {}
    env_new = new.get("env") if isinstance(new.get("env"), dict) else {}
    changed = ", ".join(sorted(str(k) for k in env_new if env_new.get(k) != env_before.get(k)))
    if changed:
        lost.append(f"`env` sets {changed}, which reaches the guard hook too")
    return lost

def planned_text(tool, args, path):
    """The text the file would hold after this Edit, MultiEdit or Write; None when it can\u2019t be worked out."""
    if tool == "Write":
        return str(args.get("content") or "")
    try:
        with open(os.path.join(ROOT, path), encoding="utf-8", newline="") as f:
            text = f.read()
    except FileNotFoundError:
        text = ""
    except (OSError, UnicodeError):
        return None
    edits = args.get("edits") if tool == "MultiEdit" else [args] if tool == "Edit" else None
    if not isinstance(edits, list):
        return None
    for e in edits:
        if not isinstance(e, dict):
            return None
        old, new = str(e.get("old_string") or ""), str(e.get("new_string") or "")
        if not old:
            if text:
                return None
            text = new
        elif old in text:
            text = text.replace(old, new) if e.get("replace_all") else text.replace(old, new, 1)
        else:
            # Edit also matches straight quotes in old_string to curly ones in the file: do the same (same length, so
            # positions agree)
            flat = lambda t: t.translate({0x201c: 34, 0x201d: 34, 0x2018: 39, 0x2019: 39})
            at = flat(text).find(flat(old))
            if at >= 0:
                text = text[:at] + new + text[at + len(old):]
    return text

def protect(path, how, after=None):
    """Deny or ask for a write to a protected file. `after` is the text the file would hold (Edit and Write), when known."""
    kind = protected_kind(path)
    if kind == "owner":
        deny(f"`{path}` is the owner\u2019s file ({how}); an agent never writes settings.local.json.")
    if kind == "holder":
        deny(f"`{path}` holds the guard or its wiring ({how}); removing, moving or replacing it would switch the guard off, "
             "so the owner does it by hand.")
    if kind == "core":
        deny(f"`{path}` is the guard itself ({how}). No tool call changes it, because one approved change could switch every "
             "check off: the owner edits it by hand. For a kit update, write the new copy under /tmp and give the owner the "
             f"command to run in a terminal (`cp /tmp/<file> {path}`).")
    if kind in ("settings", "config"):
        if after is None:
            deny(f"`{path}` holds the guard\u2019s own settings, and the guard can\u2019t work out what this change does to it "
                 f"({how}). Make the change with the Edit or Write tool: the guard checks that it removes no protection, "
                 "and the owner approves it.")
        lost = settings_lost(path, after) if kind == "settings" else config_lost(after)
        if lost:
            what = "; ".join(lost)
            deny(f"this change to `{path}` removes a protection: {what}. One approval must not switch a protection off, so "
                 "an agent never makes this change. If the owner wants it, they edit the file by hand.")
        kind = "guard"
    if kind == "guard":
        ask(f"`{path}` is one of the files the guard rests on ({how}); the owner approves each change to it.")
    if kind == "persist":
        ask(f"`{path}` runs in every later shell or on a schedule ({how}); the owner approves a change to it.")
    if kind == "ci":
        ask(f"`{path}` is a CI definition that runs with the repository\u2019s secrets ({how}); the owner reads each change to it. "
            "`guard.deploys: off` in harness.config.yml turns this prompt off.")

# ---- secret and credential files ---------------------------------------------------------------
SAFE_SUFFIX = (".example", ".sample", ".template")
SECRET_DIRS = {".aws", ".ssh", ".gnupg", ".azure", ".kube"}
SECRET_NAMES = {".envrc", ".netrc", "_netrc", ".pgpass", ".git-credentials", ".my.cnf", ".htpasswd", ".dockercfg", ".dev.vars", ".secrets"}
ASK_NAMES = {".npmrc", ".pypirc"}
SECRET_SUFFIX = (".pem", ".key", ".p12", ".pfx", ".jks", ".keystore", ".ppk", ".tfstate", ".tfvars", ".tfvars.json")
SECRET_RE = re.compile(r"^(id_(rsa|dsa|ecdsa|ed25519)(_[a-z0-9_]+)?"
                       r"|(credentials?|client_secrets?|service[-_]account[-_a-z0-9]*|[a-z0-9_-]+[-_]credentials?)\.(json|ya?ml|toml|ini|xml|csv|txt)"
                       r"|([a-z0-9_.-]+[-_])?service[-_]?account[-_a-z0-9]*\.json"
                       r"|[a-z0-9_.-]*firebase-adminsdk[-_a-z0-9]*\.json"
                       r"|(secrets?|[a-z0-9_-]+[-_.]secrets?)(\.sops)?\.(json|ya?ml|toml|env|ini|txt|properties|cfg|conf)"
                       r"|\.dev\.vars\.[a-z0-9_-]+"
                       r"|kubeconfig([-_][a-z0-9_-]+)?(\.(ya?ml|json))?|[a-z0-9_.-]+[-_.]kubeconfig(\.ya?ml)?"
                       r"|[a-z0-9_.-]+\.(secrets?|credentials?))$")
GLOB_PROBES = (".env", ".envrc", ".netrc", ".npmrc", ".pypirc", ".pgpass", ".git-credentials")

def own_tool_results(path):
    """True for a file in the tool-results folder of this project (~/.claude/projects/<this project>/<session>/tool-results/),
    where Claude Code saves the output of a call that was too long to show."""
    w = expand_home(path)
    if not os.path.isabs(w) or "$" in w or "`" in w:
        return False
    base = os.path.join(CLAUDE_HOME, "projects", re.sub(r"[^A-Za-z0-9]", "-", ROOT))
    p = os.path.normpath(w)
    for cand in {p, os.path.realpath(p)}:
        rel = os.path.relpath(cand, base).split(os.sep) if under(cand, base) else []
        if len(rel) < 2 or rel[1] != "tool-results" or rel[0] in ("", ".", ".."):
            return False
    return True

def secret_kind(path, read=False):
    """"deny" for a secret or credential file, "ask" for one that is often plain config, "home" for a path
    under ~/.claude, "" otherwise. `read`: the caller only reads the path, so the tool-results folder of this project is fine."""
    if read and own_tool_results(path):
        return ""
    w = expand_home(str(path).strip("\"\x27"))
    try:
        folder = bool(w) and "$" not in w and os.path.isdir(os.path.join(ROOT, w))
    except (ValueError, OSError):
        folder = False
    # a folder is read only through the files in it: `pkg/kubeconfig/` is code, `.ssh/` is not
    named = file_secret_kind(os.path.join(w, "x") if folder else path)
    return named or link_kind(path) or ("home" if home_kind(path) == "home" else "")

def link_kind(path):
    """file_secret_kind of what a path resolves to, when a symlink (the file or a folder above it) makes that a
    different path: `notes.txt -> .env` reads the secret under another name."""
    w = expand_home(str(path).strip("\"\x27"))
    if not w or any(c in w for c in "$`"):
        return ""
    bases = [""] if os.path.isabs(w) else [ROOT] + [os.path.join(ROOT, d) for d in CD_DIRS]
    try:
        for base in bases:
            full = os.path.normpath(os.path.join(base, w))
            # a glob (`note?.txt`) is checked on each file it matches
            for cand in sorted(globmod.glob(full))[:200] if any(c in w for c in "*?[") else [full]:
                real = os.path.realpath(cand)
                kind = file_secret_kind(os.path.join(real, "x") if os.path.isdir(real) else real) if real != cand else ""
                # after a `cd`, a relative path is read where the cd leads (`cd supabase && cat .temp/pooler-url`)
                if not kind and base not in ("", ROOT):
                    kind = file_secret_kind(os.path.relpath(cand, ROOT))
                if kind:
                    return kind
    except (ValueError, OSError):
        return ""
    return ""

def file_secret_kind(path):
    parts = [c for c in str(path).strip("\"\x27").split("/") if c]
    if not parts or any(c.isspace() for c in parts[-1]):
        return ""
    name = parts[-1]
    low = name.lower()
    dirs = [c.lower() for c in parts[:-1]]
    if low in (".env.example", ".env.sample", ".env.template") or low.endswith(SAFE_SUFFIX):
        return ""
    if low == ".env" or low.startswith(".env."):
        return "deny"
    if any(c in SECRET_DIRS for c in dirs):
        return "" if low.endswith(".pub") else "deny"
    for i, c in enumerate(dirs):
        nxt = dirs[i + 1] if i + 1 < len(dirs) else low
        if (c == ".config" and nxt in ("gcloud", "gh", "doctl")) or (c == ".docker" and low == "config.json") \
                or (c == "supabase" and nxt == ".temp" and i + 1 < len(dirs)):
            return "deny"   # supabase/.temp holds the linked project\u2019s database address and password (pooler-url)
    if low in SECRET_NAMES or (low.endswith(SECRET_SUFFIX) and low not in SECRET_SUFFIX) or SECRET_RE.match(low):
        return "deny"
    if low in ASK_NAMES:
        return "ask"
    if any(c in low for c in "*?[") and low.startswith(".env"):
        return "deny"
    if any(c in low for c in "*?[") and low.startswith(".") and len(re.sub(r"[*?\[\]]", "", low)) >= 3:
        for probe in GLOB_PROBES:
            if fnmatch.fnmatch(probe, low):
                return "ask" if probe in ASK_NAMES else "deny"
    return ""

def is_secret_env(path):
    return secret_kind(path) == "deny"

READ_ONLY_CMDS = {"cat", "head", "tail", "sed", "grep", "egrep", "fgrep", "rg", "wc", "less", "more", "nl", "ls", "stat", "file"}

def env_in_word(word, read=False):
    # Covers plain paths, globs (.env*, .en?), redirections glued to a word, VAR=path and @file forms.
    kinds = [secret_kind(part, read and not re.search(r"[<>]", word)) for part in re.split(r"[=:<>|,;()@]", word) if part]
    return "deny" if "deny" in kinds else "ask" if "ask" in kinds else "home" if "home" in kinds else ""

# ---- Bash parsing ------------------------------------------------------------------------------
SEPARATORS = {";", "&&", "||", "|", "&", "|&", "\n", "(", ")", "{", "}"}
WRAPPERS = {"env", "command", "builtin", "exec", "nohup", "time", "sudo", "nice", "doas", "xargs", "then", "do", "else", "if", "while", "until", "!"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}

def tokens(cmd):
    lex = shlex.shlex(cmd.replace("\\\n", " "), posix=True, punctuation_chars=";&|()")
    lex.whitespace_split = True
    lex.commenters = ""
    out = []
    try:
        for t in lex:
            out.append(t)
    except ValueError:
        # Unbalanced quotes: fall back to a plain split so a malformed command still gets checked.
        out = cmd.split()
    return out

def simple_commands(cmd, depth=0):
    """Yield each simple command (a list of words) in cmd, nested ones included."""
    if depth > 4:
        return
    for inner in re.findall(r"\$\(([^()]*(?:\([^()]*\)[^()]*)*)\)", cmd) + re.findall(r"`([^`]*)`", cmd):
        yield from simple_commands(inner, depth + 1)
    cur, last, last2 = [], "", ""
    for t in tokens(cmd.replace("\n", " ; ")) + [";"]:
        prev_t, last, last2 = last2, t, last
        if t in SEPARATORS or set(t) <= set(";&|()"):
            if t == "(" and cur == ["$"] and prev_t == ")":
                cur = []   # the `$` of a second `$(` right after a substitution: not a command named `$`
            if cur:
                yield from expand(cur, depth)
            cur = []
        else:
            cur.append(t)

BARE_ENV = []   # set when a command would print the whole environment

class Cmd(list):
    """A simple command (the name stripped to its basename, then the arguments) that remembers the first word as typed."""
    def __init__(self, words, raw):
        super().__init__(words)
        self.raw = raw

# Options that take a value, per wrapper, so `timeout 10 cmd`, `nice -n 5 cmd` and `xargs -a f cmd` reach the real command.
WRAPPER_VALUE_OPTS = {"sudo": {"-u", "-g", "-h", "-p", "-C", "-D", "-R", "-T", "-U", "-r", "-t"}, "doas": {"-u", "-C"},
                      "env": {"-u", "-C", "-S", "--unset", "--chdir"}, "nice": {"-n"}, "ionice": {"-c", "-n", "-p", "-P", "-t"},
                      "timeout": {"-s", "-k", "--signal", "--kill-after"}, "time": {"-f", "-o"}, "exec": {"-a"},
                      "stdbuf": {"-i", "-o", "-e"},
                      "xargs": {"-a", "-I", "-L", "-n", "-P", "-s", "-d", "-E", "-l", "--arg-file", "--max-args", "--delimiter"}}
WRAPPERS |= {"timeout", "setsid", "stdbuf", "ionice", "chronic", "unbuffer"}
INTERP_RE = re.compile(r"^(python|node|nodejs|ruby|perl|php|deno|bun)[0-9.]*$")
# Code in an interpreter one-liner that starts another process, which the guard then cannot read.
SPAWN_RE = re.compile(r"(subprocess|os\.system|os\.popen|os\.exec|os\.spawn|pty\.spawn|Popen|child_process|execSync|spawnSync|"
                      r"\bspawn\(|\bexecFile|\bexec\(|Deno\.Command|Bun\.spawn|Bun\.\$|\bsystem\(|\bpopen\(|shell_exec|passthru|"
                      r"proc_open|%x[({\[]|IO\.popen|Open3|\bexecv)")

def operands(words):
    """The words that are not options and not redirections (`<<<`, `> f`, `<<EOF`) or their targets."""
    out, skip = [], False
    for w in words:
        if skip:
            skip = False
            continue
        if re.match(r"^[0-9&]*(<<<|<<-?|<|>>?\|?)$", w):
            skip = True
            continue
        if w.startswith("-") or re.match(r"^[0-9&]*(<|>)", w):
            continue
        out.append(w)
    return out

def shell_script(words):
    """For `sh -c x`, `bash -lc x` and `sh -ec x`: the command string, else None."""
    for k, w in enumerate(words[1:], 1):
        if not w.startswith("-") or w == "--":
            break
        if re.match(r"^-[A-Za-z]*c[A-Za-z]*$", w) or w == "--command":
            rest = [x for x in words[k + 1:] if not x.startswith("-")]
            return rest[0] if rest else ""
    return None

SHELL_FETCH = re.compile(r"(^|[;&|(\s])(source|\.|eval|sh|bash|zsh|dash|ksh)\b[^;&|\n]*?(\$\(|`|<\()\s*(curl|wget)\b")
FETCH_RE = re.compile(r"(\$\(|`|<\()\s*(curl|wget)\b")

def ask_fetched():
    ask("this runs code that `curl` or `wget` fetches in the same command, and nobody has read it. Download it to a file, "
        "read it, then run it, or leave it to the owner.")

ENV_LISTERS = {"export", "declare", "typeset"}

def expand(words, depth):
    first = os.path.basename(words[0]) if words else ""
    stripped_env = False
    # Strip what only starts the real command: wrappers (with their options), `VAR=value` prefixes and keywords.
    while words:
        w, base = words[0], os.path.basename(words[0])
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", w):
            if env_in_word(w) == "deny":
                deny(f"`{w}` puts a secret or credential file name in a variable; agents never read or write it (AGENTS.md \u00a7 Golden rules).")
            words = words[1:]
            continue
        if base not in WRAPPERS:
            break
        stripped_env = stripped_env or base == "env"
        words = words[1:]
        values = WRAPPER_VALUE_OPTS.get(base, set())
        while words and words[0].startswith("-") and words[0] != "--":
            words = words[2:] if words[0] in values else words[1:]
        if words and words[0] == "--":
            words = words[1:]
        if base == "timeout" and words:
            words = words[1:]   # the duration
        if base == "xargs" and words:
            run = os.path.basename(words[0])
            if run in SHELLS or run == "eval" or INTERP_RE.match(run):
                ask("`xargs` starts a shell or an interpreter on text it reads, so the guard cannot see the commands it runs. "
                    "Name the command itself.")
    # `env` with nothing to run (also `env -0`, `env 2>&1`, `sudo env > f`) prints every variable, secrets included
    if stripped_env and not operands(words):
        BARE_ENV.append("env")
    if not words:
        return
    name = os.path.basename(words[0])
    args_ = operands(words[1:])
    if (name == "printenv" and not args_) or (name in ENV_LISTERS and not args_) or (name == "set" and len(words) == 1) \
            or (name == "compgen" and any(w in ("-v", "-e") or w in ("variable", "export") for w in words[1:])) \
            or (name in ("jq", "gojq", "jaq") and any(re.search(r"(^|[^\w$.])(env|\$ENV)\b", w) for w in args_)) \
            or (name == "ps" and len(words) > 1 and not words[1].startswith("-") and "e" in words[1]):
        BARE_ENV.append(name)
    if words[0].startswith(("$", "`")) and "/" not in words[0]:
        ask(f"`{words[0]}` builds the command name at run time, so the guard cannot see which command runs. Write the command out.")
    if name in SHELLS:
        script = shell_script(words)
        if script is not None:
            if FETCH_RE.search(script):
                ask_fetched()
            yield from simple_commands(script, depth + 1)
            return
        if not operands(words[1:]) or "-s" in words[1:]:
            ask(f"`{name}` reads its commands from a pipe, a here-string or a here-document, so the guard cannot see them. Write the commands out.")
    if name == "eval":
        if FETCH_RE.search(" ".join(words[1:])):
            ask_fetched()
        yield from simple_commands(" ".join(words[1:]), depth + 1)
        return
    if name in ("source", ".") and any(FETCH_RE.search(w) or w.startswith("<(") for w in words[1:]):
        ask_fetched()
    if name == "alias" and any("=" in w for w in words[1:]):
        ask("`alias` defines a command the guard cannot follow when it is used later in the chain. Write the command out.")
    if INTERP_RE.match(name):
        for k, w in enumerate(words[1:], 1):
            if w in ("-c", "-e", "-p", "-pe", "-E", "eval", "--eval", "--print") and k + 1 < len(words) and SPAWN_RE.search(words[k + 1]):
                ask(f"`{name} {w}` starts another process from inline code, so the guard cannot see what runs. Write the command out, or use a script file.")
    if name == "find" and any(w in ("-exec", "-execdir", "-ok", "-okdir") for w in words):
        # `find … -exec CMD … {} +`: check CMD like a command of its own.
        k = next(i for i, w in enumerate(words) if w in ("-exec", "-execdir", "-ok", "-okdir"))
        inner = []
        for w in words[k + 1:]:
            if w in (";", "+"):
                break
            inner.append(w)
        if inner:
            yield from expand(inner, depth + 1)
    yield Cmd([name] + words[1:], words[0])

# ---- git push --------------------------------------------------------------------------------
GIT_OPTS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env"}
# git config keys whose value is a command, a script folder or another config file that git runs or reads later, out of
# the guard\u2019s sight: setting one (`git config`, `git -c`, `--config-env`) asks. Matched without letter case.
CMD_CONFIG_KEYS = ("core.hookspath", "core.sshcommand", "core.pager", "core.editor", "core.fsmonitor", "core.askpass",
                   "core.gitproxy", "core.alternaterefscommand", "credential.helper", "credential.*.helper",
                   "sequence.editor", "diff.external", "diff.*.textconv", "diff.*.command", "difftool.*.cmd",
                   "mergetool.*.cmd", "merge.*.driver", "filter.*.clean", "filter.*.smudge", "filter.*.process", "alias.*",
                   "pager.*", "gpg.program", "gpg.*.program", "init.templatedir", "include.path", "includeif.*.path",
                   "remote.*.uploadpack", "remote.*.receivepack", "protocol.allow", "protocol.ext.allow", "uploadpack.packobjectshook",
                   "submodule.*.update", "sendemail.sendmailcmd", "sendemail.smtpserver", "web.browser", "browser.*.cmd",
                   "browser.*.path", "man.*.cmd", "man.*.path", "interactive.difffilter", "trailer.*.command", "trailer.*.cmd",
                   "gpg.ssh.defaultkeycommand", "mergetool.*.path", "difftool.*.path", "imap.tunnel", "sendemail.tocmd",
                   "sendemail.cccmd", "sendemail.headercmd")
# An editor or pager that only quiets git (`git -c core.editor=true rebase --continue`, `-c core.pager=cat`) is fine.
QUIET_VALUE = re.compile(r"^(true|false|:|cat|more|less( -[A-Za-z]+)*)$")
CONFIG_READS = {"--get", "--get-all", "--get-regexp", "--get-urlmatch", "--get-color", "--get-colorbool", "-l", "--list",
                "--unset", "--unset-all", "--remove-section", "-e", "--edit"}

def config_ask(key, how):
    ask(f"`{key}` ({how}) names a command, hook folder or config file that git runs or reads later, out of the guard\u2019s "
        "sight (hooks, ssh, pager, editor, credential helper, alias, filter); the owner approves it.")

def check_config_key(key, value, how):
    k = str(key).strip("\"\x27").lower()
    if "$" in k or "`" in k:
        ask(f"`{key}` ({how}) is a config key built at run time, so the guard cannot see which key is set. Write the key out.")
    if not any(fnmatch.fnmatchcase(k, p) for p in CMD_CONFIG_KEYS):
        return
    if (k in ("core.pager", "core.editor", "sequence.editor") or k.startswith("pager.")) and QUIET_VALUE.match(str(value).strip()):
        return
    config_ask(key, how)

def check_config_section(name, how):
    """Renaming a section into one whose keys run commands (`alias`, `core`, `filter.x`) sets those keys."""
    n = str(name).strip("\"\x27").lower()
    if "$" in n or "`" in n or any(fnmatch.fnmatchcase(n, p.rsplit(".", 1)[0]) for p in CMD_CONFIG_KEYS):
        config_ask(name, how)
PUSH_OPTS_WITH_VALUE = {"--repo", "--receive-pack", "--exec", "-o", "--push-option", "--signed", "--recurse-submodules"}

# State a command chain leaves behind for the next git command: where HEAD points after a checkout,
# switch or symbolic-ref (None = the real HEAD), remote.*.push values set by `git config`, new tags.
SIM = {"head": None, "push": [], "tags": set()}
HEAD_SUBST = re.compile(r"(\$\(|`)\s*git\s+(branch\s+--show-current|rev-parse\s+--abbrev-ref\s+HEAD|symbolic-ref\s+(--short\s+)?(-q\s+)?HEAD)\s*(\)|`)")

def git_out(git_dir_args, *args):
    try:
        r = subprocess.run(["git"] + git_dir_args + list(args), capture_output=True, text=True, timeout=5)
        return r.stdout.strip() if r.returncode == 0 else ""
    except subprocess.TimeoutExpired:
        # An empty answer would read as "not on an environment branch", so a git that hangs must block, not pass.
        deny("`git " + " ".join(args) + "` did not answer within 5 s, so the guard can\u2019t tell which branch this is. Retry; "
             "if git keeps hanging, look for a stuck git process or a lock file in .git.")
    except Exception:
        return ""

def current_branch(git_dir_args):
    if SIM["head"] is not None:
        return SIM["head"]
    return git_out(git_dir_args, "symbolic-ref", "--short", "-q", "HEAD")

def branch_of(ref, here):
    ref = ref.strip()
    if ref in ("HEAD", "@"):
        return here
    # Gerrit style magic refs push to the branch they name.
    for prefix in ("refs/for/", "refs/drafts/", "refs/publish/", "refs/heads/", "heads/"):
        if ref.startswith(prefix):
            return ref[len(prefix):].split("%")[0]
    return ref

def split_flags(rest):
    """Split the words after a git subcommand into (positional, flags); `--` ends the flags."""
    positional, flags = [], []
    for j, w in enumerate(rest):
        if w == "--":
            positional += rest[j + 1:]
            break
        (flags if w.startswith("-") else positional).append(w)
    return positional, flags

def follow_git(sub, rest, git_dir_args):
    """Update SIM for the git commands that move HEAD or change where a plain push goes, and deny
    deleting or force-moving an environment branch."""
    positional, flags = split_flags(rest)
    short = "".join(f[1:] for f in flags if re.match(r"^-[A-Za-z]+$", f))
    if sub in ("checkout", "switch"):
        if "--detach" in flags or (sub == "switch" and "d" in short):
            SIM["head"] = ""
            return
        for k, w in enumerate(rest):
            if w in ("-b", "-B", "-c", "-C", "--orphan") and k + 1 < len(rest):
                SIM["head"] = rest[k + 1]
                return
        if "--" in rest or not positional or positional[0] == "-":
            return
        if sub == "checkout" and not protected_branch(positional[0]) and os.path.exists(positional[0]):
            return   # a path restore, HEAD stays
        SIM["head"] = branch_of(positional[0], "")
    elif sub == "symbolic-ref":
        if len(positional) >= 2 and positional[0] == "HEAD":
            SIM["head"] = branch_of(positional[1], "")
    elif sub == "config":
        if len(positional) >= 2 and re.match(r"^remote\..+\.push$", positional[0]):
            SIM["push"].append(positional[1])
        pos, verb = positional, ""
        if pos and pos[0] in ("set", "get", "list", "unset", "remove-section", "rename-section", "edit"):
            verb, pos = pos[0], pos[1:]
        if verb == "rename-section" or "--rename-section" in flags:
            for w in pos[1:]:
                check_config_section(w, "git config renames a section to it")
        # a read flag counts only when no `--no-…` flag (`--no-list`) cancels it
        reads = any(f.split("=", 1)[0] in CONFIG_READS for f in flags) and not any(f.startswith("--no-") for f in flags)
        if verb in ("", "set") and "--rename-section" not in flags and not reads:
            if pos and ("$" in pos[0] or "`" in pos[0]):
                check_config_key(pos[0], "", "git config sets it")
            # `git config [-f file] <key> <value>`: a key with a value after it is set (a key alone is a read).
            for k, w in enumerate(pos[:-1]):
                check_config_key(w, pos[k + 1], "git config sets it")
    elif sub in ("clone", "init", "submodule"):
        # `git clone -c key=value` / `--config` sets config in the new repository, and `--template` copies its hooks.
        for k, w in enumerate(rest):
            if w in ("-c", "--config") and k + 1 < len(rest):
                key, _, value = rest[k + 1].partition("=")
                check_config_key(key, value, f"git {sub} {w} sets it")
            elif w.startswith("--config="):
                key, _, value = w.split("=", 1)[1].partition("=")
                check_config_key(key, value, f"git {sub} --config sets it")
            elif w == "--template" or w.startswith("--template="):
                config_ask("--template", f"git {sub} copies hooks from a template folder")
    elif sub == "tag":
        if positional and not any(f in ("-d", "--delete", "-l", "--list") for f in flags):
            SIM["tags"].add(positional[0])
    elif sub == "reset" and "--hard" in flags:
        ask("`git reset --hard` throws away uncommitted work and moves the branch; the owner approves it. Commit or stash first, or reset with `--soft`/`--mixed`.")
    elif sub == "clean" and ("--force" in flags or "f" in short) and "--dry-run" not in flags and "n" not in short:
        ask("`git clean -f` deletes untracked files, ignored ones too with `-x`, and nothing brings them back; the owner approves it. Run `git clean -n` to see what it would delete.")
    elif sub == "branch":
        if CONFIG_PROBLEMS and positional and (any(f in ("--delete", "--force", "--move") for f in flags) or re.search("[dDfmM]", short)):
            deny("`git branch` deletes, moves or forces a branch while the environment branches can\u2019t be read from "
                 "harness.config.yml (" + "; ".join(CONFIG_PROBLEMS[:3]) + "). Fix the config, then retry.")
        names = [x for x in positional if protected_branch(x)]
        if names and (any(f in ("--delete", "--force", "--move") for f in flags) or re.search("[dDfmM]", short)):
            deny(f"agents never delete, move or force `{names[0]}`: it is an environment branch and changes only through a PR "
                 "(AGENTS.md § Golden rules).")

def is_tag(spec, git_dir_args):
    name = spec.lstrip("+").split(":")[0]
    return (name.startswith("refs/tags/") or name in SIM["tags"]
            or bool(git_out(git_dir_args, "rev-parse", "-q", "--verify", "refs/tags/" + name)))

def check_git(words):
    i, git_dir_args, cfg_push = 1, [], []
    while i < len(words) and words[i].startswith("-"):
        opt = words[i]
        if opt.startswith("--config-env="):
            check_config_key(opt.split("=")[1], "", "git --config-env sets it")
        if opt in GIT_OPTS_WITH_VALUE and i + 1 < len(words):
            if opt in ("-c", "--config-env"):
                key, _, value = words[i + 1].partition("=")
                check_config_key(key, "" if opt == "--config-env" else value, f"git {opt} sets it")
            if opt == "-C":
                git_dir_args += ["-C", words[i + 1]]
            m = re.match(r"^remote\..+\.push=(.*)$", words[i + 1]) if opt == "-c" else None
            if m:
                cfg_push.append(m.group(1))
            i += 2
        else:
            i += 1
    if i >= len(words):
        return
    if words[i] != "push":
        follow_git(words[i], words[i + 1:], git_dir_args)
        return
    if CONFIG_PROBLEMS:
        deny("every `git push` is blocked because the environment branches can\u2019t be read: " + "; ".join(CONFIG_PROBLEMS[:3])
             + ". Fix `branches.integration`, `branches.production` and `environments` in harness.config.yml, then retry "
             "(/morph-doctor shows what the scripts read).")
    rest = words[i + 1:]
    positional, flags, j = [], [], 0
    while j < len(rest):
        w = rest[j]
        if w == "--":
            positional += rest[j + 1:]
            break
        if w.startswith("-"):
            flags.append(w)
            if w in PUSH_OPTS_WITH_VALUE and "=" not in w:
                j += 1
        else:
            positional.append(w)
        j += 1
    short = "".join(f[1:] for f in flags if re.match(r"^-[A-Za-z]+$", f))
    if any(f.startswith("--force") for f in flags) or "f" in short or any(p.startswith("+") for p in positional[1:]):
        deny("force pushes are not allowed (AGENTS.md § Golden rules). Push a new commit instead.")
    if any(f in ("--all", "--mirror", "--branches", "--prune") for f in flags):
        deny("`git push --all`, `--mirror` and `--prune` can update or delete the environment branches. Push your feature branch by name.")
    here = current_branch(git_dir_args)
    deleting = "--delete" in flags or "d" in short
    refspecs = positional[1:]
    tag_push = any(f in ("--tags", "--follow-tags") for f in flags)
    if refspecs and refspecs[0] == "tag":
        tag_push, refspecs = True, refspecs[1:]
    targets = []
    if not refspecs:
        # A bare push goes where remote.<name>.push says (set in the chain, with -c, or in the config), else to HEAD.
        remote = positional[0] if positional else "origin"
        configured = SIM["push"] + cfg_push + git_out(git_dir_args, "config", "--get-all", f"remote.{remote}.push").split()
        if configured:
            refspecs = configured
        else:
            targets.append(here)
    for spec in refspecs:
        spec = spec.lstrip("+")
        dst = spec.split(":", 1)[1] if ":" in spec else spec
        if "$" in dst or "`" in dst:
            ask(f"`git push` target `{dst}` is built at run time, so the guard cannot see which branch it is. "
                "Name the branch in the command.")
        if is_tag(spec, git_dir_args):
            tag_push = True
            continue
        if ":" in spec:
            src = spec.split(":", 1)[0]
            targets.append(branch_of(dst, here) if dst else branch_of(src, here))
        else:
            targets.append(branch_of(dst, here))
    for t in targets:
        if t and protected_branch(t):
            what = "delete" if deleting or any(s.startswith(":") for s in refspecs) else "push to"
            deny(f"agents never {what} `{t}`: it is an environment branch and moves only through a PR "
                 "(AGENTS.md § Golden rules). Push a feature branch and open a PR.")
    if tag_push and GROUP_ASK["publishes"]:
        ask("pushing a tag can start a release or a deploy on the code host; only the owner approves it. "
            "`guard.publishes: off` in harness.config.yml turns this prompt off.")

# ---- code host and remote databases --------------------------------------------------------------
REMOTE_DB = [
    (r"^supabase\b.*\bdb\s+push\b", "supabase db push"),
    (r"^supabase\b.*\bdb\s+reset\b.*--(linked|db-url)", "supabase db reset on a remote database"),
    (r"^supabase\b.*\bmigration\s+(up|repair)\b.*--(linked|db-url)", "supabase migration on a remote database"),
    (r"\bprisma\s+migrate\s+(deploy|resolve)\b", "prisma migrate deploy"),
    (r"^wrangler\b.*\bd1\b.*--remote\b", "wrangler d1 with --remote"),
    (r"^turso\s+db\s+shell\b", "turso db shell"),
    (r"^(heroku|fly|flyctl)\b.*\b(pg:push|pg:reset|postgres\s+connect)\b", "a hosted database command"),
]
# (group, pattern, label); the group is the guard.<group> switch in harness.config.yml.
DEPLOY_ASK = [
    ("deploys", r"^wrangler\b.*\b(deploy|publish|rollback)\b", "wrangler deploy"),
    ("deploys", r"^wrangler\b.*\bsecret(:|\s+)(put|delete|bulk)\b", "wrangler secret"),
    ("deploys", r"^(fly|flyctl)\b.*\b(deploy|launch)\b", "fly deploy"),
    ("deploys", r"^firebase\b.*\bdeploy\b", "firebase deploy"),
    ("deploys", r"^(netlify|ntl)\b.*\bdeploy\b", "netlify deploy"),
    ("deploys", r"^(netlify|ntl)\b.*\benv(:|\s+)(set|unset|import|clone|migrate)\b", "netlify env set"),
    ("deploys", r"^supabase\b.*\bfunctions\s+deploy\b", "supabase functions deploy"),
    ("schema_pushes", r"\bprisma\s+db\s+push\b", "prisma db push"),
    ("schema_pushes", r"\bprisma\s+(migrate\s+reset|db\s+execute)\b", "prisma migrate reset"),
    ("schema_pushes", r"^drizzle-kit\b.*\b(push|migrate)\b", "drizzle-kit push"),
    ("deploys", r"^(terraform|tofu)\b.*\b(apply|destroy)\b", "terraform apply"),
    ("deploys", r"^kubectl\b.*\bapply\b", "kubectl apply"),
    ("deploys", r"^helm\b.*\b(upgrade|install)\b", "helm upgrade"),
    ("publishes", r"^cargo\b.*\bpublish\b", "cargo publish"),
    ("publishes", r"^changeset\b.*\bpublish\b", "changeset publish"),
    ("publishes", r"^docker\b.*(\bpush\b|--push\b)", "docker push"),
    ("publishes", r"^(twine\s+upload|gem\s+push|poetry\s+publish|flit\s+publish|uv\s+publish|dotnet\s+nuget\s+push|mvn\b.*\bdeploy|gradlew?\b.*\bpublish)", "a package upload"),
    ("deploys", r"^supabase\b.*\b(secrets\s+(set|unset)|functions\s+delete|projects\s+(create|delete)|branches\s+(create|delete|update|disable)|domains\b|vanity-subdomains\b|network-(bans|restrictions)\b|ssl-enforcement\b|postgres-config\b|sso\b|config\s+push|storage\s+(cp|mv|rm))", "supabase on the hosted project"),
    ("deploys", r"^(wrangler|npx wrangler)\b.*\b(kv|r2|d1|queues|vectorize|hyperdrive|pages|secret|versions)[: ]+(key |bucket |namespace |project )?(put|delete|create|bulk|deploy|rollback|upload)\b", "wrangler on a hosted resource"),
]
# Matched on the command as typed, because the runner strip below removes a leading `npm`. Covers
# `pnpm --filter x publish`, `npm --workspace x publish` and `yarn npm publish`.
PUBLISH_ASK = re.compile(r"^(npm|pnpm|yarn|bun)\b.*\bpublish\b")
# vercel: only these subcommands read. A scoped one (`env`, `domains`, `dns`, …) reads only with `ls`
# and the like; `vercel env add|rm|update|pull`, `vercel alias set`, `vercel deploy`, `vercel pull` and a bare `vercel` ask.
VERCEL_READ = {"ls", "list", "inspect", "logs", "whoami", "login", "logout", "help", "link",
               "build", "dev", "bisect", "version"}
VERCEL_SCOPED = {"env", "domains", "dns", "alias", "aliases", "project", "projects", "certs", "teams",
                 "team", "git", "integration", "webhooks", "rolling-release"}
VERCEL_SCOPED_READ = {"ls", "list", "inspect", "help"}

def vercel_writes(line):
    words = line.split()[1:]
    if any(w in ("--version", "-v", "--help", "-h") for w in words):
        return False
    pos = [w for w in words if not w.startswith("-")]
    if not pos or pos[0] in VERCEL_READ:
        return not pos
    if pos[0] in VERCEL_SCOPED:
        return len(pos) < 2 or pos[1] not in VERCEL_SCOPED_READ
    return True

def dry_run(words):
    for w in words:
        if w in ("--dry-run", "--help", "-h"):
            return True
        if w.startswith("--dry-run=") and w.split("=", 1)[1].lower() not in ("none", "false", "no"):
            return True
    return False


GH_ASK = {"repo": {"delete", "archive", "unarchive", "rename", "create", "edit", "transfer"},
          "release": {"create", "delete", "edit", "upload", "delete-asset"},
          "workflow": {"run", "enable", "disable"}, "pr": {"merge"}, "auth": {"token", "login", "logout", "refresh", "setup-git"},
          "issue": {"delete", "transfer"}, "extension": {"install", "upgrade", "exec"}, "alias": {"set", "import"},
          "gist": {"create", "new", "edit", "delete", "rename"}}

def check_gh(words):
    if len(words) > 2 and words[2] in GH_ASK.get(words[1], ()):
        ask(f"`gh {words[1]} {words[2]}` changes the code host (deletes, releases, merges, workflow runs, credentials, extensions); only the owner approves it.")
    if len(words) > 2 and words[1] in ("secret", "variable") and words[2] in ("set", "delete", "remove"):
        deny("secrets and variables on the code host are the owner’s (the Shared remote environments golden rule in AGENTS.md).")
    if len(words) > 1 and words[1] == "api":
        rest = words[2:]
        method, path, writes = "", "", False
        k = 0
        while k < len(rest):
            w = rest[k]
            if w in ("-X", "--method") and k + 1 < len(rest):
                method = rest[k + 1].upper(); k += 2; continue
            if w.startswith("--method="):
                method = w.split("=", 1)[1].upper()
            elif w.startswith("-X") and len(w) > 2:
                method = w[2:].upper()
            elif w in ("-f", "-F", "--field", "--raw-field", "--input") or w.startswith(("--field=", "--raw-field=", "--input=")):
                writes = True
            elif not w.startswith("-") and not path:
                path = w
            k += 1
        if method in ("POST", "PUT", "PATCH", "DELETE") or (writes and method in ("", "POST")):
            if re.search(r"(secrets|variables)", path):
                deny("secrets and variables on the code host are the owner’s (the Shared remote environments golden rule in AGENTS.md).")
            if path.strip("/") == "graphql" and "mutation" not in " ".join(rest).lower():
                return   # a GraphQL query is a read
            # Every other write asks; update checks only read (GET), which .claude/settings.json allows.
            verb = method or "POST"
            ask(f"`gh api {path}` ({verb}) writes to the code host (merges, dispatches, settings, deletes); only the owner approves it.")

# ---- network and remote copies -------------------------------------------------------------------
CURL_BODY_LONG = ("--data", "--data-binary", "--data-raw", "--data-urlencode", "--data-ascii", "--form",
                  "--form-string", "--upload-file", "--json", "--post-data", "--post-file", "--body-data",
                  "--body-file")
REMOTE_COPY = {"scp", "sftp", "rsync", "nc", "ncat", "netcat", "socat", "telnet", "ftp", "ssh", "mosh"}
REMOTE_ARG = re.compile(r"^(rsync://|ssh://|([^/\s@]+@)?[A-Za-z0-9_.\[\]-]+:[^:])")

def url_hosts(words):
    from urllib.parse import urlparse
    hosts = []
    for w in words:
        if "://" in w:
            try:
                hosts.append((urlparse(w).hostname or "").lower())
            except ValueError:
                hosts.append("?")
    return hosts

def check_network(words):
    name, rest = words[0], words[1:]
    if not GROUP_ASK["network"]:
        return
    if name in ("curl", "wget"):
        sends = False
        for k, w in enumerate(rest):
            if w.startswith(CURL_BODY_LONG) or (re.match(r"^-[A-Za-z]*[dFT]", w) and not w.startswith("--")):
                sends = True
            method = ""
            if w in ("-X", "--request", "--method") and k + 1 < len(rest):
                method = rest[k + 1]
            elif w.startswith(("--request=", "--method=")):
                method = w.split("=", 1)[1]
            elif w.startswith("-X") and len(w) > 2:
                method = w[2:]
            if method and method.upper() not in ("GET", "HEAD"):
                sends = True
        if sends:
            hosts = url_hosts(rest)
            if not hosts or any(h not in ALLOW_HOSTS for h in hosts):
                ask(f"`{name}` sends a body or a non-GET request to a host outside the allow-list ({sorted(h for h in hosts if h not in ALLOW_HOSTS) or sorted(ALLOW_HOSTS)}); "
                    "that is how a file leaves the machine. `guard.network: off` or `guard.allow_hosts` in harness.config.yml changes this.")
    elif name in REMOTE_COPY:
        if name in ("rsync",) and not any(REMOTE_ARG.match(w) for w in rest if not w.startswith("-")):
            return
        ask(f"`{name}` copies files to or from another machine, or runs commands on one; only the owner approves it. "
            "`guard.network: off` in harness.config.yml turns this prompt off.")

MORPHNESS_URLS = ("https://api.github.com/repos/antarsoft/morphness/",
                  "https://raw.githubusercontent.com/antarsoft/morphness/")
CURL_READ_FLAG = re.compile(r"^(-[fsSL]+|--fail|--silent|--show-error|--location)$")

def dotted_path(url):
    # a `.` or `..` path segment, or anything that a server or URL parser could read as one; `compare/A...B` has neither
    from urllib.parse import unquote
    path = unquote(url.split("?", 1)[0].split("#", 1)[0])
    return "%" in path or "\\" in path or any(seg in (".", "..") for seg in path.split("/")[3:])

def check_curl(words):
    # .claude/settings.json allows `curl -fsSL <Morphness URL>/*`, and that pattern accepts any
    # trailing words. Stdout, GET, no body, no headers, no config file, one of the two prefixes.
    line = " ".join(words[1:]).lower()
    if not any(u[len("https://"):] in line for u in MORPHNESS_URLS):
        return
    for w in words[1:]:
        if "://" in w:
            if not w.startswith(MORPHNESS_URLS) or dotted_path(w):
                ask(f"`curl` with `{w}`: the allowed read is only the two Morphness GitHub prefixes, "
                    "no `.` or `..` path segment, and nothing else on the line.")
        elif not CURL_READ_FLAG.match(w):
            ask(f"`curl {w}` is more than a read of the Morphness repository: update checks print to "
                "the terminal only (no file, method, body, header or config). Use `gh api --method GET` "
                "or the plain `curl -fsSL <url>`.")

WRITERS = {"cp", "mv", "rm", "ln", "install", "tee", "truncate", "chmod", "chown", "chattr", "dd", "rsync",
           "patch", "ed", "ex", "vi", "vim", "nano", "touch", "unlink", "shred"}
INTERPRETERS = {"python", "python3", "node", "ruby", "perl", "php", "deno", "bun"}

def copy_targets(words):
    """The paths `cp`, `mv`, `install`, `ln` or `rsync` writes: the target, or each source name inside it when it is a
    folder (or `-t <dir>`), with every file of a source folder below that. `mv` also removes its sources, and `ln` makes
    a second name for them (a write through it changes them)."""
    name, ops, target = words[0], operands(words[1:]), None
    for k, w in enumerate(words[1:], 1):
        if w in ("-t", "--target-directory") and k + 1 < len(words):
            target = words[k + 1]
        elif w.startswith("--target-directory="):
            target = w.split("=", 1)[1]
    no_dir = any(w == "--no-target-directory" or re.match(r"^-[A-Za-z]*T", w) for w in words[1:] if not w.startswith("--") or w == "--no-target-directory")
    if target is not None:
        sources, into = [o for o in ops if o != target], True
    elif len(ops) > 1:
        target, sources = ops[-1], ops[:-1]
        t = expand_home(target.strip("\"\x27"))
        into = not no_dir and (name == "rsync" or target.endswith("/") or len(sources) > 1
                               or os.path.isdir(t if os.path.isabs(t) else os.path.join(ROOT, t)))
    else:
        return list(ops) if name == "mv" else []
    out = []
    for src in sources:
        s = expand_home(src.strip("\"\x27"))
        contents = (name == "rsync" and s.endswith("/")) or s.endswith("/.")
        base = os.path.join(target, os.path.basename(s.rstrip("/"))) if into and not contents else target
        out.append(base)
        full = s if os.path.isabs(s) else os.path.join(ROOT, s)
        if os.path.isdir(full) and not os.path.islink(full):
            seen = 0
            for top, dirs, names in os.walk(full):
                for n in names + dirs:
                    seen += 1
                    if seen > 5000:
                        break
                    out.append(os.path.join(base, os.path.relpath(os.path.join(top, n), full)))
    if not into:
        out.append(target)
    if name == "mv":
        out += sources
    if name == "ln":
        out += sources + [os.path.join(os.path.dirname(target.strip("\"\x27")), src) for src in sources if not os.path.isabs(src)]
    return out

def patch_paths(path):
    """The files a patch or mbox file changes (each path with its first one or two folders also stripped, for `-p`)."""
    try:
        with open(os.path.join(ROOT, expand_home(path.strip("\"\x27"))), encoding="utf-8", errors="replace") as f:
            text = f.read(2000000)
    except OSError:
        return None
    out = []
    for m in re.finditer(r"(?m)^(?:diff --git (\S+) (\S+)|(?:---|\+\+\+) (\S+)|rename (?:from|to) (\S+)|copy (?:from|to) (\S+))", text):
        for p in m.groups():
            if p and p != "/dev/null":
                parts = p.strip("\"").split("/")
                out += ["/".join(parts[k:]) for k in range(min(3, len(parts)))]
    return out

def archive_paths(name, words):
    """The files `tar -x` or `unzip` writes, read from the archive listing; None when it can\u2019t be listed."""
    dest, archive = ".", None
    rest = words[1:]
    if name == "unzip":
        for k, w in enumerate(rest):
            if w == "-d" and k + 1 < len(rest):
                dest = rest[k + 1]
        ops = [w for k, w in enumerate(rest) if not w.startswith("-") and not (k and rest[k - 1] in ("-d", "-x", "-P"))]
        archive = ops[0] if ops else None
        listing = ["unzip", "-Z1"]
    else:
        for k, w in enumerate(rest):
            if w in ("-C", "--directory") and k + 1 < len(rest):
                dest = rest[k + 1]
            elif w.startswith("--directory="):
                dest = w.split("=", 1)[1]
            elif w.startswith("--file="):
                archive = w.split("=", 1)[1]
            elif w == "--file" and k + 1 < len(rest):
                archive = rest[k + 1]
            elif re.match(r"^-?[A-Za-z]*f[A-Za-z]*$", w) and not w.startswith("--") and (k == 0 or w.startswith("-")):
                tail = w.lstrip("-")
                if tail.endswith("f") and k + 1 < len(rest):
                    archive = rest[k + 1]
                elif "f" in tail:
                    archive = tail[tail.index("f") + 1:] or None
        listing = ["tar", "-tf"]
    if not archive or archive == "-":
        return None, dest
    try:
        r = subprocess.run(listing + [os.path.join(ROOT, expand_home(archive.strip("\"\x27")))], capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.SubprocessError):
        return None, dest
    if r.returncode:
        return None, dest
    out = []
    for line in r.stdout.splitlines()[:20000]:
        parts = line.strip().lstrip("./").split("/")
        out += [os.path.join(dest, "/".join(parts[k:])) for k in range(min(3, len(parts)))]
    return out, dest

def git_globals(words):
    """(folders from `git -C`, the index of the subcommand) for a git command."""
    dirs, i = [], 1
    while i < len(words) and words[i].startswith("-"):
        if words[i] in GIT_OPTS_WITH_VALUE and i + 1 < len(words):
            if words[i] == "-C":
                dirs.append(words[i + 1].strip("\"\x27"))
            i += 2
        else:
            i += 1
    return dirs, i

def guarded_files():
    """The guard and the settings it rests on, as they are in this project (paths from the project root)."""
    lib = os.path.join(ROOT, "scripts/lib")
    return ["scripts/guard.sh", ".claude/settings.json", "harness.config.yml"] + sorted(
        "scripts/lib/" + n for n in (os.listdir(lib) if os.path.isdir(lib) else ()))

def git_restores(dirs, sub, args):
    """For `git checkout <commit> -- <paths>`, `git restore --source=<commit> <paths>` and `git stash pop|apply`, the
    guarded files this would change; None when the guard can\u2019t tell."""
    base = ["-C", dirs[-1]] if dirs else []
    def run(*a):
        try:
            r = subprocess.run(["git"] + base + list(a), capture_output=True, text=True, timeout=5)
            return r.stdout if r.returncode == 0 else None
        except (OSError, subprocess.SubprocessError):
            return None
    top = (run("rev-parse", "--show-toplevel") or "").strip()
    if sub == "stash":
        if not args or args[0] not in ("pop", "apply"):
            return []
        refs = [a for a in args[1:] if not a.startswith("-")]
        names = run("stash", "show", "--include-untracked", "--name-only", refs[0] if refs else "stash@{0}")
        if names is None:
            names = run("stash", "show", "--name-only", refs[0] if refs else "stash@{0}")
        return None if names is None else [n for n in names.split() if n in guarded_files()]
    source, paths = None, []
    if sub == "restore":
        for k, a in enumerate(args):
            if a in ("-s", "--source") and k + 1 < len(args):
                source = args[k + 1]
            elif a.startswith("--source="):
                source = a.split("=", 1)[1]
        paths = [a for k, a in enumerate(args) if not a.startswith("-") and not (k and args[k - 1] in ("-s", "--source"))]
    else:
        before = args[:args.index("--")] if "--" in args else args[:1]
        after = args[args.index("--") + 1:] if "--" in args else args[1:]
        commits = [a for a in before if not a.startswith("-")]
        source, paths = (commits[0] if commits else None), [a for a in after if not a.startswith("-")]
    if not source or not paths:
        return []
    here = os.path.relpath(os.path.join(ROOT, dirs[-1]) if dirs else ROOT, top or ROOT) if top else "."
    def covers(spec, f):
        spec = os.path.normpath(os.path.join(here, spec.strip("\"\x27"))) if not spec.startswith(":/") else spec[2:] or "."
        return spec in (".", "") or f == spec or f.startswith(spec.rstrip("/") + "/") or fnmatch.fnmatchcase(f, spec)
    hit = [f for f in guarded_files() if any(covers(sp, f) for sp in paths)]
    if not hit:
        return []
    changed = run("diff", "--name-only", source, "--", *[os.path.join(top or ROOT, f) for f in hit])
    return None if changed is None else [f for f in hit if f in changed.split()]

def guard_file_write(cmd, words):
    """Deny or ask when a Bash command writes one of the protected files."""
    name = words[0]
    if name in ("chmod", "chown", "chattr", "touch"):
        # no content change: only a guard file named outright counts (`chmod +x scripts/*.sh` is fine)
        named = [w for w in words[1:] if not any(c in w for c in "*?[") and protected_kind(w)]
        if named and name != "touch":
            protect(named[0], f"`{name}` changes it")
        return
    if name in ("cp", "mv", "install", "ln", "rsync"):
        named = [w for w in copy_targets(words) if protected_kind(w)]
        if named:
            protect(named[0], "`ln` links to it, and a write through the link changes it" if name == "ln" else f"`{name}` writes it")
        return
    if name in ("tar", "bsdtar", "gtar", "unzip"):
        if name == "unzip" or any(w in ("--extract", "--get") or (not w.startswith("--") and "x" in w.lstrip("-") and re.match(r"^-?[A-Za-z]+$", w))
                                  for w in words[1:2] + [w for w in words[2:] if w.startswith("-")]):
            files, dest = archive_paths(name, words)
            if files is None:
                if rel_inside(dest):
                    ask(f"`{name}` extracts an archive the guard can\u2019t list into the project, so it can\u2019t tell whether it "
                        "replaces the guard\u2019s own files; the owner approves it.")
                return
            named = [f for f in files if protected_kind(f)]
            if named:
                protect(named[0], f"`{name}` extracts over it")
        return
    if name in ("patch",) or (name == "git" and len(words) > 1):
        dirs, i = git_globals(words) if name == "git" else ([], 0)
        sub = words[i] if name == "git" and i < len(words) else name
        args = words[i + 1:] if name == "git" else words[1:]
        if sub in ("apply", "am", "patch"):
            if sub == "patch":
                files = [args[k + 1] for k, a in enumerate(args[:-1]) if a in ("-i", "--input", "<")]
                files += [a.split("=", 1)[1] for a in args if a.startswith("--input=")] + [a[1:] for a in args if a.startswith("<") and len(a) > 1]
                named = [w for w in args if protected_kind(w) and not w.startswith("-")]
            else:
                files = [a for k, a in enumerate(args) if not a.startswith("-") and not (k and args[k - 1] in ("--directory", "-p", "--include", "--exclude"))]
                named = []
            if sub == "apply" and any(a in ("--check", "--stat", "--numstat", "--summary") for a in args) and "--apply" not in args:
                return
            for f in files:
                changed = patch_paths(os.path.join(dirs[-1], f) if dirs else f)
                if changed is None:
                    continue
                named += [c for c in changed if protected_kind(os.path.join(dirs[-1], c) if dirs else c)]
            if not files:
                ask(f"`{sub}` reads a patch the guard can\u2019t see (from a pipe), so it can\u2019t tell whether it changes the "
                    "guard\u2019s own files; the owner approves it. Save the patch to a file and apply that.")
            if named:
                protect(named[0], f"`{sub}` patches it")
            return
        if name == "git":
            if sub in ("checkout", "restore", "stash"):
                changed = git_restores(dirs, sub, args)
                if changed is None:
                    ask(f"`git {sub}` may bring back an older copy of the guard\u2019s own files and the guard can\u2019t tell; "
                        "the owner approves it.")
                elif changed:
                    protect(changed[0], f"`git {sub}` replaces it with another version")
            named = [w for w in args if protected_kind(w)]
            named += [os.path.join(d, part) for d in dirs for w in args for part in re.split(r"[=:,\s]", w)
                      if part and protected_kind(os.path.join(d, part))]
            if named and sub in ("update-index", "checkout", "restore", "rm", "mv", "apply", "stash", "reset"):
                protect(named[0], f"`git {sub}` writes it")
            return
    if name == "dd":
        named = [w[3:] for w in words[1:] if w.startswith("of=") and protected_kind(w[3:])]
    elif name in ("curl", "wget"):
        from urllib.parse import urlparse
        rest = words[1:]
        outdir = "."
        for k, w in enumerate(rest):
            if w in ("--output-dir", "-P", "--directory-prefix") and k + 1 < len(rest):
                outdir = rest[k + 1]
            elif w.startswith(("--output-dir=", "--directory-prefix=")):
                outdir = w.split("=", 1)[1]
            elif re.match(r"^-P\S", w):
                outdir = w[2:]
        named = [os.path.join(outdir, rest[k + 1]) for k, w in enumerate(rest[:-1])
                 if (w in ("--output", "--output-document") or re.match(r"^-[A-Za-z]*[oO]$", w)) and protected_kind(os.path.join(outdir, rest[k + 1]))]
        named += [os.path.join(outdir, w.split("=", 1)[1]) for w in rest if w.startswith(("--output=", "--output-document="))
                  and protected_kind(os.path.join(outdir, w.split("=", 1)[1]))]
        # a remote name: `curl -O`, and wget whenever no `-O` names the file
        remote = name == "wget" and not any(w in ("-O", "--output-document") or w.startswith("--output-document=") for w in rest) \
            or name == "curl" and any(w in ("--remote-name", "--remote-name-all") or re.match(r"^-[A-Za-z]*O[A-Za-z]*$", w) for w in rest)
        if remote:
            for w in rest:
                if "://" in w:
                    try:
                        base = os.path.basename(urlparse(w.strip("\"\x27")).path) or "index.html"
                    except ValueError:
                        continue
                    if protected_kind(os.path.join(outdir, base)):
                        named.append(os.path.join(outdir, base))
        if named:
            protect(named[0], f"`{name}` downloads into it")
        return
    else:
        named = [w for w in words[1:] if protected_kind(w)]
    if not named:
        return
    sub = words[1] if len(words) > 1 else ""
    writes = (name in WRITERS
              or (name in ("sed", "perl", "ruby") and any(re.match(r"^-[A-Za-z]*i", w) or w.startswith("--in-place") for w in words[1:]))
              or (name in INTERPRETERS and any(w in ("-c", "-e", "-p", "-pe", "-pi") or w.startswith("-i") for w in words[1:]))
              or (name in ("awk", "gawk") and "-i" in words[1:] and "inplace" in " ".join(words)))
    if writes:
        protect(named[0], f"`{name}` writes it")

TMP_DIRS = ["/tmp", "/var/tmp", os.path.realpath(tempfile.gettempdir())]

def outside_repo(word):
    """True when a path word is outside the project (the project folder itself, its .git and anything
    built at run time count as outside); a path below /tmp does not."""
    w = expand_home(word)
    for var in ("${CLAUDE_PROJECT_DIR}", "$CLAUDE_PROJECT_DIR", "${PWD}", "$PWD"):
        w = w.replace(var, ROOT)
    if not w:
        return False
    if "$" in w or "`" in w:
        return True
    root = os.path.realpath(ROOT)
    for full in [w] if os.path.isabs(w) else [os.path.join(ROOT, d, w) for d in [""] + CD_DIRS]:
        full = os.path.normpath(full)
        for cand in {full, os.path.realpath(full)}:
            if cand in (ROOT, root, os.path.join(ROOT, ".git"), os.path.join(root, ".git")):
                return True
            if any(cand != b and under(cand, b) for b in (ROOT, root)):
                continue
            if any(cand != t and under(cand, t) for t in TMP_DIRS) and not under(root, cand):
                continue
            return True
    return False

def rel_inside(word):
    """True when a path word is the project folder or below it (a file path, unlike outside_repo, which also flags the folder itself)."""
    w = expand_home(word)
    if "$" in w or "`" in w:
        return False
    full = os.path.normpath(w if os.path.isabs(w) else os.path.join(ROOT, w))
    return any(under(c, b) for c in {full, os.path.realpath(full)} for b in (ROOT, os.path.realpath(ROOT)))

def check_rm(words):
    """Ask when a recursive rm reaches outside the repo."""
    flags = [w for w in words[1:] if w.startswith("-") and w != "--"]
    if not any(re.match(r"^-[A-Za-z]*[rR]", f) or f == "--recursive" for f in flags):
        return
    targets = []
    for k, w in enumerate(words[1:], 1):
        if w == "--":
            targets += words[k + 1:]
            break
        if not w.startswith("-"):
            targets.append(w)
    for t in targets:
        if outside_repo(t):
            ask(f"`rm -r` would delete `{t}`, which is outside this repo (or the repo itself, its .git, or a path built at run time); the owner approves it.")

FIND_FILTERS = {"-name", "-iname", "-path", "-ipath", "-wholename", "-iwholename", "-regex", "-iregex", "-newer", "-mtime", "-mmin"}

def check_find(words):
    """Ask when find deletes (-delete, -exec rm) from the repo root or outside it with no name or age
    filter: the same reach as `rm -rf .`."""
    runs = [os.path.basename(words[k + 1]) for k, w in enumerate(words[:-1]) if w in ("-exec", "-execdir", "-ok", "-okdir")]
    if "-delete" not in words and not any(r in ("rm", "unlink", "shred") for r in runs):
        return
    if any(w in FIND_FILTERS for w in words):
        return
    starts = []
    for w in words[1:]:
        if w.startswith("-") or w in ("(", "!", "\\("):
            break
        starts.append(w)
    for t in starts or ["."]:
        if outside_repo(t):
            ask(f"`find` would delete everything under `{t}`, which is this repo (or outside it, its .git, or a path built at run time); the owner approves it.")

# ---- known deploy, cloud and database CLIs: a call asks unless it is a listed read ---------------------
CLI_GROUP = {}
for _group, _names in (("deploys", "wrangler netlify ntl fly flyctl railway heroku gcloud gsutil aws az doctl kubectl helm "
                                    "pulumi terraform tofu firebase stripe render sst serverless sls amplify"),
                       ("schema_pushes", "psql mysql mariadb mongosh mongo redis-cli sqlcmd cockroach pscale turso")):
    for _n in _names.split():
        CLI_GROUP[_n] = _group
CLI_READ = {"get", "list", "ls", "describe", "show", "view", "info", "status", "inspect", "logs", "log", "tail", "whoami",
            "version", "help", "diff", "plan", "validate", "check", "search", "history", "doctor", "explain", "top",
            "events", "output", "outputs", "regions", "usage", "current", "lint", "template", "preview", "fmt",
            "graph", "providers", "api-resources", "api-versions", "cluster-info", "can-i", "dev", "types", "init"}
CLI_WRITE_EXTRA = {"sync", "cp", "mv", "rm", "rb", "mb", "scale", "restart", "undo", "annotate", "label",
            "taint", "untaint", "drain", "cordon", "uncordon", "replace", "ssh", "console", "shell", "proxy", "forward",
            "tunnel", "destroy", "up", "install", "upgrade", "uninstall", "release", "login", "logout", "auth", "token",
            "env", "secrets", "secret", "config:set", "unset", "invoke", "kill", "reboot", "terminate", "detach", "attach"}
CLI_NOUNS = {"env", "secrets", "secret", "release", "auth", "token", "config"}
CLI_SECRET = re.compile(r"(access-token|identity-token|secret-value|session-token|authorization-token|login-password|"
                        r"export-credentials|(^|[ :])token($|[ :]))")
CLI_LOCAL_OK = {"firebase": {"use", "emulators", "init"}, "stripe": {"listen"}, "terraform": {"init", "fmt", "validate"},
                "tofu": {"init", "fmt", "validate"}}
LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1", "0.0.0.0", "host.docker.internal", ""}
SQL_WRITE = re.compile(r"\b(insert|update|delete|drop|truncate|alter|create|grant|revoke|copy|merge|call|vacuum|reindex|"
                       r"cluster|lock|set|reset|do|refresh|comment|execute|replace|upsert|load|import)\b", re.I)
REDIS_READ = {"get", "mget", "keys", "scan", "ttl", "pttl", "exists", "type", "info", "ping", "dbsize", "hget", "hgetall",
              "hmget", "hkeys", "hlen", "llen", "lrange", "lindex", "smembers", "scard", "sismember", "zrange", "zcard",
              "zscore", "strlen", "memory", "slowlog", "client", "config", "time", "lastsave", "--version", "-v", "--help"}
MONGO_READ = re.compile(r"^\s*(db\.[\w.]+\.(find|findOne|count|countDocuments|estimatedDocumentCount|distinct)\(|"
                        r"show\s+\w+|db\.(getCollectionNames|stats|version)\()", re.S)
MONGO_WRITE = re.compile(r"(drop|delete|insert|update|remove|replace|bulkWrite|createIndex|rename|save|\$out|\$merge|"
                         r"runCommand|adminCommand|eval|\.exec\()", re.I)

def cli_asks(label):
    return ask(f"`{label}` can change a shared cloud, deploy or database resource unless it is a read; only the owner approves it "
               "(the Shared remote environments golden rule in AGENTS.md). The `guard:` switch in harness.config.yml turns this prompt off.")

def local_socket(host):
    """The hosts in a host value, one per entry of a comma list (libpq tries each): a folder path (`/tmp/pg`, `%2Ftmp%2Fpg`
    in a URL) names a Unix socket on this machine, so it counts as `localhost`."""
    from urllib.parse import unquote
    return ["localhost" if unquote(h).strip().startswith("/") else unquote(h).strip() for h in host.split(",")]

def db_url_hosts(url):
    """The hosts a database URL names: each entry of its host list and a `host=` or `hostaddr=` query value."""
    from urllib.parse import urlparse, parse_qsl
    u = urlparse(url)
    hosts = []
    for part in u.netloc.rsplit("@", 1)[-1].split(","):
        hosts.append(part[1:part.find("]")] if part.startswith("[") and "]" in part else part.split(":")[0])
    query = [v for k, v in parse_qsl(u.query) if k.lower() in ("host", "hostaddr")]
    if query:
        hosts = [h for h in hosts if h] + query
    return [h for v in hosts for h in local_socket(v.lower())] or [""]

def hosts_in(words):
    from urllib.parse import urlparse
    hosts = []
    for k, w in enumerate(words):
        if "://" in w:
            try:
                hosts += db_url_hosts(w.strip("\"\x27"))
            except ValueError:
                hosts.append("?")
        elif w in ("-h", "-H", "--host", "--hostname") and k + 1 < len(words):
            hosts.append(words[k + 1].strip("\"\x27").lower())
        elif re.match(r"^--host(name)?=", w):
            hosts.append(w.split("=", 1)[1].strip("\"\x27").lower())
        elif re.match(r"^-[hH]\S", w):
            hosts.append(w[2:].strip("\"\x27").lower())
    return [h for v in hosts for h in local_socket(v)]

def check_db(name, words):
    """Ask when a database client reaches a host that is not local, unless the statement is a read."""
    rest = words[1:]
    if any(w in ("--help", "-?", "--version", "-V", "-v") for w in rest):
        return
    hosts = hosts_in(rest)
    remote = any("$" in w or "`" in w for w in rest) or any(h not in LOCAL_HOSTS for h in hosts)
    if not remote:
        return
    stmt = ""
    for k, w in enumerate(rest):
        if w in ("-c", "--command", "-e", "--execute", "--eval", "--sql", "-q") and k + 1 < len(rest):
            stmt = rest[k + 1]
        elif re.match(r"^--(command|execute|eval|sql)=", w):
            stmt = w.split("=", 1)[1]
    if name == "redis-cli":
        cmd = [w for w in rest if not w.startswith("-")]
        known = [w for k, w in enumerate(rest) if not w.startswith("-") and (k == 0 or rest[k - 1] not in ("-h", "-p", "-a", "-n", "-u", "--user", "--pass"))]
        first = (known[0].lower() if known else "")
        if first in REDIS_READ:
            return
    elif name in ("mongosh", "mongo"):
        if stmt and MONGO_READ.match(stmt) and not MONGO_WRITE.search(stmt):
            return
    elif stmt:
        body = stmt.strip().lstrip("(").lower()
        if re.match(r"(select|show|explain|describe|desc|table|values|with|pragma|\\d)", body) and not SQL_WRITE.search(body):
            return
    cli_asks(name + " on a remote host")

# Packages whose command has another name: `npx firebase-tools@15 …` starts `firebase`.
PKG_BIN = {"firebase-tools": "firebase", "netlify-cli": "netlify", "eas-cli": "eas", "@railway/cli": "railway",
           "@aws-amplify/cli": "amplify", "@angular/cli": "ng", "@nestjs/cli": "nest", "@sentry/cli": "sentry-cli"}

def pkg_bin(word):
    """The command a package name starts, version and path dropped: `firebase-tools@15.32.1` -> `firebase`."""
    m = re.match(r"^(@[^/@]+/)?([^@/]+)(@.*)?$", str(word))
    name = (m.group(1) or "") + m.group(2) if m else str(word)
    return PKG_BIN.get(name, m.group(2) if m else os.path.basename(str(word)))

def runner_words(words):
    """The command a package runner starts: `npx wrangler deploy` -> wrangler deploy."""
    w = list(words)
    if w and w[0] in ("npx", "bunx", "pnpx"):
        w = w[1:]
    elif len(w) > 1 and w[0] in ("pnpm", "yarn", "bun", "npm") and w[1] in ("exec", "dlx", "x"):
        w = w[2:]
    else:
        return w
    while w and w[0].startswith("-") and w[0] != "--":
        w = w[1:]
    if w and w[0] == "--":
        w = w[1:]
    return w[:1] and [pkg_bin(w[0]) if "@" in w[0] or w[0] in PKG_BIN else os.path.basename(w[0])] + w[1:] or w

# Database migration tools: the subcommands that change the database. A target that is not local is denied (like
# `prisma migrate deploy`); a target the command line doesn\u2019t show (an env var, a config file) asks.
MIGRATE_WRITES = {"atlas": {"apply", "down", "clean"}, "sqitch": {"deploy", "revert", "rebase", "checkout"},
                  "flyway": {"migrate", "clean", "repair", "undo", "baseline"},
                  "goose": {"up", "up-by-one", "up-to", "down", "down-to", "redo", "reset"},
                  "dbmate": {"up", "migrate", "down", "rollback", "drop", "create", "load"},
                  "liquibase": {"drop-all", "dropall", "execute-sql", "executesql", "changelog-sync", "changelogsync", "tag",
                                "release-locks", "releaselocks", "changelog-sync-to-tag", "changelogsynctotag", "clear-checksums",
                                "clearchecksums", "mark-next-changeset-ran", "marknextchangesetran"}}
MIGRATE_WRITES["atlas"].add("set")
SERVICE_HOSTS = {"db", "database", "postgres", "postgresql", "pg", "mysql", "mariadb", "mongo", "mongodb", "redis"}
MIGRATE_LOCAL_SCHEMES = ("sqlite", "sqlite3", "file", "docker")
CMD_ASSIGNED_URLS = []   # URLs set in `VAR=value` prefixes of the command being checked (`DATABASE_URL=… goose up`)

def db_targets(rest):
    """The database hosts a migration command names: URLs (the host after the last `@`), `host=` DSNs, `tcp(host)`,
    `jdbc:…@host`, and `-h`/`--host`/`--db-host` values. A sqlite, file or docker URL is local; `--dev-url` is a scratch database."""
    from urllib.parse import urlparse
    hosts, skip = [], False
    for k, w in enumerate(rest):
        if skip:
            skip = False
            continue
        if w in ("--dev-url",):
            skip = True
            continue
        if w.startswith("--dev-url="):
            continue
        v = w.split("=", 1)[1] if re.match(r"^-{1,2}[\w-]+=", w) else w
        v = v.strip("\"\x27")
        if "://" in v:
            try:
                u = urlparse(re.sub(r"^(jdbc|db):", "", v, flags=re.I))
                hosts += ["localhost"] if u.scheme.lower() in MIGRATE_LOCAL_SCHEMES else db_url_hosts(re.sub(r"^(jdbc|db):", "", v, flags=re.I))
            except ValueError:
                hosts.append("?")
        for m in re.finditer(r"(?:^|\s)host=([^\s;]+)|tcp\(([^:)]+)|^jdbc:[\w:]+@(?://)?([\w.-]+)", v):
            hosts += local_socket((m.group(1) or m.group(2) or m.group(3)).lower())
        if w in ("-h", "--host", "--db-host", "--hostname") and k + 1 < len(rest):
            hosts += local_socket(rest[k + 1].strip("\"\x27").lower())
    return hosts

def check_migrate(words):
    name = words[0] if words else ""
    if name not in MIGRATE_WRITES or (name == "atlas" and dry_run(words)):
        return
    rest = [w for w in words[1:] if w != "--"]
    verbs = [w.lower() for w in rest if not w.startswith("-")]
    writes = [v for v in verbs if v in MIGRATE_WRITES[name]
              or (name == "liquibase" and re.match(r"^(update|rollback)", v) and not re.search(r"-?sql$", v))]
    if not writes:
        return
    # help only before the subcommand (`goose up -h` runs up), and `-h` is the database host in sqitch
    before = rest[:rest.index(next(w for w in rest if w.lower() == writes[0]))]
    if any(w in ("--help", "help", "--version", "version") or (w == "-h" and name != "sqitch") for w in before):
        return
    hosts = db_targets(rest) + [h for u in CMD_ASSIGNED_URLS for h in db_targets([u])]
    local_file = any(w.lower() in ("sqlite", "sqlite3") or re.search(r"\.(db|sqlite3?)$", w.lower()) for w in rest)
    remote = [h for h in hosts if h not in LOCAL_HOSTS]
    # a usual container service name (`db`, `postgres`) asks: it is often a local compose service; any other host is denied
    named = [h for h in remote if h not in SERVICE_HOSTS]
    if named:
        deny(f"`{name} {writes[0]}` changes the database at `{named[0]}`, which is not local; that is the owner\u2019s step "
             "(the Shared remote environments golden rule in AGENTS.md).")
    if remote and GROUP_ASK["schema_pushes"]:
        cli_asks(f"{name} {writes[0]} (the database host `{remote[0]}` may be a local service or another machine)")
    if not hosts and not local_file and GROUP_ASK["schema_pushes"]:
        cli_asks(f"{name} {writes[0]} (the database it targets is not on the command line)")

def check_cli(words):
    name = words[0]
    group = CLI_GROUP.get(name)
    if not group or not GROUP_ASK[group]:
        return
    if group == "schema_pushes":
        check_db(name, words)   # -h is a host here, not help
        return
    if dry_run(words):
        return
    rest = [w for w in words[1:] if w != "--"]
    if any(w in ("--version", "-v", "-V", "--help", "-h", "help") for w in rest):
        return
    positional = [w for w in rest if not w.startswith("-")]
    joined = " ".join(positional).lower()
    if CLI_SECRET.search(joined):
        cli_asks(f"{name} {joined}")
    tokens = [t for w in positional for t in re.split(r"[:/\s_=.\-]", w.lower()) if t]
    if positional and re.split(r"[:/]", positional[0].lower())[0] in CLI_LOCAL_OK.get(name, ()):
        return
    # Nouns like env or secrets only count as a write when no read verb comes with them (wrangler secret list).
    if any((t in WRITE_VERBS or t in CLI_WRITE_EXTRA) and t not in CLI_NOUNS for t in tokens) or not any(t in CLI_READ for t in tokens):
        cli_asks(f"{name} {joined}".strip())

# ---- code that is fetched and run, script files, deploy scripts, tree searches ---------------------
SEGMENT_END = lambda t: t in SEPARATORS or set(t) <= set(";&|()")

def bare(words):
    """The command in a list of words, without wrappers, VAR=value prefixes and their options."""
    words = list(words)
    while words:
        base = os.path.basename(words[0])
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0]):
            words = words[1:]
        elif base in WRAPPERS:
            words = words[1:]
            values = WRAPPER_VALUE_OPTS.get(base, set())
            while words and words[0].startswith("-") and words[0] != "--":
                words = words[2:] if words[0] in values else words[1:]
            if words and words[0] == "--":
                words = words[1:]
            if base == "timeout" and words:
                words = words[1:]
        else:
            break
    return words

DOWNLOADERS = {"curl", "wget", "fetch", "http", "https", "xh", "aria2c"}

def reads_stdin(words):
    """True for a shell or an interpreter that takes its program from standard input."""
    name = os.path.basename(words[0])
    if name in SHELLS:
        return shell_script(words) is None and (not operands(words[1:]) or "-s" in words[1:])
    if INTERP_RE.match(name):
        return "-" in words[1:] or (not operands(words[1:]) and not any(w in ("-c", "-e", "-p", "-pe", "-E", "--eval") for w in words[1:]))
    return False

def check_pipes(cmd):
    """Ask when a pipeline ends in a shell or interpreter that runs what it reads (`curl … | sh`, `base64 -d | sh`)."""
    segs, seps, cur = [], [], []
    for t in tokens(cmd.replace("\n", " ; ")):
        if SEGMENT_END(t):
            segs.append(cur)
            seps.append(t)
            cur = []
        else:
            cur.append(t)
    segs.append(cur)
    for i, sep in enumerate(seps):
        if sep not in ("|", "|&"):
            continue
        words = bare(segs[i + 1])
        if not words or not reads_stdin(words):
            continue
        j = i
        while j >= 0:
            prev = bare(segs[j])
            if prev and os.path.basename(prev[0]) in DOWNLOADERS:
                ask_fetched()
            if j > 0 and seps[j - 1] in ("|", "|&"):
                j -= 1
            else:
                break
        ask(f"`{os.path.basename(words[0])}` at the end of a pipe runs whatever the pipe prints, so the guard cannot see the commands. Write the commands out.")

KNOWN_RUNNERS = {"tsc", "tsx", "ts-node", "eslint", "prettier", "vitest", "jest", "playwright", "next", "vite", "turbo", "tailwindcss",
                 "prisma", "drizzle-kit", "supabase", "vercel", "wrangler", "biome", "tsup", "esbuild", "rollup", "webpack",
                 "storybook", "cypress", "mocha", "nx", "changeset", "lint-staged", "commitlint", "nodemon", "cross-env", "rimraf",
                 "expo", "eas", "netlify", "firebase", "stripe", "ruff", "black", "mypy", "pytest", "uvicorn", "alembic"}

def fetched_package(words):
    """The package a runner downloads and runs (`npx x`, `bunx x`, `pnpm dlx x`, `uvx x`), with its arguments; None when
    the runner only uses what is installed (`--no-install`, `pnpm exec`)."""
    name, rest = words[0], words[1:]
    if name in ("npx", "bunx", "pnpx", "uvx"):
        args = rest
    elif name in ("npm", "pnpm", "yarn", "bun") and rest[:1] in (["exec"], ["x"], ["dlx"]) and not (name in ("pnpm", "yarn") and rest[0] == "exec") \
            and not (name == "yarn" and rest[0] == "x"):
        args = rest[1:]
    elif name == "pipx" and rest[:1] == ["run"]:
        args = rest[1:]
    else:
        return None
    if any(a in ("--no-install", "--no", "--offline", "--prefer-offline") for a in args):
        return None
    pkg, k = "", 0
    while k < len(args):
        a = args[k]
        if a in ("-p", "--package", "--from") and k + 1 < len(args):
            pkg = args[k + 1]
            break
        if a.startswith(("--package=", "--from=")):
            pkg = a.split("=", 1)[1]
            break
        if a == "--":
            args = args[k + 1:]
            k = 0
            continue
        if not a.startswith("-"):
            pkg = a
            break
        k += 1
    if not pkg:
        return None
    return pkg, [a for a in args[k + 1:] if not a.startswith("-")]

def check_fetched_package(words):
    got = fetched_package(words)
    if not got or not GROUP_ASK["installs"]:
        return
    pkg, after = got
    short = pkg_bin(pkg)
    for base in [ROOT] + [os.path.join(ROOT, d) for d in CD_DIRS]:
        if any(os.path.exists(os.path.join(base, d, short)) for d in ("node_modules/.bin", ".venv/bin")):
            return
    if short == "skills" and after[:1] == ["add"]:
        ask("`skills add` downloads skills (instructions the agent then follows) from the internet; the owner reads what is added. "
            "`guard.installs: off` in harness.config.yml turns this prompt off.")
    if short in KNOWN_RUNNERS:
        return
    ask(f"`{words[0]} {pkg}` downloads `{short}` from the package registry and runs it, and it is not installed in this project. "
        "Add it as a dependency, or the owner approves the run. `guard.installs: off` in harness.config.yml turns this prompt off.")

DEPLOY_NAME = re.compile(r"(^|[:_./-])(deploy[a-z]*|release[a-z]*|promote[a-z]*|rollout|ship)($|[:_./-])")
PUBLISH_NAME = re.compile(r"(^|[:_./-])publish[a-z]*($|[:_./-])")
DEPLOY_FILE = re.compile(r"^(deploy|release|publish|promote|rollout)[\w.-]*$")
PM_VALUE_OPTS = {"--filter", "-F", "-C", "--cwd", "--prefix", "-w", "--workspace", "--dir", "--workspace-root"}

def check_deploy_script(words):
    """Ask when a task runner, package script or script file is named for a deploy or release: its commands are not visible."""
    if not words or dry_run(words):
        return
    name, rest = os.path.basename(words[0]), words[1:]
    targets, files = [], []
    if name in ("make", "gmake", "just", "task", "rake", "mage"):
        targets = [w for w in operands(rest) if "=" not in w]
    elif name in ("npm", "pnpm", "yarn", "bun"):
        ops, k = [], 0
        while k < len(rest):
            if rest[k] in PM_VALUE_OPTS:
                k += 2
                continue
            if not rest[k].startswith("-"):
                ops.append(rest[k])
            k += 1
        if ops[:1] in (["run"], ["run-script"]):
            targets = ops[1:2]
        elif name != "npm":
            targets = ops[:1]
    elif name in SHELLS or INTERP_RE.match(name):
        files = operands(rest)[:1]
    elif "/" in getattr(words, "raw", words[0]):
        files = [words.raw]
    for t in targets:
        for group, pattern in (("deploys", DEPLOY_NAME), ("publishes", PUBLISH_NAME)):
            if GROUP_ASK[group] and pattern.search(t.lower()):
                ask(f"`{name} {t}` runs a target or script named for a deploy, release or publish; its commands are not visible here, so the owner approves it. "
                    f"`guard.{group}: off` in harness.config.yml turns this prompt off.")
    for f in files:
        group = "publishes" if re.match(r"^publish", os.path.basename(f).lower()) else "deploys"
        if GROUP_ASK[group] and DEPLOY_FILE.match(os.path.basename(f).lower()):
            ask(f"`{f}` is a script named for a deploy, release or publish; its commands are not visible here, so the owner approves it. "
                f"`guard.{group}: off` in harness.config.yml turns this prompt off.")

SCAN_SKIP = {".git", "node_modules", ".next", ".venv", "venv", "dist", "build", "target", "__pycache__", ".cache"}

TOO_BIG = "(too many files to check)"

def secrets_in_tree(path, limit=20000, cap=200, follow=False):
    """The secret and credential files below a directory (a secret folder counts with each file in it), up to `cap`;
    dependency and build folders are skipped. TOO_BIG past `limit` entries. `follow`: the search follows folder links
    (`grep -R`), so the scan does too; a link to a secret folder that is not followed counts as one entry."""
    found, seen, visited = [], 0, set()
    for top, dirs, names in os.walk(path, followlinks=follow):
        real_top = os.path.realpath(top)
        if real_top in visited:
            dirs[:] = []
            continue
        visited.add(real_top)
        dirs[:] = [d for d in dirs if d not in SCAN_SKIP]
        # a folder counts by what is inside it: `.ssh/` does, a `kubeconfig/` package does not
        inside = top != path and (any(part in SECRET_DIRS for part in os.path.relpath(top, path).split(os.sep))
                                  or file_secret_kind(os.path.join(real_top, "x")) == "deny")
        for n in names + dirs:
            seen += 1
            if seen > limit:
                return TOO_BIG
            if len(found) >= cap:
                return found
            full = os.path.join(top, n)
            if n in dirs:
                hit = not follow and os.path.islink(full) and file_secret_kind(os.path.join(os.path.realpath(full), "x")) == "deny"
            else:
                hit = (inside and not n.endswith(".pub")) or file_secret_kind(full) == "deny" \
                    or (os.path.islink(full) and file_secret_kind(os.path.realpath(full)) == "deny")
            if hit:
                found.append(full)
    return found

def search_filters(name, rest):
    """The file filters of a recursive grep or rg search, in command-line order (the last one that matches a file decides):
    a list of (kind, glob, case_insensitive), kind include, exclude or exclude_dir for grep, glob for rg (`!` kept).
    Words after `--` are operands, not filters."""
    if "--" in rest:
        rest = rest[:rest.index("--")]
    rg_icase = name == "rg" and "--glob-case-insensitive" in rest
    out = []
    for k, w in enumerate(rest):
        flag, value = w, None
        if w.startswith("--") and "=" in w:
            flag, value = w.split("=", 1)
        elif name == "rg" and w.startswith("-g") and len(w) > 2:
            flag, value = "-g", w[2:]
        elif k + 1 < len(rest) and w in ("--include", "--exclude", "--exclude-dir", "--glob", "--iglob", "-g"):
            value = rest[k + 1]
        if value is None:
            continue
        value = value.strip("\"\x27")
        if name == "rg" and flag in ("--glob", "-g", "--iglob"):
            out.append(("glob", value, flag == "--iglob" or rg_icase))
        elif name != "rg" and flag in ("--include", "--exclude", "--exclude-dir"):
            out.append((flag[2:].replace("-", "_"), value, False))
    return out

def glob_regex(glob, rg):
    """A grep (fnmatch) or rg glob as a regex for a whole name or path. rg: `*` and `?` stop at `/`, `**` crosses it, one
    level of `{a,b}`; grep: no braces. `[!x]` and `[^x]` negate in both. None for a glob the guard cannot read."""
    out, i, depth = "", 0, 0
    while i < len(glob):
        c = glob[i]
        if c == "\\" and i + 1 < len(glob):
            out += re.escape(glob[i + 1]); i += 2; continue
        if c == "*":
            if rg and glob.startswith("**", i):
                after = glob[i + 2:i + 3]
                if after == "/":
                    out += "(?:.*/)?"; i += 3; continue
                out += ".*"; i += 2; continue
            out += "[^/]*" if rg else ".*"
        elif c == "?":
            out += "[^/]" if rg else "."
        elif c == "[":
            j = glob.find("]", i + 2 if glob[i + 1:i + 2] in ("!", "^") else i + 1)
            if j < 0:
                out += re.escape(c)
            else:
                body = glob[i + 1:j]
                neg = body[:1] in ("!", "^")
                body = body[1:] if neg else body
                out += "[" + ("^" if neg else "") + body.replace("\\", "\\\\").replace("[", "\\[") + "]"
                i = j
        elif rg and c == "{":
            if depth:
                return None
            depth += 1; out += "(?:"
        elif rg and c == "}" and depth:
            depth -= 1; out += ")"
        elif rg and c == "," and depth:
            out += "|"
        else:
            out += re.escape(c)
        i += 1
    return None if depth else out

def search_reads(name, display, rel, filters):
    """True when a recursive grep or rg with these filters may read the file at `rel` (relative to the searched folder;
    `display` is the path as rg prints it). An unreadable glob counts as reading the file."""
    parts = [p for p in rel.split("/") if p not in ("", ".")]
    base, dirs = parts[-1], parts[:-1]
    def hit(glob, text, icase, rg):
        rx = glob_regex(glob, rg)
        return rx is None or re.fullmatch(rx, text, re.S | (re.I if icase else 0)) is not None
    if name != "rg":
        # GNU grep: --exclude-dir skips a folder whose base name matches; --include and --exclude match the base name,
        # the last matching one wins, and with none matching the file is read unless the first filter is --include.
        if any(hit(g, d, False, False) and glob_regex(g, False) is not None for kind, g, _ in filters if kind == "exclude_dir" for d in dirs):
            return False
        files = [(kind, g) for kind, g, _ in filters if kind in ("include", "exclude")]
        last = None
        for kind, g in files:
            if glob_regex(g, False) is None or hit(g, base, False, False):
                last = kind if glob_regex(g, False) is not None else "include"
        if last:
            return last == "include"
        return not (files and files[0][0] == "include")
    # rg: the last matching glob wins; `!glob` leaves a file (or a folder) out; with any plain glob, a file that matches
    # none is left out. A glob without `/` matches a name at any depth, one with `/` the path rg prints.
    dparts = [p for p in display.split("/") if p not in ("", ".")]
    def rg_match(glob, icase, as_dir):
        g = glob.rstrip("/") if as_dir else glob
        if glob.endswith("/") and not as_dir:
            return False
        if "/" not in g:
            names = dirs if as_dir else [base]
            return any(hit(g, n, icase, True) for n in names)
        g = g.lstrip("/")
        targets = ["/".join(dparts[:k]) for k in range(1, len(dparts))] if as_dir else ["/".join(dparts)]
        return any(hit(g, t, icase, True) for t in targets)
    decision, plain = None, False
    for kind, glob, icase in filters:
        neg = glob.startswith("!")
        g = glob[1:] if neg else glob
        if not neg:
            plain = True
            if glob_regex(g.lstrip("/"), True) is None or rg_match(g, icase, False):
                decision = True
        elif glob_regex(g.lstrip("/").rstrip("/"), True) is not None and (rg_match(g, icase, False) or rg_match(g, icase, True)):
            decision = False
    if decision is not None:
        return decision
    return not plain

def glob_escape(text):
    return re.sub(r"([*?\[\]{}\\!])", r"\\\1", text)

def exclude_hint(name, full, rel):
    """The filter that leaves this secret file out of a grep or rg search: its secret folder, else its exact name."""
    parts = rel.split("/")
    folder = None
    for k in range(len(parts) - 1):
        sub = os.path.join(full, *parts[:k + 1])
        if parts[k] in SECRET_DIRS or file_secret_kind(os.path.join(os.path.realpath(sub), "x")) == "deny":
            folder = parts[k]
            break
    base = parts[-1]
    glob = ".env*" if base.startswith(".env") else glob_escape(base)
    if name == "rg":
        return f"-g \"!{glob_escape(folder)}/\"" if folder else f"-g \"!{glob}\""
    return f"--exclude-dir=\"{glob_escape(folder)}\"" if folder else f"--exclude=\"{glob}\""

SEARCH_VALUE_OPTS = ({"-m", "-A", "-B", "-C", "-d", "-D", "-e", "-f", "--regexp", "--file", "--include", "--exclude", "--exclude-dir",
                      "--exclude-from", "--label", "--group-separator", "--max-count", "--context", "--after-context",
                      "--before-context", "--devices", "--directories", "--binary-files"},
                     {"-g", "--glob", "--iglob", "-t", "--type", "-T", "--type-not", "-m", "--max-count", "-A", "-B", "-C", "-M",
                      "-e", "-f", "--regexp", "--file", "--max-columns", "-j", "--threads", "-d", "--max-depth", "--sort", "--sortr",
                      "-r", "--replace", "-E", "--encoding", "--max-filesize", "--type-add", "--type-clear", "--ignore-file", "--pre",
                      "--pre-glob", "--context-separator", "--color", "--colors", "--engine", "--path-separator",
                      "--field-match-separator", "--field-context-separator", "--dfa-size-limit", "--regex-size-limit",
                      "--hyperlink-format"})

SEARCH_SHORT = set("rRnilLwxvcohHsqIEFPzZUuSNap.")   # short grep and rg flags that take no value

def check_tree_search(words):
    """A recursive grep (or `rg --hidden`) over a tree that holds a secret file reads it; deny unless its filters
    (`--include`, `--exclude`, `--exclude-dir`, rg `-g`) leave every secret file out, and name the filter that would."""
    name, rest = words[0], words[1:]
    flags = [w for w in rest if w.startswith("-")]
    if name in ("grep", "egrep", "fgrep", "zgrep"):
        recursive = any(w in ("--recursive", "--dereference-recursive") or re.match(r"^-[A-Za-z]*[rR][A-Za-z]*$", w) for w in flags)
    elif name == "rg":
        recursive = any(w in ("--hidden", "-.", "--no-ignore", "--no-ignore-vcs") or re.match(r"^-u{2,}$", w) for w in flags)
    else:
        return
    if not recursive:
        return
    follow = any(w == "--dereference-recursive" or re.match(r"^-[A-Za-z]*R[A-Za-z]*$", w) for w in flags) if name != "rg" \
        else any(w in ("-L", "--follow") for w in flags)
    filters = search_filters(name, rest)
    # an option value given as the next word (`-g x`, `-e pat`) is not the pattern or a path
    takes_value = SEARCH_VALUE_OPTS[name == "rg"]
    value_next = lambda w: w in takes_value or re.match(r"^-[A-Za-z]*[ef]$", w)
    ops = operands([w for k, w in enumerate(rest) if not (k and value_next(rest[k - 1]))])
    own_pattern = any(w in ("-e", "--regexp", "-f", "--file") or w.startswith(("--regexp=", "--file=")) or re.match(r"^-[A-Za-z]*[ef]", w)
                      for w in flags if not w.startswith("--") or w.startswith(("--regexp", "--file")))
    paths = ops if own_pattern else ops[1:]
    # a short option the guard does not know may take the next word: then, if no path given exists, `.` may be searched
    risky = any(k and re.match(r"^-[^-]", rest[k - 1]) and not set(rest[k - 1][1:]) <= SEARCH_SHORT and not value_next(rest[k - 1])
                for k, w in enumerate(rest) if w in ops)
    if not paths or (risky and not any(os.path.exists(os.path.join(ROOT, expand_home(p))) for p in paths)):
        paths = paths + ["."]
    for pth in paths:
        full = os.path.normpath(os.path.join(ROOT, expand_home(pth)))
        if os.path.isdir(full) and rel_inside(pth):
            found = secrets_in_tree(full, follow=follow)
            if found == TOO_BIG:
                ask(f"`{name}` over `{pth}` searches more files than the guard can check for secret files; the owner approves it. "
                    "Search the folder you mean (`src/`).")
                continue
            def shown(h):
                r = os.path.relpath(h, full).replace(os.sep, "/")
                return r if pth in (".", "./") else os.path.normpath(pth).replace(os.sep, "/") + "/" + r
            hits = [h for h in found if search_reads(name, shown(h), os.path.relpath(h, full).replace(os.sep, "/"), filters)]
            if hits:
                hints = []
                for h in hits:
                    hint = exclude_hint(name, full, os.path.relpath(h, full).replace(os.sep, "/"))
                    if hint not in hints:
                        hints.append(hint)
                more = f" (and {len(hints) - 5} more)" if len(hints) > 5 else ""
                flags_to_add = " ".join(hints[:5])
                deny(f"`{name}` over `{pth}` would read `{os.path.relpath(hits[0], ROOT)}`, a secret or credential file; agents never "
                     f"read it (AGENTS.md § Golden rules). Add `{flags_to_add}`{more} after the other filters to leave the secret "
                     "files out, or search the folder you mean (`src/`).")


# The Grep tool `type` filter, for the types that can hold the name of a secret file (secrets.json, credentials.yml).
# A type not listed here counts as searching every file.
GREP_TYPE_EXT = {"json": ("json",), "yaml": ("yaml", "yml"), "toml": ("toml",), "xml": ("xml",), "ini": ("ini",),
                 "config": ("conf", "cfg", "ini", "json", "yaml", "yml", "toml", "properties", "xml", "config"),
                 "txt": ("txt",), "md": ("md", "markdown"), "markdown": ("md", "markdown"), "ts": ("ts", "tsx", "mts", "cts"),
                 "js": ("js", "jsx", "mjs", "cjs", "vue"), "py": ("py", "pyi"), "go": ("go",), "rust": ("rs",), "java": ("java",),
                 "css": ("css", "scss"), "html": ("html", "htm"), "sh": ("sh", "bash", "zsh"), "sql": ("sql",), "rb": ("rb",)}

def grep_glob_names(glob):
    """The Grep tool glob as fnmatch patterns: `*.{ts,tsx}` -> `*.ts`, `*.tsx` (one brace list)."""
    m = re.match(r"^(.*)\{([^{}]*)\}(.*)$", glob)
    return [m.group(1) + p + m.group(3) for p in m.group(2).split(",")] if m else [glob]

def check_grep_tree(path, glob, typ):
    """The Grep tool over a folder that holds a secret file asks, as `grep -r` denies, unless its glob or type leaves the file out."""
    full = os.path.normpath(os.path.join(ROOT, expand_home(path)))
    try:
        real = os.path.realpath(full)
    except (ValueError, OSError):
        return
    if file_secret_kind(os.path.join(real, "x")) == "deny":
        deny(f"Grep over `{path}` searches `{real}`, a folder of secret or credential files; agents never read it.")
    if not os.path.isdir(real):
        return
    negate = glob.startswith("!")
    globs = [g.lower().rsplit("/", 1)[-1] for g in grep_glob_names(glob.lstrip("!"))] if glob else []
    def searched(name):
        low = name.lower()
        if globs and any(fnmatch.fnmatchcase(low, g) for g in globs) == negate:
            return False
        if typ and typ.lower() in GREP_TYPE_EXT and not low.endswith(tuple("." + e for e in GREP_TYPE_EXT[typ.lower()])):
            return False
        return True
    top_hit, seen, visited = None, 0, set()
    for top, dirs, names in os.walk(real):
        if os.path.realpath(top) in visited:
            dirs[:] = []
            continue
        visited.add(os.path.realpath(top))
        dirs[:] = [d for d in dirs if d not in SCAN_SKIP]
        seen += len(names) + len(dirs)
        if seen > 20000:
            ask(f"Grep over `{path}` searches more files than the guard can check for secret files; the owner approves it. "
                "Search the folder you mean, or narrow it with `glob` or `type`.")
        for n in names + dirs:
            f = os.path.join(top, n)
            # a folder is walked into, so only a link to a secret folder (which the search does not enter) counts as one
            secret = os.path.islink(f) and file_secret_kind(os.path.join(os.path.realpath(f), "x")) == "deny" if n in dirs else \
                (file_secret_kind(f) == "deny" or (os.path.islink(f) and file_secret_kind(os.path.realpath(f)) == "deny"))
            if secret and (n in dirs or searched(n)):
                top_hit = f
                break
        if top_hit:
            break
    if top_hit:
        ask(f"Grep over `{path}` would read `{os.path.relpath(top_hit, ROOT)}`, a secret or credential file. Narrow it with `glob` "
            "or `type` (`*.ts`), or search the folder you mean; otherwise the owner approves it.")

def check_bash(cmd):
    # `$(git branch --show-current)` and its kin are the current branch: read them as HEAD.
    cmd = HEAD_SUBST.sub("HEAD", cmd)
    CMD_ASSIGNED_URLS[:] = [m.group(2) for m in re.finditer(
        r"(?:^|[\s;&|(])[A-Za-z_]\w*=([\"\x27]?)([A-Za-z][\w+.-]*://[^\s\"\x27]+)\1", cmd)]
    # Heredoc bodies are text (a commit message, a PR body), not commands: keep only their first line.
    cmd = re.sub(r"(<<-?\s*([\x27\"]?)(\w+)\2[^\n]*)\n.*?\n[ \t]*\3[ \t]*(?=\n|\)|$)", r"\1", cmd, flags=re.S)
    for words in simple_commands(cmd):
        if words[0] in ("cd", "pushd") and len(words) > 1:
            CD_DIRS.append(words[-1].strip("\"\x27"))
        if words[0] == "ln":
            # a link to a secret file or folder reads it under another name in the same command (`ln -s ~/.ssh k && cat k/config`)
            for w in operands(words[1:]):
                t = expand_home(w.strip("\"\x27"))
                if file_secret_kind(t) == "deny" or ((os.path.basename(t.rstrip("/")) in SECRET_DIRS or os.path.isdir(os.path.join(ROOT, t)))
                                                     and file_secret_kind(os.path.join(t, "x")) == "deny"):
                    deny(f"`ln` to `{w}` would let a secret or credential file be read under another name; agents never read it.")
    if BARE_ENV:
        # Before any ask below: `env | curl -d @- …` would otherwise stop at the curl prompt, and one yes sends every secret.
        deny(f"`{BARE_ENV[0]}` here prints every environment variable, secrets included (as a bare `env` or `printenv` does). "
             "Name the variable you need (`printenv NAME`).")
    check_pipes(cmd)
    if SHELL_FETCH.search(cmd):
        ask_fetched()
    # Files this command writes, so that running one of them in the same command is seen (see run_target below).
    written = set()
    def norm(path):
        return os.path.normpath(str(path).strip("\"\x27"))
    # A redirect (`> f`, `>> f`, `>|f`, `tee`-less here-doc writes) onto a protected file.
    for m in re.finditer(r"[0-9&]?>>?\|?\s*([^\s;&|<>()]+)", cmd):
        protect(m.group(1), "a redirect writes it")
        written.add(norm(m.group(1)))
    for words in simple_commands(cmd):
        guard_file_write(cmd, words)
        ops = operands(words[1:])
        if words[0] == "tee":
            written |= {norm(x) for x in ops}
        elif words[0] in ("cp", "mv", "install") and len(ops) > 1:
            written.add(norm(ops[-1]))
        elif words[0] in ("curl", "wget"):
            for k, w in enumerate(words[1:-1], 1):
                if w in ("-o", "--output", "-O", "--output-document"):
                    written.add(norm(words[k + 1]))
        run = ""
        if words[0] in SHELLS and shell_script(words) is None or INTERP_RE.match(words[0]) or words[0] in ("source", "."):
            run = ops[0] if ops else ""
        elif "/" in getattr(words, "raw", words[0]):
            run = words.raw
        if run and norm(run) in written:
            ask(f"`{run}` is a file this same command wrote, so the guard cannot see what it does when it runs. "
                "The owner reads the command, file contents included, and approves it.")
        check_fetched_package(words)
        check_deploy_script(words)
        check_tree_search(words)
        prev = ""
        # Computed once per command: inside the loop it made a long argument list quadratic (20,000 words took minutes).
        redirects = any(re.match(r"^(\d*>|&>)" if words[0] != "sed" else r"^(\d*>|&>|-i|--in-place)", x) for x in words[1:])
        reads_only = words[0] in READ_ONLY_CMDS and not redirects
        for w in words[1:]:
            skipped = bool(re.match(r"^--(exclude(-dir)?|glob|iglob|ignore)=", w)) or w.startswith("!") \
                or (words[0] in ("grep", "egrep", "fgrep", "zgrep", "rg", "ag", "ack") and prev in ("--exclude", "--exclude-dir", "--glob", "--iglob", "-g"))
            prev = w
            if skipped:
                continue   # an exclude pattern such as --exclude=.env* names a secret in order to leave it out
            if re.search(r"^/proc/[^/]+/environ$", w):
                deny("`/proc/<pid>/environ` is the whole environment, secrets included.")
            kind = env_in_word(w, reads_only)
            if kind == "deny":
                deny(f"`{w}` is a secret or credential file; agents never read or write it (AGENTS.md § Golden rules). Use .env.example for names.")
            if kind == "ask":
                ask(f"`{w}` often holds registry tokens; the owner approves a read or change of it.")
            if kind == "home":
                ask(f"`{w}` is under ~/.claude: Claude Code settings, permissions and other projects\u2019 transcripts; the owner approves a read or change of it.")
        line = " ".join(words)
        if GROUP_ASK["publishes"] and PUBLISH_ASK.search(line) and not dry_run(words):
            ask("`publish` releases a package to a shared registry; only the owner approves it (the Shared remote environments golden rule in AGENTS.md). "
                "`guard.publishes: off` in harness.config.yml turns this prompt off.")
        # `npx supabase …`, `pnpm exec prisma …`: match the tool the runner starts.
        line = re.sub(r"^(npx|bunx|pnpx|(pnpm|yarn|bun|npm)(\s+(exec|dlx|x))?)(\s+-\S+)*\s+(--\s+)?", "", line)
        line = re.sub(r"^\S+", lambda m: pkg_bin(m.group(0)) if m.group(0) in PKG_BIN or re.match(r"^(@[^/@]+/[^@/]+|[^@/]+)@", m.group(0)) else m.group(0), line)
        check_network(words)
        if words[0] == "crontab" and "-l" not in words[1:]:
            ask("`crontab` installs a schedule that runs commands later; the owner approves it.")
        if words[0] == "rm":
            check_rm(words)
        if words[0] == "find":
            check_find(words)
        if words[0] == "git":
            check_git(words)
        elif words[0] == "gh":
            check_gh(words)
        elif words[0] == "curl":
            check_curl(words)
        for pattern, label in REMOTE_DB:
            if re.search(pattern, line):
                deny(f"{label} writes a remote database; that is the owner’s step (the Shared remote environments golden rule in AGENTS.md).")
        if GROUP_ASK["deploys"] and re.match(r"^vercel\b", line) and not dry_run(words) and vercel_writes(line):
            ask("`vercel` deploys to or changes a shared environment (deploy, env add|rm|update, alias set, …); only the owner approves it "
                "(the Shared remote environments golden rule in AGENTS.md). `guard.deploys: off` in harness.config.yml turns this prompt off.")
        for group, pattern, label in DEPLOY_ASK:
            if GROUP_ASK[group] and re.search(pattern, line) and not dry_run(words):
                ask(f"`{label}` changes a shared remote environment or registry; only the owner approves it (the Shared remote environments golden rule in AGENTS.md). "
                    f"`guard.{group}: off` in harness.config.yml turns this prompt off.")
        check_cli(runner_words(words))
        check_migrate(runner_words(words))

    if BARE_ENV:
        deny(f"`{BARE_ENV[0]}` here prints every environment variable, secrets included (as a bare `env` or `printenv` does). "
             "Name the variable you need (`printenv NAME`).")

# ---- dispatch ------------------------------------------------------------------------------------
# An MCP tool passes when a word of its name is a read verb and none is a write verb
# (`list_deployments`, `pull_request_read`); anything else asks (`execute_sql`, `d1_database_query`).
READ_VERBS = {"get", "list", "search", "read", "fetch", "find", "view", "show", "describe", "check",
              "count", "aggregate", "lookup", "whoami", "docs", "doc", "help", "status", "logs",
              "inspect", "preview", "diff", "browse", "ping", "explain", "observe", "learn", "guide"}
WRITE_VERBS = {"create", "update", "delete", "remove", "write", "set", "put", "patch", "post", "send",
               "deploy", "apply", "execute", "exec", "run", "merge", "push", "upload", "add", "insert",
               "edit", "cancel", "pause", "resume", "restore", "rollback", "publish", "transfer", "buy",
               "revoke", "rename", "move", "assign", "invite", "submit", "trigger", "reset", "enable",
               "disable", "approve", "reply", "comment", "start", "stop", "kill", "rerun", "fork",
               "import", "connect", "disconnect", "activate", "accept", "drop", "truncate", "grant",
               "register", "archive", "unarchive", "promote", "resolve", "unresolve", "react"}
# Verbs that make a connector tool a write even next to a read verb (`get_and_destroy_resource`). MCP only: in a CLI
# call these words are often values (`helm list --filter flush`).
MCP_WRITE_EXTRA = {"destroy", "purge", "terminate", "scale", "flush", "overwrite", "wipe", "evict", "clone", "teardown",
                   "restart", "reboot", "provision", "deprovision", "detach"}

# The pull request tools of the GitHub connector that never merge or change files; the kit own process
# opens a draft PR at the first push and marks it ready after QA, so these do not need the owner each time.
PR_TOOLS = {"create_pull_request", "update_pull_request", "add_issue_comment", "update_issue_comment",
            "add_reply_to_pull_request_comment", "add_comment_to_pending_review"}

def own_repo(a):
    """True when the call names this project own repository (origin), so a PR tool never reaches another repo."""
    try:
        url = subprocess.run(["git", "remote", "get-url", "origin"], capture_output=True, text=True, timeout=5).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return False
    m = re.search(r"[:/]([^/:]+)/([^/]+?)(\.git)?/?$", url)
    return bool(m) and str(a.get("owner", "")).lower() == m.group(1).lower() and str(a.get("repo", "")).lower() == m.group(2).lower()

if tool == "Bash":
    HELD_ASK.append(None)
    check_bash(str(args.get("command", "")))
    held = HELD_ASK.pop()
    if held:
        ask(held)
elif tool in ("Read", "Edit", "MultiEdit", "Write", "NotebookEdit"):
    p = args.get("file_path") or args.get("notebook_path") or ""
    if tool != "Read" and protected_kind(p):
        protect(p, f"{tool} writes it", planned_text(tool, args, p))
    kind = secret_kind(p, tool == "Read")
    if kind == "deny":
        deny(f"`{p}` is a secret or credential file; agents never read or write it (AGENTS.md § Golden rules).")
    if kind == "ask":
        ask(f"`{p}` often holds registry tokens; the owner approves a read or change of it.")
    if kind == "home":
        ask(f"`{p}` is under ~/.claude: Claude Code settings, permissions and other projects\u2019 transcripts; the owner approves a read or change of it.")
    if tool != "Read" and p and outside_repo(p) and not rel_inside(p):
        ask(f"`{p}` is outside this project, and {tool} would write it; the owner approves a write anywhere but the repo and /tmp.")
elif tool == "WebFetch":
    # .claude/settings.json allows WebFetch on the whole api.github.com and raw.githubusercontent.com domains for the
    # update checks; anything on those hosts outside the two Morphness paths asks. Browsers and URL parsers read
    # `https:/\api.github.com`, `https:api.github.com` or a trailing dot as that host too, so any URL naming one asks
    # unless it is a plain Morphness path. Other domains get Claude Code\u2019s own prompt.
    url = str(args.get("url") or "").strip()
    low = url.lower()
    if re.search(r"api\.github\.com|raw\.githubusercontent\.com", low) and not (
            low.startswith(MORPHNESS_URLS) and not re.search(r"[\\@\s]|\.\.|%2e|%5c|%2f", low)):
        ask(f"WebFetch of `{url}`: .claude/settings.json allows only the Morphness update paths on GitHub without a prompt; "
            "the owner approves any other page there.")
elif tool == "Grep":
    for key in ("path", "glob"):
        v = str(args.get(key) or "")
        if v and env_in_word(v) == "deny":
            deny(f"`{v}` names a secret or credential file; agents never read it.")
        if v and env_in_word(v, True) == "home":
            ask(f"`{v}` is under ~/.claude: Claude Code settings, permissions and other projects\u2019 transcripts; the owner approves a read or change of it.")
    check_grep_tree(str(args.get("path") or "."), str(args.get("glob") or ""), str(args.get("type") or ""))
elif tool.startswith("mcp__") and MCP_ASK:
    short = tool.split("__", 2)[-1]
    if PR_ALLOW and tool.startswith("mcp__github__") and short in PR_TOOLS and own_repo(args) \
            and not (short == "update_pull_request" and str(args.get("state", "")).lower() == "closed"):
        sys.exit(0)
    words = {w.lower() for w in re.split(r"[_\-.]|(?<=[a-z])(?=[A-Z])", short) if w}
    if words & (WRITE_VERBS | MCP_WRITE_EXTRA) or not words & READ_VERBS:
        ask(f"`{tool}` can change something outside this repo; every connector write needs the owner’s yes "
            "(harness/SKILLS_AND_MCPS.md § Connector actions).")
sys.exit(0)
GUARD_PY
