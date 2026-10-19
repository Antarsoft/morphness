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
#   - writing `.claude/settings.local.json` (the owner writes that file; an agent that could write it
#     could grant itself permissions that never show in a PR)
# Asks (the owner answers a permission prompt):
#   - changing the files the guard itself rests on: scripts/guard.sh, scripts/session-start.sh,
#     scripts/lib/, .claude/settings.json and harness.config.yml, by an Edit/Write tool or a Bash
#     write (redirect, `sed -i`, `cp`, `mv`, `rm`, `chmod`, `tee`, `git restore`, an interpreter
#     one-liner naming the file). /morph-init, /morph-update and the retro change them on the owner's
#     yes, so the prompt shows the owner each change instead of blocking it.
#   - deploys, platform secrets and publishes from well-known CLIs, so nothing reaches a shared
#     environment or registry by accident. Three groups, each with its own switch (`guard.deploys`,
#     `guard.publishes`, `guard.schema_pushes`: ask or off):
#       deploys        `vercel` (anything but its read-only subcommands; `vercel env add|rm|update`),
#                      `wrangler deploy`, `wrangler secret put|delete|bulk`, `fly deploy`,
#                      `firebase deploy`, `netlify deploy`, `netlify env:set|unset|import`,
#                      `supabase functions deploy`, `terraform apply`, `kubectl apply`, `helm upgrade`
#       publishes      `npm|pnpm|yarn|bun … publish` (also with `--filter`/`--workspace`),
#                      `changeset publish`, `cargo publish`
#       schema_pushes  `prisma db push`, `drizzle-kit push`
#     A command with `--dry-run` (not `=none`) or `--help` passes; `terraform plan`, `kubectl get`,
#     `vercel ls` and the like are not listed at all.
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
# Secrets, force-pushes, .env files, environment-branch pushes and remote database writes (the Blocks
# above) have no switch.
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
GUARD_DEPLOYS="$(config_get guard.deploys)"
GUARD_PUBLISHES="$(config_get guard.publishes)"
GUARD_SCHEMA_PUSHES="$(config_get guard.schema_pushes)"
GUARD_NETWORK="$(config_get guard.network)"
GUARD_ALLOW_HOSTS="$(config_get guard.allow_hosts)"
export GUARD_BRANCHES GUARD_MCP_WRITES GUARD_DEPLOYS GUARD_PUBLISHES GUARD_SCHEMA_PUSHES GUARD_NETWORK GUARD_ALLOW_HOSTS

exec python3 -I -c '
import fnmatch, json, os, re, shlex, subprocess, sys

PROTECTED = set(os.environ.get("GUARD_BRANCHES", "").split())
def switch(name):
    return os.environ.get(name, "ask").strip().lower() not in ("off", "false", "no")

MCP_ASK = switch("GUARD_MCP_WRITES")
GROUP_ASK = {"deploys": switch("GUARD_DEPLOYS"), "publishes": switch("GUARD_PUBLISHES"),
             "schema_pushes": switch("GUARD_SCHEMA_PUSHES"), "network": switch("GUARD_NETWORK")}
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
    sys.exit(0)
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
               "harness.config.yml"]
OWNER_FILES = [".claude/settings.local.json"]
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

def protected_kind(word):
    """"owner" for settings.local.json, "guard" for the guard files, "" for anything else."""
    for part in re.split(r"[=:<>|,;()]", str(word)):
        globbed = any(c in part for c in "*?[")
        for rel in rels_to_root(part) if part else ():
            for kind, names in (("owner", OWNER_FILES), ("guard", GUARD_FILES)):
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

# ---- secret env files --------------------------------------------------------------------------
SAFE_ENV = {".env.example", ".env.sample", ".env.template"}
def is_secret_env(path):
    name = os.path.basename(str(path).rstrip("/").strip("\"\x27"))
    if name in SAFE_ENV or name.endswith((".example", ".sample", ".template")):
        return False
    return name == ".env" or name.startswith(".env.")

def env_in_word(word):
    # Covers plain paths, globs (.env*), redirections glued to a word and VAR=path forms.
    for part in re.split(r"[=:<>|,;()@]", word):
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

BARE_ENV = []   # set when a command would print the whole environment

def expand(words, depth):
    first = os.path.basename(words[0]) if words else ""
    while words and (words[0] in WRAPPERS or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0])
                     or (words[0].startswith("-") and len(words) > 1 and words[1] != "--")):
        words = words[1:]
    if not words:
        if first == "env":
            BARE_ENV.append(first)
        return
    name = os.path.basename(words[0])
    if name == "printenv" and len(words) == 1:
        BARE_ENV.append(name)
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
    ("schema_pushes", r"^drizzle-kit\b.*\b(push|migrate)\b", "drizzle-kit push"),
    ("deploys", r"^(terraform|tofu)\b.*\b(apply|destroy)\b", "terraform apply"),
    ("deploys", r"^kubectl\b.*\bapply\b", "kubectl apply"),
    ("deploys", r"^helm\b.*\b(upgrade|install)\b", "helm upgrade"),
    ("publishes", r"^cargo\b.*\bpublish\b", "cargo publish"),
    ("publishes", r"^changeset\b.*\bpublish\b", "changeset publish"),
]
# Matched on the command as typed, because the runner strip below removes a leading `npm`. Covers
# `pnpm --filter x publish`, `npm --workspace x publish` and `yarn npm publish`.
PUBLISH_ASK = re.compile(r"^(npm|pnpm|yarn|bun)\b.*\bpublish\b")
# vercel: only these subcommands read. A scoped one (`env`, `domains`, `dns`, …) reads only with `ls`
# and the like; `vercel env add|rm|update`, `vercel alias set`, `vercel deploy` and a bare `vercel` ask.
VERCEL_READ = {"ls", "list", "inspect", "logs", "whoami", "login", "logout", "help", "link", "pull",
               "build", "dev", "bisect", "version"}
VERCEL_SCOPED = {"env", "domains", "dns", "alias", "aliases", "project", "projects", "certs", "teams",
                 "team", "git", "integration", "webhooks", "rolling-release"}
VERCEL_SCOPED_READ = {"ls", "list", "inspect", "pull", "help"}

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

# ---- network and remote copies -------------------------------------------------------------------
CURL_BODY_LONG = ("--data", "--data-binary", "--data-raw", "--data-urlencode", "--data-ascii", "--form",
                  "--form-string", "--upload-file", "--json", "--post-data", "--post-file", "--body-data",
                  "--body-file")
REMOTE_COPY = {"scp", "sftp", "rsync", "nc", "ncat", "netcat", "socat", "telnet", "ftp"}
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
        ask(f"`{name}` copies files to or from another machine; only the owner approves it. "
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

def check_bash(cmd):
    # Heredoc bodies are text (a commit message, a PR body), not commands: keep only their first line.
    cmd = re.sub(r"(<<-?\s*([\x27\"]?)(\w+)\2[^\n]*)\n.*?\n[ \t]*\3[ \t]*(?=\n|\)|$)", r"\1", cmd, flags=re.S)
    for words in simple_commands(cmd):
        if words[0] == "cd" and len(words) > 1:
            CD_DIRS.append(words[1].strip("\"\x27"))
    # A redirect (`> f`, `>> f`, `>|f`, `tee`-less here-doc writes) onto a protected file.
    for m in re.finditer(r"[0-9&]?>>?\|?\s*([^\s;&|<>()]+)", cmd):
        protect(m.group(1), "a redirect writes it")
    for words in simple_commands(cmd):
        guard_file_write(cmd, words)
        for w in words[1:]:
            if re.search(r"^/proc/[^/]+/environ$", w):
                deny("`/proc/<pid>/environ` is the whole environment, secrets included.")
            if env_in_word(w):
                deny(f"`{w}` is a secret env file; agents never read or write it (AGENTS.md § Golden rules). Use .env.example for names.")
        line = " ".join(words)
        if GROUP_ASK["publishes"] and PUBLISH_ASK.search(line) and not dry_run(words):
            ask("`publish` releases a package to a shared registry; only the owner approves it (the Shared remote environments golden rule in AGENTS.md). "
                "`guard.publishes: off` in harness.config.yml turns this prompt off.")
        # `npx supabase …`, `pnpm exec prisma …`: match the tool the runner starts.
        line = re.sub(r"^(npx|bunx|pnpx|(pnpm|yarn|bun|npm)(\s+(exec|dlx|x))?)(\s+-\S+)*\s+(--\s+)?", "", line)
        check_network(words)
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

if tool == "Bash":
    check_bash(str(args.get("command", "")))
elif tool in ("Read", "Edit", "MultiEdit", "Write", "NotebookEdit"):
    p = args.get("file_path") or args.get("notebook_path") or ""
    if tool != "Read":
        protect(p, f"{tool} writes it")
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
