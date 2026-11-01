#!/usr/bin/env bash
# Validate Morphness lesson files. Usage: scripts/check-lessons.sh [--since <git-ref>] [file ...]
#   (default: every lessons/**/*.md)
# Risky prose anywhere in a lesson (a URL or host, a network or remote-shell command, a command that installs
# or runs text, an environment dump, the guard, settings, harness config or permissions, secrets) fails for the files named
# on the command line and, with --since, for lessons added or changed since <git-ref>, unless the
# frontmatter says `reviewed: <why it is safe>`: a maintainer reads those before merging (a changed file needs a
# new reason).
# Optional: DENY="word1|word2" adds project-specific terms that must not appear (used by /morph-share).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -I - "$ROOT" "$@" <<'PY'
import os, re, subprocess, sys, glob
root, files = sys.argv[1], sys.argv[2:]
since = None
if files[:1] == ["--since"]:
    if len(files) < 2:
        print("usage: scripts/check-lessons.sh [--since <git-ref>] [file ...]"); sys.exit(2)
    since, files = files[1], files[2:]
strict = {os.path.abspath(f) for f in files}   # named files: drafts and contributions
if not files:
    files = [f for f in glob.glob(os.path.join(root, "lessons", "**", "*.md"), recursive=True)
             if os.path.basename(f) != "README.md"]
if since:
    def git(*a):
        return subprocess.run(["git", "-C", root, *a], check=True, capture_output=True, text=True).stdout.split()
    strict |= {os.path.join(root, p) for p in git("diff", "--name-only", "--no-renames", "--diff-filter=AM", since, "--", "lessons")
               + git("ls-files", "--others", "--exclude-standard", "--", "lessons")}
# Prose an agent would follow or paste that could open a hole: shell that reaches the network, installs or
# runs fetched text, an env dump, a URL or host, or anything that touches the guard, the settings, the
# harness config or secrets. A maintainer reads each flagged file before merging; `reviewed: <why>` in the
# frontmatter records that, and a later change to the text needs a new reason.
RISKY = [
    ("a URL or host", re.compile(r"\bhttps?://|\bwww\.|\b(?:[a-z0-9-]+\.)+(?:com|net|org|io|dev|app|co|ai|cloud|xyz|site|example|internal|local)/\S"
                                 r"|\b\d{1,3}(?:\.\d{1,3}){3}\b", re.I)),
    ("a network or remote-shell command", re.compile(r"\b(curl|wget|nc|ncat|netcat|socat|ssh|scp|sftp|telnet|ftp|openssl\s+s_client|dig|nslookup)\b(?!-)"
                                                     r"|\bInvoke-(WebRequest|RestMethod)\b|\biwr\b|\bgit\s+(push|remote)\b|\bfetch\(", re.I)),
    ("a command that installs or runs text", re.compile(r"\|\s*(ba|z|da)?sh\b|\b(ba|z|da)?sh\s+-c\b|(?<!unsafe-)\beval\b|\bsource\s+<\(|\bbase64\s+(-d|--decode)\b"
                                                        r"|\b(python3?|node|perl|ruby)\s+-[cep]\b|\b(npx|bunx|dlx)\b|\b(npm|pnpm|yarn|bun|pip3?|pipx|gem|cargo|go)\s+(i|install|add|get)\b"
                                                        r"|--no-verify\b", re.I)),
    ("an environment dump", re.compile(r"(?<![.\w-])(printenv|env)\b(?=\s*($|[|>;&`)]))|\bexport\s+-p\b|\bdeclare\s+-x\b|\bset\s*\||/proc/\S*environ", re.I | re.M)),
    ("the guard, settings, harness config or permissions", re.compile(
        r"\bguard(\.sh|\.[a-z_]+)?\b|settings(\.local)?\.json|\.claude/|harness\.config\.yml|\binstalled_from\b|\bpermissions?\b|\bdefaultMode\b"
        r"|\bbypassPermissions\b|--dangerously|\ballow(ed)?Tools\b|\bdeny\b|\bdisable\w*\s+(the\s+)?(hook|guard|check)"
        r"|\b(network|installs|deploys|publishes|mcp_writes|pr_writes|schema_pushes|source)\s*:\s*(off|allow|local)\b", re.I)),
    ("secrets or tokens", re.compile(r"(?<![\w-])\.env\b|\bsecrets?\b|\b(access|auth|api|bearer|refresh|github|gh|npm|deploy)[_ -]?tokens?\b"
                                     r"|\bapi[_ -]?keys?\b|\bcredentials?\b|\bpasswords?\b", re.I)),
]

def risky(text):
    """[(what, the matched text)] for each kind of risky prose in `text`, first match of each."""
    out = []
    for what, rx in RISKY:
        m = rx.search(text)
        if m:
            out.append((what, m.group(0).strip()))
    return out
reviewed_old = 0
kinds = {"checklist-item", "rule", "testing-rule", "module-rule", "agent-rule"}
targets_ok = lambda t: os.path.isfile(os.path.join(root, "template", t))
secretish = re.compile(r"(sk_live_|sk_test_|ghp_[A-Za-z0-9]{20}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|eyJhbGciOi|xox[bp]-)")
# DENY is a |-separated list of names, matched as whole words, not a regex (`acme.io`, `c++`, a short name)
deny_terms = [t.strip() for t in os.environ.get("DENY", "").split("|") if t.strip()]
deny_re = re.compile(r"(?<!\w)(" + "|".join(re.escape(t) for t in deny_terms) + r")(?!\w)", re.I) if deny_terms else None
ids, errors = {}, []
for f in sorted(files):
    rel = os.path.relpath(f, root)
    text = open(f, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        errors.append(f"{rel}: missing frontmatter"); continue
    fm, body = m.group(1), m.group(2)
    def field(k):
        mm = re.search(rf"^{k}:\s*(.*)$", fm, re.M)
        return mm.group(1).strip().strip('"') if mm else None
    for k in ("id", "title", "kind", "target", "tags", "evidence", "added"):
        if field(k) is None: errors.append(f"{rel}: missing '{k}'")
    i = field("id")
    if i:
        if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", i): errors.append(f"{rel}: id '{i}' is not kebab-case")
        if os.path.splitext(os.path.basename(f))[0] != i: errors.append(f"{rel}: file name must be '{i}.md'")
        if i in ids: errors.append(f"{rel}: duplicate id '{i}' (also {ids[i]})")
        ids[i] = rel
    k = field("kind")
    if k and k not in kinds: errors.append(f"{rel}: unknown kind '{k}'")
    t = field("target")
    t = t and re.sub(r"\s+#.*$", "", t).strip('"')
    if t and not targets_ok(t): errors.append(f"{rel}: target '{t}' not found in template/")
    a = field("added")
    if a and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", a): errors.append(f"{rel}: added must be YYYY-MM-DD")
    for h in ("## Rule", "## Why"):
        if h not in body: errors.append(f"{rel}: missing '{h}' section")
    if secretish.search(text): errors.append(f"{rel}: looks like it contains a secret")
    rv = field("reviewed")
    if rv is not None and not rv.strip():
        errors.append(f"{rel}: 'reviewed' is empty: say why the flagged text is safe, or remove the key")
    flags = risky(body)   # the whole body: agents read every section, and a heading can be renamed
    if flags and os.path.abspath(f) in strict:
        before = None
        if since and os.path.abspath(f).startswith(root + os.sep):
            r = subprocess.run(["git", "-C", root, "show", f"{since}:{rel}"], capture_output=True, text=True)
            mm = re.search(r"^reviewed:\s*(.*)$", r.stdout, re.M) if r.returncode == 0 else None
            before = mm.group(1).strip().strip('"') if mm else None
        if not (rv or "").strip():
            for what, hit in flags:
                errors.append(f"{rel}: has {what} (`{hit}`). Agents paste or run lesson text, so a maintainer "
                              "reads it before merging: rewrite it without that, or add `reviewed: <why it is safe>` to the frontmatter")
        elif before is not None and before == rv.strip():
            errors.append(f"{rel}: changed since {since} but keeps the same `reviewed:` reason; a maintainer re-reads the "
                          f"flagged text ({', '.join(w for w, _ in flags)}) and writes a new one")
        elif since:
            print(f"::warning file={rel}::reviewed ({rv.strip()}): " + "; ".join(f"{w}: {h}" for w, h in flags))
    elif flags and not rv:
        reviewed_old += 1
    if deny_re and deny_re.search(text): errors.append(f"{rel}: contains a denied term ({deny_re.search(text).group(0)})")
for f in sorted(files):
    m = re.search(r"^superseded_by:\s*(\S+)", open(f, encoding="utf-8").read(), re.M)
    if m and m.group(1) not in ids:
        errors.append(f"{os.path.relpath(f, root)}: superseded_by '{m.group(1)}' is not a lesson id")
titles = {}
for f in sorted(files):
    m = re.search(r"^title:\s*(.*)$", open(f, encoding="utf-8").read(), re.M)
    if m:
        key = re.sub(r"[^a-z0-9]+", " ", m.group(1).lower()).strip()
        if key in titles: errors.append(f"{os.path.relpath(f, root)}: same title as {titles[key]}; amend that lesson instead")
        titles[key] = os.path.relpath(f, root)
for e in errors: print(e)
if reviewed_old:
    print(f"note: {reviewed_old} older lesson(s) have risky prose and no 'reviewed' key (checked only when added or changed)")
print(f"{len(files)} lesson file(s) checked, {len(errors)} problem(s)")
sys.exit(1 if errors else 0)
PY
