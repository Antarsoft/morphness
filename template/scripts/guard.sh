#!/usr/bin/env bash
# PreToolUse hook (.claude/settings.json → hooks): checks each tool call before it runs. The deny
# and ask rules in .claude/settings.json stay as a second layer; this script catches what text
# patterns miss, because it reads a Bash command the way the shell does (every command in a chain,
# inside `$(…)`, `bash -c '…'`, `eval`, after `env`, `sudo` or `git -C <dir>`).
#
# Blocks (exit 2, the reason goes back to the agent):
#   - a push that would update an environment branch (branches.* and every environments[].branch):
#     an explicit refspec, `HEAD` or a bare `git push` while on one, `--all`, `--mirror`, a delete
#   - a force push (`--force*`, `-f`, a `+` refspec), on any branch
#   - reading or writing a `.env` file (`.env`, `.env.local`, `.env.production`, …) with any tool;
#     `.env.example`, `.env.sample` and `.env.template` are fine
#   - writing secrets or variables on the code host (`gh secret set`, `gh variable set`, `gh api`
#     writes to …/secrets or …/variables)
#   - remote database writes from well-known CLIs (`supabase db push`, `prisma migrate deploy`,
#     `wrangler d1 … --remote`, …)
# Asks (the owner answers a permission prompt):
#   - deploys and publishes from well-known CLIs (`vercel`, `wrangler deploy`, `fly deploy`,
#     `firebase deploy`, `netlify deploy`, `supabase functions deploy`, `terraform apply`,
#     `kubectl apply`, `helm upgrade`, `npm publish`, `cargo publish`) and schema pushes
#     (`prisma db push`, `drizzle-kit push`), so nothing reaches a shared environment by accident
#   - `gh api` writes to git refs and merges (…/git/refs, …/merges, …/pulls/N/merge)
#   - `gh api` writes to rulesets, branch protection and repo settings (/morph-init and /morph-doctor
#     apply branch protection that way, on the owner's yes)
#   - a `curl` that names a Morphness GitHub address (the update checks' read fallback) and is
#     anything but a plain read: the allow rules in .claude/settings.json match any trailing flags,
#     so this hook checks the rest. Only `-f -s -S -L` and URLs under the two Morphness prefixes pass;
#     `-o`, `-O`, `-X`, `-d`, `-F`, `-T`, `-H`, `-K`, `-u`, a redirect to a file, another URL and
#     every other flag ask
#   - every MCP tool whose name doesn't start with a read verb (get, list, search, read, …), so each
#     connector write waits for the owner's yes (harness/SKILLS_AND_MCPS.md § Connector actions).
#     `guard.mcp_writes: off` in harness.config.yml turns this off; reads always pass.
# This stops accidents, not intent: it reads the command text, so a script that runs a deploy, an
# unlisted tool or a deliberately disguised call gets past it. The settings rules and the owner's
# review are the other layers.
# Everything else passes untouched. Without python3 the hook lets the call through (the settings
# rules still apply) and /morph-doctor reports it.
#
# Input: the hook's JSON on stdin. Test by hand:
#   echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | bash scripts/guard.sh

. "$(cd "$(dirname "$0")" && pwd)/lib/config.sh" 2>/dev/null || exit 0
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" 2>/dev/null || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

GUARD_BRANCHES="$(
  {
    config_get branches.integration
    config_get branches.production
    sed -n 's/.*[{,][ \t]*branch:[ \t]*\([^ \t,}]*\).*/\1/p' harness.config.yml 2>/dev/null
  } | tr -d "\"'" | grep . | sort -u | tr '\n' ' '
)"
GUARD_MCP_WRITES="$(config_get guard.mcp_writes)"
export GUARD_BRANCHES GUARD_MCP_WRITES

exec python3 -I -c '
import json, os, re, shlex, subprocess, sys

PROTECTED = set(os.environ.get("GUARD_BRANCHES", "").split())
MCP_ASK = os.environ.get("GUARD_MCP_WRITES", "ask").strip().lower() not in ("off", "false", "no")

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
    sys.exit(0)
tool = event.get("tool_name") or ""
args = event.get("tool_input") or {}

# ---- secret env files --------------------------------------------------------------------------
SAFE_ENV = {".env.example", ".env.sample", ".env.template"}
def is_secret_env(path):
    name = os.path.basename(str(path).rstrip("/").strip("\"\x27"))
    if name in SAFE_ENV or name.endswith((".example", ".sample", ".template")):
        return False
    return name == ".env" or name.startswith(".env.")

def env_in_word(word):
    # Covers plain paths, globs (.env*), redirections glued to a word and VAR=path forms.
    for part in re.split(r"[=:<>|,;()]", word):
        if part and (is_secret_env(part) or re.search(r"(^|/)\.env\*", part)):
            return True
    return False

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
    cur = []
    for t in tokens(cmd.replace("\n", " ; ")) + [";"]:
        if t in SEPARATORS or set(t) <= set(";&|()"):
            if cur:
                yield from expand(cur, depth)
            cur = []
        else:
            cur.append(t)

def expand(words, depth):
    while words and (words[0] in WRAPPERS or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0])
                     or (words[0].startswith("-") and len(words) > 1 and words[1] != "--")):
        words = words[1:]
    if not words:
        return
    name = os.path.basename(words[0])
    if name in SHELLS and "-c" in words[1:]:
        i = words.index("-c")
        if i + 1 < len(words):
            yield from simple_commands(words[i + 1], depth + 1)
        return
    if name == "eval":
        yield from simple_commands(" ".join(words[1:]), depth + 1)
        return
    yield [name] + words[1:]

# ---- git push --------------------------------------------------------------------------------
GIT_OPTS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}
PUSH_OPTS_WITH_VALUE = {"--repo", "--receive-pack", "--exec", "-o", "--push-option", "--signed", "--recurse-submodules"}

def current_branch(git_dir_args):
    try:
        return subprocess.run(["git"] + git_dir_args + ["symbolic-ref", "--short", "-q", "HEAD"],
                              capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ""

def branch_of(ref, here):
    ref = ref.strip()
    if ref in ("HEAD", "@"):
        return here
    for prefix in ("refs/heads/", "heads/"):
        if ref.startswith(prefix):
            return ref[len(prefix):]
    return ref

def check_git(words):
    i, git_dir_args = 1, []
    while i < len(words) and words[i].startswith("-"):
        opt = words[i]
        if opt in GIT_OPTS_WITH_VALUE and i + 1 < len(words):
            if opt == "-C":
                git_dir_args += ["-C", words[i + 1]]
            i += 2
        else:
            i += 1
    if i >= len(words) or words[i] != "push":
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
    if any(f in ("--all", "--mirror", "--branches") for f in flags):
        deny("`git push --all` / `--mirror` would update the environment branches. Push your feature branch by name.")
    here = current_branch(git_dir_args)
    deleting = "--delete" in flags or "d" in short
    refspecs = positional[1:]
    targets = []
    if not refspecs:
        targets.append(here)
    for spec in refspecs:
        spec = spec.lstrip("+")
        if ":" in spec:
            src, dst = spec.split(":", 1)
            targets.append(branch_of(dst, here) if dst else branch_of(src, here))
        else:
            targets.append(branch_of(spec, here))
    for t in targets:
        if t and t in PROTECTED:
            what = "delete" if deleting or any(s.startswith(":") for s in refspecs) else "push to"
            deny(f"agents never {what} `{t}`: it is an environment branch and moves only through a PR "
                 "(AGENTS.md § Golden rules). Push a feature branch and open a PR.")

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
DEPLOY_ASK = [
    (r"^vercel\b(?!\s+(-\S+\s+)*(ls|list|inspect|logs|whoami|login|logout|help|link|pull|build|dev|env|domains|teams|project|projects|certs|dns|alias|bisect|--version|-v|--help|-h)\b)", "vercel deploys to a shared environment"),
    (r"^wrangler\b.*\b(deploy|publish|rollback)\b", "wrangler deploy"),
    (r"^(fly|flyctl)\b.*\b(deploy|launch)\b", "fly deploy"),
    (r"^firebase\b.*\bdeploy\b", "firebase deploy"),
    (r"^(netlify|ntl)\b.*\bdeploy\b", "netlify deploy"),
    (r"^supabase\b.*\bfunctions\s+deploy\b", "supabase functions deploy"),
    (r"\bprisma\s+db\s+push\b", "prisma db push"),
    (r"^drizzle-kit\b.*\b(push|migrate)\b", "drizzle-kit push"),
    (r"^(terraform|tofu)\b.*\b(apply|destroy)\b", "terraform apply"),
    (r"^kubectl\b.*\bapply\b", "kubectl apply"),
    (r"^helm\b.*\b(upgrade|install)\b", "helm upgrade"),
    (r"^cargo\b.*\bpublish\b", "cargo publish"),
]
# Matched on the command as typed, because the runner strip below removes a leading `npm`.
PUBLISH_ASK = re.compile(r"^(npm|pnpm|yarn|bun)\s+(-\S+\s+)*(npm\s+)?publish\b")
GH_ASK_PATHS = re.compile(r"(/git/(refs|tags)|/merges|/pulls/[^/]+/merge|rulesets|/protection|/branches/[^/]+/protection|^/?repos/[^/]+/[^/]+/?$|collaborators|/hooks|/keys|/environments)")

def check_gh(words):
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
            default_method = "POST"
            if GH_ASK_PATHS.search(path):
                ask(f"`gh api {path}` ({method or default_method}) changes repository settings or protection; only the owner approves it.")
            # Upstream update checks only read Morphness; .claude/settings.json allows those reads.
            if re.search(r"^/?repos/[^/]+/morphness(/|$)", path):
                ask(f"`gh api {path}` ({method or default_method}) writes to the Morphness repository; update checks only read it.")

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

def check_bash(cmd):
    # Heredoc bodies are text (a commit message, a PR body), not commands: keep only their first line.
    cmd = re.sub(r"(<<-?\s*([\x27\"]?)(\w+)\2[^\n]*)\n.*?\n[ \t]*\3[ \t]*(?=\n|\)|$)", r"\1", cmd, flags=re.S)
    for words in simple_commands(cmd):
        for w in words[1:]:
            if env_in_word(w):
                deny(f"`{w}` is a secret env file; agents never read or write it (AGENTS.md § Golden rules). Use .env.example for names.")
        line = " ".join(words)
        if PUBLISH_ASK.search(line):
            ask("`npm publish` releases a package to a shared registry; only the owner approves it (the Shared remote environments golden rule in AGENTS.md).")
        # `npx supabase …`, `pnpm exec prisma …`: match the tool the runner starts.
        line = re.sub(r"^(npx|bunx|pnpx|(pnpm|yarn|bun|npm)(\s+(exec|dlx|x))?)(\s+-\S+)*\s+(--\s+)?", "", line)
        if words[0] == "git":
            check_git(words)
        elif words[0] == "gh":
            check_gh(words)
        elif words[0] == "curl":
            check_curl(words)
        for pattern, label in REMOTE_DB:
            if re.search(pattern, line):
                deny(f"{label} writes a remote database; that is the owner’s step (the Shared remote environments golden rule in AGENTS.md).")
        for pattern, label in DEPLOY_ASK:
            if re.search(pattern, line):
                ask(f"`{label}` changes a shared remote environment or registry; only the owner approves it (the Shared remote environments golden rule in AGENTS.md).")

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

if tool == "Bash":
    check_bash(str(args.get("command", "")))
elif tool in ("Read", "Edit", "MultiEdit", "Write", "NotebookEdit"):
    p = args.get("file_path") or args.get("notebook_path") or ""
    if is_secret_env(p):
        deny(f"`{p}` is a secret env file; agents never read or write it (AGENTS.md § Golden rules).")
elif tool == "Grep":
    for key in ("path", "glob"):
        v = str(args.get(key) or "")
        if v and env_in_word(v):
            deny(f"`{v}` names a secret env file; agents never read it.")
elif tool.startswith("mcp__") and MCP_ASK:
    short = tool.split("__", 2)[-1]
    words = {w.lower() for w in re.split(r"[_\-.]|(?<=[a-z])(?=[A-Z])", short) if w}
    if words & WRITE_VERBS or not words & READ_VERBS:
        ask(f"`{tool}` can change something outside this repo; every connector write needs the owner’s yes "
            "(harness/SKILLS_AND_MCPS.md § Connector actions).")
sys.exit(0)
'
