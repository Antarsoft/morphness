#!/usr/bin/env bash
# PreToolUse hook (.claude/settings.json → hooks): checks each tool call before it runs. The deny
# and ask rules in .claude/settings.json stay as a second layer; this script catches what text
# patterns miss, because it reads a Bash command the way the shell does (every command in a chain,
# inside `$(…)`, `bash -c '…'`, `eval`, after `env`, `sudo` or `git -C <dir>`).
#
# What it denies (exit 2, the reason goes back to the agent), what it asks (the owner answers a
# permission prompt), which `guard:` switches in harness.config.yml turn an ask off, and what it does not
# see are described once, in AGENTS.md § Permissions for this project. This file is the implementation of
# that list: change the two together, and add a case to tests/guard-cases.jsonl for each rule.
# The hook fails closed: without python3, without the config reader (scripts/lib/config.sh), when the
# project folder can't be entered, on input it can't parse and on an internal error, it exits 2
# with the reason, so a broken guard blocks the call instead of passing it. `guard: { fail_open: true }`
# in harness.config.yml lets calls through when python3 is missing (the owner's choice for a machine
# that can't have it); /morph-doctor reports the gap either way.
#
# Input: the hook's JSON on stdin. Test by hand:
#   echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | bash scripts/guard.sh

guard_closed() {
  echo "Blocked by scripts/guard.sh: $1 The guard fails closed. Fix that, then retry (/morph-doctor lists what is missing)." >&2
  exit 2
}

. "$(cd "$(dirname "$0")" && pwd)/lib/config.sh" 2>/dev/null || guard_closed "scripts/lib/config.sh is missing or unreadable, so harness.config.yml can't be read."
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" 2>/dev/null || guard_closed "the project folder can't be entered."
if ! command -v python3 >/dev/null 2>&1; then
  case "$(config_get guard.fail_open | tr 'A-Z' 'a-z')" in
    true|yes|on) echo "scripts/guard.sh: python3 is missing and guard.fail_open is set, so this call is not checked." >&2; exit 0 ;;
  esac
  guard_closed "python3 is not installed, so the call can't be checked. Install python3, or set guard.fail_open: true in harness.config.yml to accept unchecked calls."
fi

GUARD_BRANCHES="$(
  {
    config_get branches.integration
    config_get branches.production
    config_env_branches
  } | tr -d "\"'" | grep . | sort -u | tr '\n' ' '
)"
GUARD_MCP_WRITES="$(config_get guard.mcp_writes)"
GUARD_DEPLOYS="$(config_get guard.deploys)"
GUARD_PUBLISHES="$(config_get guard.publishes)"
GUARD_SCHEMA_PUSHES="$(config_get guard.schema_pushes)"
GUARD_NETWORK="$(config_get guard.network)"
GUARD_INSTALLS="$(config_get guard.installs)"
GUARD_PR_WRITES="$(config_get guard.pr_writes)"
GUARD_ALLOW_HOSTS="$(config_get guard.allow_hosts)"
export GUARD_BRANCHES GUARD_MCP_WRITES GUARD_DEPLOYS GUARD_PUBLISHES GUARD_SCHEMA_PUSHES GUARD_NETWORK GUARD_INSTALLS GUARD_PR_WRITES GUARD_ALLOW_HOSTS

python3 -I -c '
import fnmatch, json, os, re, shlex, subprocess, sys, tempfile

PROTECTED = set(os.environ.get("GUARD_BRANCHES", "").split())
PROTECTED_LOW = {b.lower() for b in PROTECTED}
def protected_branch(name):
    # Branch names are case sensitive on the code host but not on every remote or file system, so `Main` counts as `main`.
    return str(name).lower() in PROTECTED_LOW
def switch(name):
    return os.environ.get(name, "ask").strip().lower() not in ("off", "false", "no")

MCP_ASK = switch("GUARD_MCP_WRITES")
# `pr_writes: allow` (the default, also when the key is missing) lets a pull request be opened, updated and commented on
# in this project own repo without a prompt; `ask` brings the prompt back for those tools.
PR_ALLOW = os.environ.get("GUARD_PR_WRITES", "allow").strip().lower() not in ("ask", "no", "false")
GROUP_ASK = {"deploys": switch("GUARD_DEPLOYS"), "publishes": switch("GUARD_PUBLISHES"),
             "schema_pushes": switch("GUARD_SCHEMA_PUSHES"), "network": switch("GUARD_NETWORK"),
             "installs": switch("GUARD_INSTALLS")}
ALLOW_HOSTS = {"localhost", "127.0.0.1", "::1"} | set(re.split(r"[\s,]+", os.environ.get("GUARD_ALLOW_HOSTS", "").lower()))

def deny(reason):
    sys.stderr.write("Blocked by scripts/guard.sh: " + reason + "\n")
    sys.exit(2)

def ask(reason):
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

# ---- the guard own files -------------------------------------------------------------------------
# A write here switches the guard off for every later call, so these ask (the owner reads the change);
# settings.local.json is the owner alone and is denied.
GUARD_FILES = ["scripts/guard.sh", "scripts/session-start.sh", "scripts/lib/*", ".claude/settings.json",
               "harness.config.yml", ".git/hooks/*", ".git/config"]
OWNER_FILES = [".claude/settings.local.json"]
# CI definitions run with the repository\u2019s secrets, so a change to one asks (the `deploys` switch turns it off).
CI_FILES = [".github/workflows/*", ".github/actions/*", ".gitlab-ci.yml"]
ROOT = os.getcwd()
CD_DIRS = []   # directories a `cd` in the same command moves to; a relative path is also tried under each

def rels_to_root(word):
    """Where a path word points, relative to the project root, once per directory a `cd` could set."""
    w = str(word).strip("\"\x27")
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
    """"owner" for settings.local.json, "guard" for the guard files, "persist" for shell startup files and
    schedules, "ci" for CI definitions, "" for anything else."""
    for part in re.split(r"[=:<>|,;()]", str(word)):
        if part and home_kind(part) == "persist":
            return "persist"
        globbed = any(c in part for c in "*?[")
        for rel in rels_to_root(part) if part else ():
            for kind, names in (("owner", OWNER_FILES), ("guard", GUARD_FILES), ("ci", CI_FILES if GROUP_ASK["deploys"] else [])):
                for name in names:
                    if fnmatch.fnmatch(rel, name) or (globbed and fnmatch.fnmatch(name.replace("/*", "/x"), rel)):
                        return kind
    return ""

def protect(path, how):
    kind = protected_kind(path)
    if kind == "owner":
        deny(f"`{path}` is the owner\u2019s file ({how}); an agent never writes settings.local.json.")
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
SECRET_NAMES = {".envrc", ".netrc", "_netrc", ".pgpass", ".git-credentials", ".my.cnf", ".htpasswd"}
ASK_NAMES = {".npmrc", ".pypirc"}
SECRET_SUFFIX = (".pem", ".key", ".p12", ".pfx", ".jks", ".keystore", ".ppk", ".tfstate")
SECRET_RE = re.compile(r"^(id_(rsa|dsa|ecdsa|ed25519)(_[a-z0-9_]+)?"
                       r"|(credentials?|client_secrets?|service[-_]account[-_a-z0-9]*|[a-z0-9_-]+[-_]credentials?)\.(json|ya?ml|toml|ini|xml|csv|txt)"
                       r"|(secrets?|[a-z0-9_-]+[-_.]secrets?)\.(json|ya?ml|toml|env|ini|txt|properties|cfg|conf)"
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
    return file_secret_kind(path) or ("home" if home_kind(path) == "home" else "")

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
        if (c == ".config" and nxt in ("gcloud", "gh", "doctl")) or (c == ".docker" and low == "config.json"):
            return "deny"
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

def expand(words, depth):
    first = os.path.basename(words[0]) if words else ""
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
    if not words:
        if first == "env":
            BARE_ENV.append(first)
        return
    name = os.path.basename(words[0])
    if name == "printenv" and len(words) == 1:
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
GIT_OPTS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}
PUSH_OPTS_WITH_VALUE = {"--repo", "--receive-pack", "--exec", "-o", "--push-option", "--signed", "--recurse-submodules"}

# State a command chain leaves behind for the next git command: where HEAD points after a checkout,
# switch or symbolic-ref (None = the real HEAD), remote.*.push values set by `git config`, new tags.
SIM = {"head": None, "push": [], "tags": set()}
HEAD_SUBST = re.compile(r"(\$\(|`)\s*git\s+(branch\s+--show-current|rev-parse\s+--abbrev-ref\s+HEAD|symbolic-ref\s+(--short\s+)?(-q\s+)?HEAD)\s*(\)|`)")

def git_out(git_dir_args, *args):
    try:
        r = subprocess.run(["git"] + git_dir_args + list(args), capture_output=True, text=True, timeout=5)
        return r.stdout.strip() if r.returncode == 0 else ""
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
    elif sub == "tag":
        if positional and not any(f in ("-d", "--delete", "-l", "--list") for f in flags):
            SIM["tags"].add(positional[0])
    elif sub == "reset" and "--hard" in flags:
        ask("`git reset --hard` throws away uncommitted work and moves the branch; the owner approves it. Commit or stash first, or reset with `--soft`/`--mixed`.")
    elif sub == "clean" and ("--force" in flags or "f" in short) and "--dry-run" not in flags and "n" not in short:
        ask("`git clean -f` deletes untracked files, ignored ones too with `-x`, and nothing brings them back; the owner approves it. Run `git clean -n` to see what it would delete.")
    elif sub == "branch":
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
        if opt in GIT_OPTS_WITH_VALUE and i + 1 < len(words):
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
          "issue": {"delete", "transfer"}, "extension": {"install", "upgrade", "exec"}, "alias": {"set", "import"}}

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

def check_curl(words):
    # .claude/settings.json allows `curl -fsSL <Morphness URL>/*`, and that pattern accepts any
    # trailing words. Stdout, GET, no body, no headers, no config file, one of the two prefixes.
    line = " ".join(words[1:]).lower()
    if not any(u[len("https://"):] in line for u in MORPHNESS_URLS):
        return
    for w in words[1:]:
        if "://" in w:
            if not w.startswith(MORPHNESS_URLS) or ".." in w or "%2e" in w.lower():
                ask(f"`curl` with `{w}`: the allowed read is only the two Morphness GitHub prefixes, "
                    "no `..` in the path, and nothing else on the line.")
        elif not CURL_READ_FLAG.match(w):
            ask(f"`curl {w}` is more than a read of the Morphness repository: update checks print to "
                "the terminal only (no file, method, body, header or config). Use `gh api --method GET` "
                "or the plain `curl -fsSL <url>`.")

WRITERS = {"cp", "mv", "rm", "ln", "install", "tee", "truncate", "chmod", "chown", "chattr", "dd", "rsync",
           "patch", "ed", "ex", "vi", "vim", "nano", "touch", "unlink", "shred"}
INTERPRETERS = {"python", "python3", "node", "ruby", "perl", "php", "deno", "bun"}

def guard_file_write(cmd, words):
    """Ask or deny when a Bash command writes one of the protected files."""
    name = words[0]
    named = [w for w in words[1:] if protected_kind(w)]
    if not named:
        return
    sub = words[1] if len(words) > 1 else ""
    writes = (name in WRITERS
              or (name in ("sed", "perl", "ruby") and any(re.match(r"^-[A-Za-z]*i", w) or w.startswith("--in-place") for w in words[1:]))
              or (name in INTERPRETERS and any(w in ("-c", "-e", "-p", "-pe", "-pi") or w.startswith("-i") for w in words[1:]))
              or (name == "git" and sub in ("update-index", "checkout", "restore", "rm", "mv", "apply", "stash", "reset"))
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

def hosts_in(words):
    from urllib.parse import urlparse
    hosts = []
    for k, w in enumerate(words):
        if "://" in w:
            try:
                hosts.append((urlparse(w.strip("\"\x27")).hostname or "").lower())
            except ValueError:
                hosts.append("?")
        elif w in ("-h", "-H", "--host", "--hostname") and k + 1 < len(words):
            hosts.append(words[k + 1].lower())
        elif re.match(r"^--host(name)?=", w):
            hosts.append(w.split("=", 1)[1].lower())
        elif re.match(r"^-[hH]\S", w):
            hosts.append(w[2:].lower())
    return hosts

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

def secret_in_tree(path, limit=20000):
    """The first secret or credential file below a directory (skipping dependency and build folders), else None."""
    seen = 0
    for top, dirs, names in os.walk(path):
        dirs[:] = [d for d in dirs if d not in SCAN_SKIP]
        for n in names + dirs:
            seen += 1
            if seen > limit:
                return None
            full = os.path.join(top, n)
            if file_secret_kind(full) == "deny" or (n in SECRET_DIRS and os.path.isdir(full)):
                return full
    return None

def check_tree_search(words):
    """A recursive grep (or `rg --hidden`) over a tree that holds a secret file reads it; deny unless the secret names are excluded."""
    name, rest = words[0], words[1:]
    flags = [w for w in rest if w.startswith("-")]
    if name in ("grep", "egrep", "fgrep", "zgrep"):
        recursive = any(w in ("--recursive", "--dereference-recursive") or re.match(r"^-[A-Za-z]*[rR][A-Za-z]*$", w) for w in flags)
    elif name == "rg":
        recursive = any(w in ("--hidden", "-.", "--no-ignore", "--no-ignore-vcs") or re.match(r"^-u{2,}$", w) for w in flags)
    else:
        return
    excludes = [w.split("=", 1)[1] if "=" in w else "" for w in rest if re.match(r"^--(exclude(-dir)?|glob|iglob)=", w)]
    excludes += [rest[k + 1] for k, w in enumerate(rest[:-1]) if w in ("--exclude", "--exclude-dir", "--glob", "--iglob", "-g")]
    excludes += [w for w in rest if w.startswith("!")]
    if not recursive or any("env" in x for x in excludes):
        return
    ops = operands(rest)
    own_pattern = any(w in ("-e", "--regexp", "-f", "--file") or w.startswith(("--regexp=", "--file=")) for w in flags)
    paths = ops if own_pattern else ops[1:]
    for pth in paths or ["."]:
        full = os.path.normpath(os.path.join(ROOT, expand_home(pth)))
        if os.path.isdir(full) and rel_inside(pth):
            hit = secret_in_tree(full)
            if hit:
                deny(f"`{name}` over `{pth}` would read `{os.path.relpath(hit, ROOT)}`, a secret or credential file; agents never read it "
                     "(AGENTS.md \u00a7 Golden rules). Search `src/` (or the folder you mean), exclude it (`--exclude=.env*`) or use the Grep tool.")


def check_bash(cmd):
    # `$(git branch --show-current)` and its kin are the current branch: read them as HEAD.
    cmd = HEAD_SUBST.sub("HEAD", cmd)
    # Heredoc bodies are text (a commit message, a PR body), not commands: keep only their first line.
    cmd = re.sub(r"(<<-?\s*([\x27\"]?)(\w+)\2[^\n]*)\n.*?\n[ \t]*\3[ \t]*(?=\n|\)|$)", r"\1", cmd, flags=re.S)
    for words in simple_commands(cmd):
        if words[0] == "cd" and len(words) > 1:
            CD_DIRS.append(words[1].strip("\"\x27"))
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
        for w in words[1:]:
            skipped = bool(re.match(r"^--(exclude(-dir)?|glob|iglob|ignore)=", w)) or w.startswith("!") \
                or (words[0] in ("grep", "egrep", "fgrep", "zgrep", "rg", "ag", "ack") and prev in ("--exclude", "--exclude-dir", "--glob", "--iglob", "-g"))
            prev = w
            if skipped:
                continue   # an exclude pattern such as --exclude=.env* names a secret in order to leave it out
            if re.search(r"^/proc/[^/]+/environ$", w):
                deny("`/proc/<pid>/environ` is the whole environment, secrets included.")
            kind = env_in_word(w, words[0] in READ_ONLY_CMDS and not any(re.match(r"^(\d*>|&>)" if words[0] != "sed" else r"^(\d*>|&>|-i|--in-place)", x) for x in words[1:]))
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

    if BARE_ENV:
        deny("a bare `env` or `printenv` prints every variable, secrets included. Name the variable you need (`printenv NAME`).")

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
    check_bash(str(args.get("command", "")))
elif tool in ("Read", "Edit", "MultiEdit", "Write", "NotebookEdit"):
    p = args.get("file_path") or args.get("notebook_path") or ""
    if tool != "Read":
        protect(p, f"{tool} writes it")
    kind = secret_kind(p, tool == "Read")
    if kind == "deny":
        deny(f"`{p}` is a secret or credential file; agents never read or write it (AGENTS.md § Golden rules).")
    if kind == "ask":
        ask(f"`{p}` often holds registry tokens; the owner approves a read or change of it.")
    if kind == "home":
        ask(f"`{p}` is under ~/.claude: Claude Code settings, permissions and other projects\u2019 transcripts; the owner approves a read or change of it.")
    if tool != "Read" and p and outside_repo(p) and not rel_inside(p):
        ask(f"`{p}` is outside this project, and {tool} would write it; the owner approves a write anywhere but the repo and /tmp.")
elif tool == "Grep":
    for key in ("path", "glob"):
        v = str(args.get(key) or "")
        if v and env_in_word(v) == "deny":
            deny(f"`{v}` names a secret or credential file; agents never read it.")
        if v and env_in_word(v, True) == "home":
            ask(f"`{v}` is under ~/.claude: Claude Code settings, permissions and other projects\u2019 transcripts; the owner approves a read or change of it.")
elif tool.startswith("mcp__") and MCP_ASK:
    short = tool.split("__", 2)[-1]
    if PR_ALLOW and tool.startswith("mcp__github__") and short in PR_TOOLS and own_repo(args) \
            and not (short == "update_pull_request" and str(args.get("state", "")).lower() == "closed"):
        sys.exit(0)
    words = {w.lower() for w in re.split(r"[_\-.]|(?<=[a-z])(?=[A-Z])", short) if w}
    if words & WRITE_VERBS or not words & READ_VERBS:
        ask(f"`{tool}` can change something outside this repo; every connector write needs the owner’s yes "
            "(harness/SKILLS_AND_MCPS.md § Connector actions).")
sys.exit(0)
'
rc=$?
# 0 = pass or ask (JSON on stdout), 2 = deny. Anything else is a crash inside the hook: block, don't pass.
[ "$rc" -eq 0 ] || [ "$rc" -eq 2 ] || guard_closed "the guard script crashed (exit $rc), so the call can't be checked."
exit "$rc"
