#!/usr/bin/env bash
# Public test results: runs the kit's own checks and a few well-known public tools, then writes the
# results page (docs/trust.html) and its data (docs/trust/results.json, raw logs in docs/trust/logs/).
# Nothing on the page is typed by hand: every row comes from a run of this script, with the tool
# version, the commit tested and the UTC time. Findings that need a verdict (warnings and errors,
# secrets, skill issues) are matched against tests/triage.jsonl; one without an entry is shown as
# "untriaged" and makes the script exit 1, so noise cannot be hidden by leaving it out. The limits
# block on the page comes from tests/known-gaps.md.
#
# Usage: scripts/trust-report.sh [--out DIR] [--allow-untriaged] [--skip-selftest]
#        scripts/trust-report.sh --render-only results.json [--out DIR]   (re-renders the page, runs nothing)
#   --out DIR  where docs/trust.html and docs/trust/ go (default: docs/ in the repo)
#   TRUST_FAKE_FAIL=agnix,gitleaks  makes those tools fail to start (tests that a crash is shown as "did not run")
# Needs bash, git, perl, python3 with pip, node with npx, uv and curl. Tools are installed into a temporary
# folder that is deleted at the end; versions are pinned below (bump them in their own PR).
# Run it on a clean checkout with tags (git fetch --tags), at the release being published.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -I - "$ROOT" "$@" <<'PY'
import datetime, fnmatch, hashlib, html, json, os, platform, re, shutil, subprocess, sys, tempfile, tarfile, urllib.request

root = sys.argv[1]
args = sys.argv[2:]

PINS = {
    "agnix": "0.59.0",
    "shellcheck-py": "0.11.0.1",
    "gitleaks": "8.28.0",
    "skillspector": "95a52d89fa16f608f0b18ccee76b0918ea4b7eef",   # NVIDIA/SkillSpector v2.12.0
}
URLS = {
    "agnix": "https://github.com/agent-sh/agnix",
    "shellcheck": "https://github.com/koalaman/shellcheck",
    "gitleaks": "https://github.com/gitleaks/gitleaks",
    "skillspector": "https://github.com/NVIDIA/SkillSpector",
}
SITE = "https://antarsoft.github.io/morphness/"
REPO = "https://github.com/antarsoft/morphness"

out_dir = os.path.join(root, "docs")
allow_untriaged = skip_selftest = False
render_only = None
i = 0
while i < len(args):
    a = args[i]
    if a == "--out": out_dir = os.path.abspath(args[i + 1]); i += 1
    elif a == "--allow-untriaged": allow_untriaged = True
    elif a == "--skip-selftest": skip_selftest = True
    elif a == "--render-only": render_only = args[i + 1]; i += 1
    else: sys.exit(f"unknown option {a}")
    i += 1
fake_fail = set(filter(None, os.environ.get("TRUST_FAKE_FAIL", "").split(",")))
html_path = os.path.join(out_dir, "trust.html")
data_dir = os.path.join(out_dir, "trust")
log_dir = os.path.join(data_dir, "logs")

def now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

def sh(cmd, cwd=root, env=None, check=False):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=env)
    if check and r.returncode:
        raise RuntimeError(f"{' '.join(cmd[:3])} failed: {(r.stderr or r.stdout).strip()[:300]}")
    return r

# ---------------------------------------------------------------------------------------------------------
# Rendering (also used by --render-only)
# ---------------------------------------------------------------------------------------------------------
E = html.escape

def verdict(row):
    """(css class, text) for one row."""
    s = row["status"]
    if s == "did-not-run":
        return "bad", "did not run: " + row.get("error", "")
    if row["group"] == "own":
        return ("ok", row["summary"]) if s == "pass" else ("bad", row["summary"])
    return {"clean": "ok", "triaged": "warn", "untriaged": "bad"}.get(s, "bad"), row["summary"]

def render_page(data):
    rows = data["rows"]
    problems = [r for r in rows if r["status"] in ("fail", "did-not-run", "untriaged")]
    limits = data.get("limits", [])
    def table(group):
        out = ['<div class="scroll"><table><thead><tr><th>Check</th><th>What it looks at</th><th>Result</th><th>Run</th></tr></thead><tbody>']
        for r in rows:
            if r["group"] != group: continue
            cls, text = verdict(r)
            tool = r["name"]
            if r.get("url"):
                tool = f'<a href="{E(r["url"])}">{E(r["name"])}</a>'
            ver = f' <span class="muted">{E(r["version"])}</span>' if r.get("version") else ""
            cell = f'<span class="pill {cls}">{E(text)}</span>'
            det = ""
            if r.get("findings"):
                items = []
                for f in r["findings"]:
                    t = f.get("triage")
                    tag = (f'<b>{E(t["status"])}</b>: {E(t["reason"])}' if t else '<b class="untriaged">untriaged</b>')
                    loc = E(f["path"] + (f":{f['line']}" if f.get("line") else ""))
                    items.append(f'<li><code>{E(f["rule"])}</code> {loc}<br><span class="muted">{E(f["message"][:200])}</span><br>{tag}</li>')
                det = f'<details><summary>{len(items)} finding(s) and how each was judged</summary><ul>{"".join(items)}</ul></details>'
            if r.get("notes"):
                det += f'<p class="muted small">{E(r["notes"])}</p>'
            logs = " · ".join(f'<a href="trust/logs/{E(l)}">{E(l)}</a>' for l in r.get("logs", []))
            if logs: det += f'<p class="small">Raw output: {logs}</p>'
            out.append(f'<tr><td data-l="Check"><b>{tool}</b>{ver}</td><td data-l="Looks at">{E(r["what"])}<br><code>{E(r["command"])}</code></td>'
                       f'<td data-l="Result">{cell}{det}</td><td data-l="Run" class="nowrap">{E(r["finished"])}</td></tr>')
        out.append("</tbody></table></div>")
        return "\n".join(out)
    dirty = ' <span class="pill warn">working tree had uncommitted changes</span>' if data.get("dirty") else ""
    state = ('<p class="banner bad">This run has problems: ' + E(", ".join(r["name"] for r in problems)) + ".</p>") if problems else \
            '<p class="banner ok">Every check in this run finished and no finding is left without a verdict.</p>'
    lim = "\n".join(f"<li>{E(l)}</li>" for l in limits)
    short = data["commit"][:7]
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Test results · Morphness</title>
<meta name="description" content="What Morphness is tested with, the exact results, the date and the commit tested, and the known limits. Generated by a script from a real run.">
<link rel="canonical" href="{SITE}trust.html">
<link rel="icon" href="logo.svg" type="image/svg+xml">
<meta name="color-scheme" content="light dark">
<style>
  :root {{ --bg:#fff; --fg:#1f1d2b; --muted:#5b5870; --accent:#7C3AED; --border:#e6e3ef; --surface:#f7f5fb; --ok:#166534; --okbg:#dcfce7; --warn:#854d0e; --warnbg:#fef3c7; --bad:#991b1b; --badbg:#fee2e2; }}
  @media (prefers-color-scheme: dark) {{ :root {{ --bg:#0f0d17; --fg:#ece9f5; --muted:#a6a2b8; --accent:#a78bfa; --border:#2a2638; --surface:#1a1524; --ok:#86efac; --okbg:#14532d; --warn:#fde68a; --warnbg:#422006; --bad:#fca5a5; --badbg:#450a0a; }} }}
  * {{ box-sizing: border-box; }}
  body {{ margin:0; background:var(--bg); color:var(--fg); font:16px/1.65 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif; }}
  main {{ max-width:1040px; margin:0 auto; padding:40px 16px 64px; }}
  a {{ color:var(--accent); }}
  h1 {{ font-size:2rem; line-height:1.2; margin:0 0 8px; }}
  h2 {{ font-size:1.25rem; margin:36px 0 8px; }}
  code {{ font:0.85em ui-monospace,SFMono-Regular,Menlo,Consolas,monospace; background:var(--surface); padding:1px 5px; border-radius:5px; overflow-wrap:anywhere; }}
  .muted {{ color:var(--muted); }} .small {{ font-size:.85rem; margin:6px 0 0; }} .nowrap {{ white-space:nowrap; }}
  header a {{ text-decoration:none; font-weight:600; }}
  .scroll {{ overflow-x:auto; }}
  table {{ border-collapse:collapse; width:100%; font-size:.93rem; }}
  th, td {{ text-align:left; vertical-align:top; padding:10px 12px; border-bottom:1px solid var(--border); }}
  th {{ font-size:.8rem; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); }}
  .pill {{ display:inline-block; padding:2px 10px; border-radius:99px; font-size:.85rem; font-weight:600; }}
  .pill.ok {{ background:var(--okbg); color:var(--ok); }} .pill.warn {{ background:var(--warnbg); color:var(--warn); }} .pill.bad {{ background:var(--badbg); color:var(--bad); }}
  .banner {{ padding:12px 16px; border-radius:10px; font-weight:600; }}
  .banner.ok {{ background:var(--okbg); color:var(--ok); }} .banner.bad {{ background:var(--badbg); color:var(--bad); }}
  details {{ margin-top:8px; }} summary {{ cursor:pointer; font-size:.85rem; }} li {{ margin:6px 0; }}
  .untriaged {{ color:var(--bad); }}
  pre {{ background:var(--surface); padding:12px 14px; border-radius:10px; overflow-x:auto; font-size:.85rem; }}
  footer {{ border-top:1px solid var(--border); margin-top:48px; padding-top:16px; font-size:.9rem; }}
  @media (max-width:640px) {{
    thead {{ display:none; }} table, tbody, tr, td {{ display:block; width:100%; }}
    tr {{ border-bottom:1px solid var(--border); padding:8px 0; }} td {{ border:0; padding:4px 0; }}
    td::before {{ content:attr(data-l); display:block; font-size:.75rem; text-transform:uppercase; color:var(--muted); }}
  }}
</style>
</head>
<body>
<main>
  <header><p><a href="./">← Morphness</a></p></header>
  <h1>Test results</h1>
  <p class="muted">What Morphness is tested with, what came out, and when. Release <b>{E(data["release"])}</b>, commit <a href="{REPO}/commit/{E(data["commit"])}"><code>{E(short)}</code></a>, run {E(data["generated"])}.{dirty}</p>
  {state}
  <p>This page is written by <a href="{REPO}/blob/main/scripts/trust-report.sh"><code>scripts/trust-report.sh</code></a> from a real run, never by hand. A tool that fails to start is shown as "did not run", not as a pass. Every warning, error or finding gets a verdict in <a href="{REPO}/blob/main/tests/triage.jsonl"><code>tests/triage.jsonl</code></a> (fixed, false positive or accepted, with the reason); one without a verdict is shown as untriaged. "Tested with" is all this page claims. It is not a certificate that Morphness is secure.</p>

  <h2>Morphness's own checks</h2>
  <p class="muted">Anyone who clones the repository can run these.</p>
{table("own")}

  <h2>Public tools</h2>
  <p class="muted">Pinned versions, run locally with no API key. Nothing is uploaded to the tools' vendors.</p>
{table("public")}

  <h2>Known limits</h2>
  <p>What these results do not cover, kept in <a href="{REPO}/blob/main/tests/known-gaps.md"><code>tests/known-gaps.md</code></a>:</p>
  <ul>
{lim}
  </ul>

  <h2>Run it yourself</h2>
<pre>git clone {REPO}.git &amp;&amp; cd morphness &amp;&amp; git fetch --tags
scripts/kit-selftest.sh          # the kit's own checks
scripts/trust-report.sh --out /tmp/trust   # everything on this page, written to /tmp/trust</pre>
  <p class="muted">Raw data for this run: <a href="trust/results.json">results.json</a>. Results change when the kit or the tools do, so check the date above.</p>
  <footer>MIT licensed · <a href="{REPO}">GitHub</a> · <a href="privacy.html">Privacy</a> · Built by <a href="https://github.com/antarsoft">Antarsoft</a></footer>
</main>
</body>
</html>
"""

def write_page(data):
    os.makedirs(os.path.dirname(html_path), exist_ok=True)
    open(html_path, "w", encoding="utf-8").write(render_page(data))
    # shields.io endpoint data for the README badge: derived from the same rows as the page
    problems = [r for r in data["rows"] if r["status"] in ("fail", "did-not-run", "untriaged")]
    day = data["generated"][:10]
    badge = {"schemaVersion": 1, "label": "tests",
             "message": (f"{len(problems)} problem(s) · {day}" if problems else f"all checks pass · {day}"),
             "color": "red" if problems else "brightgreen"}
    os.makedirs(data_dir, exist_ok=True)
    open(os.path.join(data_dir, "badge.json"), "w", encoding="utf-8").write(json.dumps(badge) + "\n")

if render_only:
    data = json.load(open(render_only, encoding="utf-8"))
    write_page(data)
    print(f"wrote {html_path}")
    sys.exit(0)

# ---------------------------------------------------------------------------------------------------------
# Running
# ---------------------------------------------------------------------------------------------------------
tmp = tempfile.mkdtemp(prefix="morphness-trust-")
tools = os.path.join(tmp, "tools"); os.makedirs(tools)
shutil.rmtree(log_dir, ignore_errors=True); os.makedirs(log_dir)
install_dir = None            # rendered sample install, set by the self-test run
rows = []
redact = [(root, "<repo>"), (tmp, "<tmp>")]

def scrub(text):
    for a, b in redact: text = text.replace(a, b)
    return text

def save_log(name, text):
    open(os.path.join(log_dir, name), "w", encoding="utf-8").write(scrub(text))
    return name

def triage_rules():
    p = os.path.join(root, "tests/triage.jsonl")
    return [json.loads(l) for l in open(p, encoding="utf-8") if l.strip()] if os.path.exists(p) else []
TRIAGE = triage_rules()
used_triage = set()

def judge(tool, rule, path):
    for n, t in enumerate(TRIAGE):
        if t["tool"] == tool and t["rule"] == rule and fnmatch.fnmatch(path, t.get("path", "*")):
            used_triage.add(n)
            return {"status": t["status"], "reason": t["reason"]}
    return None

def public_row(name, tool, what, command, version, findings, notes_count, logs, extra="", notes=""):
    """findings: those needing a verdict; notes_count: informational items only counted."""
    for f in findings:
        f["triage"] = judge(tool, f["rule"], f["path"])
    open_n = sum(1 for f in findings if not f["triage"])
    if not findings:
        status, summary = "clean", "0 findings" + (f" ({notes_count} informational)" if notes_count else "")
    elif open_n:
        status, summary = "untriaged", f"{len(findings)} finding(s), {open_n} untriaged"
    else:
        status, summary = "triaged", f"{len(findings)} finding(s), all judged" + (f" ({notes_count} informational)" if notes_count else "")
    if extra: summary += "; " + extra
    rows.append({"group": "public", "name": name, "url": URLS[tool], "version": version, "what": what, "command": command,
                 "status": status, "summary": summary, "findings": findings, "logs": logs, "finished": now(), "notes": notes})

def failed_row(group, name, what, command, err, tool=None, version=""):
    rows.append({"group": group, "name": name, "url": URLS.get(tool or "", ""), "version": version, "what": what, "command": command,
                 "status": "did-not-run", "error": str(err)[:300].replace(root, "<repo>"), "summary": "", "findings": [], "logs": [], "finished": now()})

def guard(tool):
    if tool in fake_fail: raise RuntimeError("TRUST_FAKE_FAIL set for this tool")

commit = sh(["git", "rev-parse", "HEAD"]).stdout.strip()
dirty = bool(sh(["git", "status", "--porcelain"]).stdout.strip())
if sh(["git", "describe", "--tags", "--abbrev=0"]).returncode:
    sh(["git", "fetch", "--tags", "--quiet", "origin"])
release = sh(["git", "describe", "--tags", "--abbrev=0"]).stdout.strip() or "unreleased"
head_tag = sh(["git", "describe", "--tags", "--exact-match", "HEAD"]).stdout.strip()
if not head_tag and release != "unreleased":
    release += " + later commits"

# --- own checks -------------------------------------------------------------------------------------------
cases = [json.loads(l) for l in open(os.path.join(root, "tests/guard-cases.jsonl"), encoding="utf-8") if l.strip()]
fixtures = sorted(os.listdir(os.path.join(root, "tests/fixtures")))
by = {k: sum(1 for c in cases if c["expect"] == k) for k in ("pass", "ask", "deny")}
SELF_CMD = "STRICT=1 GUARD_FULL=1 scripts/kit-selftest.sh"
if skip_selftest:
    failed_row("own", "Kit self-test", "Renders the template for sample projects and checks it.", SELF_CMD, "skipped with --skip-selftest")
else:
    try:
        guard("selftest")
        env = dict(os.environ, KEEP="1", STRICT="1", GUARD_FULL="1")
        r = sh(["bash", "scripts/kit-selftest.sh"], env=env)
        text = r.stdout + r.stderr
        m = re.search(r"rendered copies kept in (\S+)", text)
        keep = m.group(1) if m else None
        if keep: redact.append((keep, "<install-root>"))
        log = save_log("kit-selftest.txt", text)
        ok_projects = re.findall(r"^(\S+): ok$", text, re.M)
        fails = [l for l in text.splitlines() if l.startswith("FAIL")]
        tail = [l for l in text.splitlines() if l.startswith("kit self-test:")]
        passed = r.returncode == 0 and not fails
        if keep:
            samples = [d for d in os.listdir(keep) if os.path.isdir(os.path.join(keep, d))]
            install_dir = os.path.join(keep, "nextjs-supabase") if "nextjs-supabase" in samples else (os.path.join(keep, samples[0]) if samples else None)
        replays = len(cases) * len(fixtures)
        summary = (f"{len(ok_projects)} of {len(fixtures)} sample projects pass; {len(cases)} guard cases replayed on each ({replays} replays; per project "
                   f"{by['pass']} allowed, {by['ask']} asked, {by['deny']} denied, all as expected)") if passed else \
                  ("; ".join(fails[:3]) or (tail[0] if tail else f"exit {r.returncode}"))
        rows.append({"group": "own", "name": "Kit self-test", "url": REPO + "/blob/main/scripts/kit-selftest.sh", "version": "",
                     "what": "Renders the template as /morph-init would for sample projects, runs its own consistency checks, replays every guard case and runs the template scripts.",
                     "command": SELF_CMD, "status": "pass" if passed else "fail", "summary": summary, "findings": [], "logs": [log],
                     "finished": now(), "notes": "Sample projects: " + ", ".join(f[:-5] for f in fixtures) + "."})
    except Exception as e:
        failed_row("own", "Kit self-test", "Renders the template for sample projects and checks it.", SELF_CMD, e)

def own_script(name, script, what, pattern, logname):
    try:
        guard("selftest")
        r = sh(["bash", f"scripts/{script}"])
        text = r.stdout + r.stderr
        log = save_log(logname, text)
        m = re.search(pattern, text)
        ok = r.returncode == 0 and m is not None
        rows.append({"group": "own", "name": name, "url": REPO + f"/blob/main/scripts/{script}", "version": "", "what": what,
                     "command": f"scripts/{script}", "status": "pass" if ok else "fail",
                     "summary": (m.group(0) if m else text.strip().splitlines()[-1] if text.strip() else f"exit {r.returncode}"),
                     "findings": [], "logs": [log], "finished": now()})
    except Exception as e:
        failed_row("own", name, what, f"scripts/{script}", e)

own_script("Update notes", "check-updates.sh", "Every kit change has an update note, and every note is well formed.", r"\d+ update note\(s\) checked, 0 problem\(s\)", "check-updates.txt")
own_script("Lesson catalog", "check-lessons.sh", "Every lesson file follows the catalog format.", r"\d+ lesson file\(s\) checked, 0 problem\(s\)", "check-lessons.txt")

# --- public tools -----------------------------------------------------------------------------------------
tool_env = dict(os.environ, PYTHONPATH=os.path.join(tools, "py"), PATH=os.path.join(tools, "py", "bin") + os.pathsep + os.environ["PATH"])

# agnix
def run_agnix():
    guard("agnix")
    version = PINS["agnix"]
    findings, infos, logs, checked = [], 0, [], 0
    targets = [("install", install_dir), ("skills", os.path.join(root, "skills"))]
    if not install_dir: raise RuntimeError("no rendered sample install (the self-test did not leave one)")
    for label, path in targets:
        r = sh(["npx", "--yes", f"agnix@{version}", "--format", "json", path], env=tool_env)
        try: d = json.loads(r.stdout)
        except ValueError: raise RuntimeError(f"no JSON from agnix ({(r.stderr or r.stdout).strip()[:200]})")
        logs.append(save_log(f"agnix-{label}.json", json.dumps(d, indent=1)))
        version = d.get("version", version); checked += d.get("files_checked", 0)
        for x in d["diagnostics"]:
            rel = os.path.relpath(x["file"], path) if x["file"].startswith(path) else x["file"]
            if x["level"] in ("error", "warning"):
                findings.append({"rule": x["rule"], "path": f"{label}/{rel}" if rel != "." else label, "line": x.get("line"),
                                 "level": x["level"], "message": x["message"]})
            else: infos += 1
    public_row("agnix", "agnix", "Config correctness of CLAUDE.md, AGENTS.md, rules, agents, settings, hooks and skills, on a rendered sample install and on the kit's skills.",
               f"npx agnix@{PINS['agnix']} --format json <path>", version, findings, infos, logs,
               notes=f"{checked} files checked. Errors and warnings need a verdict; info notes are only counted.")
# shellcheck
def run_shellcheck():
    guard("shellcheck")
    sh([sys.executable, "-m", "pip", "install", "--quiet", "--target", os.path.join(tools, "py"), f"shellcheck-py=={PINS['shellcheck-py']}"], check=True)
    ver = re.search(r"version: (\S+)", sh(["shellcheck", "--version"], env=tool_env).stdout)
    files = sorted(sh(["git", "ls-files", "*.sh"]).stdout.split())
    r = sh(["shellcheck", "-x", "-f", "json"] + files, env=tool_env)
    try: d = json.loads(r.stdout or "[]")
    except ValueError: raise RuntimeError(f"no JSON from shellcheck ({r.stderr.strip()[:200]})")
    log = save_log("shellcheck.json", json.dumps(d, indent=1))
    findings = [{"rule": f"SC{x['code']}", "path": x["file"], "line": x["line"], "level": x["level"], "message": x["message"]}
                for x in d if x["level"] in ("error", "warning")]
    infos = sum(1 for x in d if x["level"] not in ("error", "warning"))
    public_row("ShellCheck", "shellcheck", "The kit's bash scripts and the scripts installed into projects, including the guard hook.",
               "shellcheck -x -f json $(git ls-files '*.sh')", ver.group(1) if ver else "", findings, infos, [log],
               notes=f"{len(files)} scripts. Errors and warnings need a verdict; style notes and info are only counted.")
# gitleaks
def run_gitleaks():
    guard("gitleaks")
    ver = PINS["gitleaks"]
    sysn = {"Linux": "linux", "Darwin": "darwin"}.get(platform.system())
    arch = {"x86_64": "x64", "AMD64": "x64", "aarch64": "arm64", "arm64": "arm64"}.get(platform.machine())
    if not sysn or not arch: raise RuntimeError(f"no gitleaks build pinned for {platform.system()} {platform.machine()}")
    base = f"{URLS['gitleaks']}/releases/download/v{ver}/"
    name = f"gitleaks_{ver}_{sysn}_{arch}.tar.gz"
    tgz = os.path.join(tools, name)
    urllib.request.urlretrieve(base + name, tgz)
    sums = urllib.request.urlopen(base + f"gitleaks_{ver}_checksums.txt").read().decode()
    want = dict(l.split()[::-1] for l in sums.splitlines() if l.strip()).get(name)
    got = hashlib.sha256(open(tgz, "rb").read()).hexdigest()
    if want != got: raise RuntimeError("gitleaks download does not match its published checksum")
    tarfile.open(tgz).extract("gitleaks", tools, filter="data")
    rep = os.path.join(tmp, "gitleaks.json")
    r = sh([os.path.join(tools, "gitleaks"), "detect", "--no-banner", "--redact", "-s", root, "-r", rep, "-f", "json"])
    if r.returncode not in (0, 1): raise RuntimeError(f"gitleaks exit {r.returncode}: {r.stderr.strip()[-200:]}")
    d = json.load(open(rep))
    commits = re.search(r"(\d+) commits scanned", re.sub(r"\x1b\[[0-9;]*m", "", r.stderr))
    log = save_log("gitleaks.json", json.dumps(d, indent=1))
    findings = [{"rule": x["RuleID"], "path": x["File"], "line": x.get("StartLine"), "level": "secret", "message": x.get("Description", "secret")} for x in d]
    public_row("gitleaks", "gitleaks", "Secrets in the files and in the whole git history (matches are redacted in the log).",
               "gitleaks detect --redact", ver, findings, 0, [log], notes=(f"{commits.group(1)} commits scanned." if commits else ""))
# skillspector
def run_skillspector():
    guard("skillspector")
    skills = sorted(d for d in os.listdir(os.path.join(root, "skills")) if os.path.isdir(os.path.join(root, "skills", d)))
    findings, logs, scores, ver = [], [], [], ""
    for s in skills:
        out = os.path.join(tmp, f"ss-{s}.json")
        r = sh(["uvx", "--from", f"git+{URLS['skillspector']}@{PINS['skillspector']}", "skillspector", "scan",
                os.path.join(root, "skills", s), "--no-llm", "--format", "json", "--output", out])
        if not os.path.exists(out): raise RuntimeError(f"no report for {s}: {(r.stderr or r.stdout).strip()[-200:]}")
        d = json.load(open(out))
        logs.append(save_log(f"skillspector-{s}.json", json.dumps(d, indent=1)))
        ver = d["metadata"].get("skillspector_version", ver)
        scores.append(f"{s} {d['risk_assessment']['score']}/100")
        for x in d["issues"]:
            findings.append({"rule": str(x.get("rule_id") or x.get("id") or x.get("category") or "issue"), "path": f"skills/{s}/" + str(x.get("file") or "SKILL.md"),
                             "line": x.get("line") or x.get("line_number"), "level": str(x.get("severity", "")), "message": str(x.get("description") or x.get("title") or x.get("message") or "")})
    public_row("SkillSpector", "skillspector", "Prompt injection, exfiltration and tool poisoning patterns in the five /morph-* skills. Static mode only, no model is called.",
               "skillspector scan skills/<name> --no-llm", ver, findings, 0, logs, notes="Risk scores (0 is best): " + ", ".join(scores) + ".")

for fn, label, what, cmd in [
    (run_agnix, "agnix", "Config correctness of the agent files.", "npx agnix"),
    (run_shellcheck, "ShellCheck", "The kit's bash scripts.", "shellcheck"),
    (run_gitleaks, "gitleaks", "Secrets in files and history.", "gitleaks detect"),
    (run_skillspector, "SkillSpector", "Security patterns in the skills.", "skillspector scan"),
]:
    try: fn()
    except Exception as e: failed_row("public", label, what, cmd, e, tool={"agnix": "agnix", "ShellCheck": "shellcheck", "gitleaks": "gitleaks", "SkillSpector": "skillspector"}[label])

stale = [t for n, t in enumerate(TRIAGE) if n not in used_triage]
limits = [l[2:].strip() for l in open(os.path.join(root, "tests/known-gaps.md"), encoding="utf-8") if l.startswith("- ")]
data = {"schema": 1, "generated": now(), "commit": commit, "release": release, "dirty": dirty, "rows": rows, "limits": limits,
        "stale_triage": [f"{t['tool']} {t['rule']} {t.get('path', '*')}" for t in stale]}
os.makedirs(data_dir, exist_ok=True)
open(os.path.join(data_dir, "results.json"), "w", encoding="utf-8").write(json.dumps(data, indent=1) + "\n")
write_page(data)
shutil.rmtree(tmp, ignore_errors=True)
if install_dir: shutil.rmtree(os.path.dirname(install_dir), ignore_errors=True)

bad = [r for r in rows if r["status"] in ("fail", "did-not-run") or (r["status"] == "untriaged" and not allow_untriaged)]
for r in rows:
    print(f"{r['status']:<11} {r['name']}: {r.get('summary') or r.get('error', '')}")
if stale: print("note: triage entries that matched nothing: " + "; ".join(data["stale_triage"]))
print(f"wrote {html_path}, {os.path.join(data_dir, 'results.json')}")
sys.exit(1 if bad else 0)
PY
