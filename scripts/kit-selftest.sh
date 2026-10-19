#!/usr/bin/env bash
# Kit self-test: renders template/ for each sample project in tests/fixtures/ the way /morph-init
# would (placeholders, config values, modules on and off, missing checks), then runs the self-checks
# from skills/morph-init/references/render.md § 7 on the result, the guard hook cases in
# tests/guard-cases.jsonl, and the template scripts. It catches kit drift: a placeholder render.md
# doesn't know, a link to a file that moved, a module marker that leaves broken text, a script that
# no longer runs on a fresh install. It also checks that /morph-module can add any module back: each
# module has On install and On remove, and each marked span has a unique anchor line above it.
#
# Usage: scripts/kit-selftest.sh [fixture ...]   (a name such as python-cli, or a path; default: every
#   tests/fixtures/*.json)
#   KEEP=1 keeps the rendered copies and prints where they are.
#   STRICT=1 (CI) fails when PyYAML is missing instead of skipping the YAML checks.
# Needs bash, git, perl and python3. Read-only on the repo: renders into a temporary folder.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -I - "$ROOT" "$@" <<'PY'
import glob, json, os, re, shutil, subprocess, sys, tempfile

root, wanted = sys.argv[1], sys.argv[2:]
template = os.path.join(root, "template")
render_md = open(os.path.join(root, "skills/morph-init/references/render.md"), encoding="utf-8").read()
harness_readme = open(os.path.join(template, "harness/README.md"), encoding="utf-8").read()
fixtures = [w if os.path.exists(w) else os.path.join(root, "tests/fixtures", w + ".json") for w in wanted] \
    or sorted(glob.glob(os.path.join(root, "tests/fixtures/*.json")))
cases = [json.loads(l) for l in open(os.path.join(root, "tests/guard-cases.jsonl"), encoding="utf-8") if l.strip()]
ALL_MODULES = sorted(os.listdir(os.path.join(template, "harness/modules")))
try:
    import yaml
except ImportError:
    yaml = None
    if os.environ.get("STRICT") == "1":
        sys.exit("PyYAML is missing (python3 -m pip install pyyaml); STRICT=1 needs it")
    print("note: PyYAML not installed, YAML checks skipped")

PLACEHOLDER = re.compile(r"(?<!\$)\{\{ *([a-z][a-z0-9_.-]*) *\}\}")
DEFAULTS = {
    "human.name": "Sam Owner", "human.github": "samowner",
    "models.tl": "opus", "models.fullstack": "opus", "models.fullstack_medium": "sonnet",
    "models.qa": "sonnet", "models.qa_medium": "sonnet", "models.researcher": "sonnet",
    "models.researcher_high": "opus", "models.legal": "opus",
    "morphness.repo": "https://github.com/antarsoft/morphness", "morphness.commit": "0000000",
    "morphness.release": "unreleased", "ci.on_drafts": "false",
    "ci.docs_regex": r"^(_harness|docs|harness|project)/|\.md$",
    "branch_protection.required_approvals": "0",
}
failures = []

def run(cmd, cwd, **kw):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, **kw)

def files_under(base, *, exts=None):
    for dirpath, dirnames, names in os.walk(base):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for n in names:
            if exts is None or n.endswith(exts):
                yield os.path.join(dirpath, n)

def read(p):
    return open(p, encoding="utf-8").read()

def write(p, s):
    open(p, "w", encoding="utf-8").write(s)

# ---- once: every placeholder the kit uses is documented in render.md § 3 ------------------------
used = set()
for f in files_under(template):
    try:
        used |= set(PLACEHOLDER.findall(read(f)))
    except UnicodeDecodeError:
        pass
for key in sorted(used):
    documented = f"`{key}`" in render_md or (key.startswith("cmd.") and "`cmd.<check-name>`" in render_md)
    if not documented:
        failures.append(f"kit: placeholder {{{{{key}}}}} is used in template/ but not listed in render.md § 3")

m = re.search(r"\*\*Module markers\.\*\*.*?```bash\n(.*?)\n```", harness_readme, re.S)
if not m:
    sys.exit("kit: no module marker command found in template/harness/README.md § Modules")
MARKER_CMD = m.group(1)

# ---- once: /morph-module can add and remove every module ---------------------------------------
# It runs each module's On install / On remove, and puts a marked span back right after its anchor
# (the nearest non-blank line above it in the kit's file that isn't marked for the module), so each
# anchor must be found exactly once in the file without the module.
morph_module = open(os.path.join(root, "skills/morph-module/SKILL.md"), encoding="utf-8").read()
for name in ALL_MODULES:
    readme = read(os.path.join(template, f"harness/modules/{name}/README.md"))
    for section in ("## On install", "## On remove"):
        if section not in readme:
            failures.append(f"kit: harness/modules/{name}/README.md has no {section} section")
    if f"`{name}`" not in morph_module:
        failures.append(f"kit: skills/morph-module/SKILL.md doesn't name the {name} module")
    opening, closing = f"<!-- module:{name} -->", f"<!-- /module:{name} -->"
    inline = re.compile(re.escape(opening) + ".*?" + re.escape(closing))
    for f in files_under(template, exts=".md"):
        text = read(f)
        if opening not in text:
            continue
        rel = os.path.relpath(f, template)
        scratch = tempfile.mkdtemp(prefix="morphness-anchor-")
        os.makedirs(os.path.join(scratch, "harness"))
        copy = os.path.join(scratch, "harness/file.md")
        write(copy, text)
        run(["bash", "-c", MARKER_CMD.replace("m=legal;", f"m={name};", 1)], scratch)
        without = read(copy).split("\n")
        shutil.rmtree(scratch)
        lines, marked, starts, i = text.split("\n"), set(), [], 0
        while i < len(lines):
            if lines[i] == opening:
                if closing not in lines[i:]:
                    failures.append(f"kit: {rel}: a {name} block opened on line {i + 1} is never closed"); break
                j = lines.index(closing, i)
                marked |= set(range(i, j + 1)); starts.append(i); i = j + 1; continue
            stripped = inline.sub("", lines[i])
            if opening in stripped:
                marked.add(i); starts.append(i)
            elif stripped != lines[i] and without.count(stripped) != 1:
                failures.append(f"kit: {rel}: the line holding a {name} span isn't unique without it: {stripped[:70]!r}")
            i += 1
        for s in starts:
            if s - 1 in marked:
                continue
            a = s - 1
            while a >= 0 and (not lines[a].strip() or a in marked):
                a -= 1
            anchor = inline.sub("", lines[a]) if a >= 0 else None
            if anchor is None or without.count(anchor) != 1:
                failures.append(f"kit: {rel}: a {name} span (line {s + 1}) has no unique anchor line above it")

# ---- render ------------------------------------------------------------------------------------
def remove_module(t, name):
    readme = read(os.path.join(t, f"harness/modules/{name}/README.md"))
    on_remove = readme.split("## On remove", 1)[1] if "## On remove" in readme else ""
    files = re.search(r"\*\*Delete these files:\*\*(.*?)(\n\*\*|\Z)", on_remove, re.S)
    for path in re.findall(r"^- `([^`]+)`", files.group(1) if files else "", re.M):
        if os.path.exists(os.path.join(t, path)):
            os.remove(os.path.join(t, path))
    r = run(["bash", "-c", MARKER_CMD.replace("m=legal;", f"m={name};", 1)], t)
    if r.returncode:
        failures.append(f"module marker command failed for {name}: {r.stderr.strip()}")
    if name == "roadmap":
        # On remove: "replace the paragraph … or delete it" in AGENTS.md § Product docs; the test deletes it.
        p = os.path.join(t, "AGENTS.md")
        write(p, re.sub(r"^\*\*\[docs/ROADMAP\.md\]\(docs/ROADMAP\.md\) is the source of truth.*\n", "", read(p), flags=re.M))
    shutil.rmtree(os.path.join(t, f"harness/modules/{name}"))
    link = re.compile(r"\[([^\]]*)\]\(([^)]*modules/" + re.escape(name) + r"/[^)]*)\)")
    for f in files_under(t, exts=".md"):
        s = read(f)
        if link.search(s):
            write(f, link.sub(r"\1", s))

def env_line(e):
    return (f"  - {{ name: {e['name']}, branch: {e['branch']}, deploy: {e['deploy']}, "
            f"real_data: {str(e['real_data']).lower()} }}")

def app_line(a):
    deploy = ", ".join(f"{k}: {v}" for k, v in a["deploy"].items())
    return (f"  - {{ name: {a['name']}, path: {a['path']}, stack: \"{a['stack']}\", e2e: {a['e2e']}, "
            f"deploy: {{ {deploy} }} }}")

def drop_block(lines, start_re):
    """Remove the comment lines right above the matching key and the key's indented block."""
    out, i = [], 0
    while i < len(lines):
        if re.match(start_re, lines[i]):
            while out and out[-1].startswith("#"):
                out.pop()
            i += 1
            while i < len(lines) and lines[i].startswith((" ", "\t")):
                i += 1
            continue
        out.append(lines[i]); i += 1
    return out

def render_config(t, fx, modules, ci_paths):
    p = os.path.join(t, "harness.config.yml")
    lines = read(p).split("\n")
    out, i = [], 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("environments:"):
            while i + 1 < len(lines) and lines[i + 1].startswith("  - "):
                i += 1
            out += ["environments:"] + [env_line(e) for e in fx["environments"]] if fx["environments"] else ["environments: []"]
        elif line.startswith("apps: []") and fx["apps"]:
            out += ["apps:"] + [app_line(a) for a in fx["apps"]]
        elif line.startswith("modules:"):
            out.append(f"modules: [{', '.join(modules)}]")
        elif line.startswith("environment:") and "claude-projects" in modules:
            out.append("environment: [claude-code-cli, claude-projects]")
        else:
            for key, value in (("integration", fx["branches"]["integration"]),
                               ("production", fx["branches"]["production"]),
                               ("default", fx["branches"]["integration"])):
                line = re.sub(rf"^(  {key}: )\S+", rf"\g<1>{value}", line)
            for key in ("before_qa", "before_signoff"):
                line = re.sub(rf"^(  {key}: )\[.*\]", rf"\g<1>[{', '.join(fx['checks'][key])}]", line)
            if "roadmap" not in modules:
                line = re.sub(r"^(  enabled: )true$", r"\1false", line) if out and out[-1].startswith("roadmap:") else line
            for key, path in ci_paths.items():
                line = re.sub(rf"^(  {key}: )\S+$", rf"\g<1>{path}", line) if any(o.startswith("ci_cd:") for o in out[-6:]) else line
            if "legal" in modules or not line.startswith("  legal_writer:"):
                out.append(line)
        i += 1
    if "ci-cd" not in modules:
        out = drop_block(out, r"^ci_cd:")
    if "claude-projects" not in modules:
        out = drop_block(out, r"^claude_projects:")
    write(p, "\n".join(out))

def fill_workflow(path, fx):
    out = []
    for line in read(path).split("\n"):
        if "morph-init: fill one line per entry in harness.config.yml → environments" in line:
            indent = line[: len(line) - len(line.lstrip())]
            out += [f"{indent}{e['name']}) want={e['branch']} ;;" for e in fx["environments"]]
            continue
        out.append(line)
    # Other fill comments are prose /morph-init writes; the test drops them with their continuation lines.
    lines, kept, skipping = out, [], None
    for line in lines:
        stripped = line.lstrip()
        indent = len(line) - len(stripped)
        if stripped.startswith("# morph-init: fill"):
            skipping = indent; continue
        if skipping is not None and stripped.startswith("#") and indent == skipping:
            continue
        skipping = None
        kept.append(line)
    write(path, "\n".join(kept))

def render(fx, t):
    shutil.copytree(template, t)
    modules = fx["modules"]
    values = dict(DEFAULTS)
    values.update({"branches.integration": fx["branches"]["integration"],
                   "branches.production": fx["branches"]["production"]})
    envs = fx["environments"]
    values["environments.names"] = ", ".join(e["name"] for e in envs)
    values["environments.first"] = envs[0]["name"] if envs else ""
    refs = sorted({e["branch"] for e in envs} or {fx["branches"]["production"]})
    values["branch_protection.refs"] = ", ".join(f'"refs/heads/{b}"' for b in refs)
    values.update(fx["values"])
    checks = set(fx["checks"]["before_qa"]) | set(fx["checks"]["before_signoff"])

    for name in ALL_MODULES:
        if name not in modules:
            remove_module(t, name)
    ci_paths = {}
    if "ci-cd" in modules:
        wf = os.path.join(t, ".github/workflows")
        os.makedirs(wf, exist_ok=True)
        wanted_files = ["ci.yml", "tag.yml"]
        if any(e["deploy"] == "workflow" for e in envs):
            wanted_files += ["deploy.yml", "migrations.yml"]
        for f in wanted_files:
            shutil.copy(os.path.join(t, "harness/modules/ci-cd/github", f), os.path.join(wf, f))
            key = {"ci.yml": "ci", "tag.yml": "tags", "deploy.yml": "deploy", "migrations.yml": "migrations"}[f]
            ci_paths[key] = f".github/workflows/{f}"
    if "roadmap" in modules:
        vdir = os.path.join(t, "docs/versions/v1")
        os.makedirs(os.path.join(vdir, "steps"))
        write(os.path.join(t, "docs/ROADMAP.md"), "# Roadmap\n\n| Version | Status |\n|---|---|\n| v1 | **NEXT** |\n")
        shutil.copy(os.path.join(t, "harness/templates/version.md"), os.path.join(vdir, "v1.md"))
        shutil.copy(os.path.join(t, "harness/templates/version-checklist.md"), os.path.join(vdir, "checklist.md"))
        write(os.path.join(vdir, "steps/README.md"), "# Steps\n")
    for a in fx["apps"]:
        os.makedirs(os.path.join(t, a["path"]), exist_ok=True)
        write(os.path.join(t, a["path"], ".gitkeep"), "")

    # A named check the project doesn't have loses its rows (render.md § 3b).
    for rel in ("project/CONTROLS.md", "project/STACK.md"):
        p = os.path.join(t, rel)
        kept = [l for l in read(p).split("\n")
                if not any(n not in checks for n in re.findall(r"\{\{cmd\.([a-z0-9-]+)\}\}", l))]
        write(p, "\n".join(kept))

    for f in files_under(t):
        try:
            s = read(f)
        except UnicodeDecodeError:
            continue
        rel = os.path.relpath(f, t)
        def sub(mm):
            key = mm.group(1)
            if key not in values:
                return mm.group(0)
            v = values[key]
            return v.replace("'", "'\\''") if rel == "scripts/session-start.sh" else v
        s2 = PLACEHOLDER.sub(sub, s)
        s2 = re.sub(r"<!-- morph-init: fill.*?-->", "Not set yet: filled by /morph-init (kit self-test).", s2, flags=re.S)
        if s2 != s:
            write(f, s2)
    render_config(t, fx, modules, ci_paths)
    for f in glob.glob(os.path.join(t, ".github/workflows/*.yml")):
        fill_workflow(f, fx)
    for f in glob.glob(os.path.join(t, "scripts/*.sh")):
        os.chmod(f, 0o755)
    integ = fx["branches"]["integration"]
    for cmd in (["git", "init", "-q", "-b", integ], ["git", "add", "-A"],
                ["git", "-c", "user.name=selftest", "-c", "user.email=selftest@example.com",
                 "commit", "-q", "-m", "chore: install Morphness harness"]):
        r = run(cmd, t)
        if r.returncode:
            sys.exit(f"git failed in {t}: {r.stderr}")

# ---- self-checks (render.md § 7) -------------------------------------------------------------
def strip_code(s):
    s = re.sub(r"^```.*?^```", "", s, flags=re.S | re.M)
    return re.sub(r"`[^`\n]*`", "", s)

def check(name, fx, t):
    bad = lambda msg: failures.append(f"{name}: {msg}")
    # 1. placeholders
    r = run(["bash", "-c", "grep -rnE '(^|[^$]){{ *[a-z]' AGENTS.md CLAUDE.md harness.config.yml project .claude scripts .github"], t)
    for line in r.stdout.splitlines():
        bad(f"placeholder left: {line}")
    # 2. fill comments
    r = run(["grep", "-rn", "--exclude-dir=.git", "<!-- morph-init: fill", "."], t)
    for line in r.stdout.splitlines():
        bad(f"fill comment left: {line}")
    r = run(["grep", "-rn", "morph-init: fill", ".github/workflows"], t) if os.path.isdir(os.path.join(t, ".github/workflows")) else None
    for line in (r.stdout.splitlines() if r else []):
        bad(f"workflow fill line left: {line}")
    # 3. JSON parses
    for rel in [".claude/settings.json", ".mcp.json"] + [os.path.relpath(p, t) for p in glob.glob(os.path.join(t, ".github/rulesets/*.json"))]:
        p = os.path.join(t, rel)
        if os.path.exists(p):
            try:
                json.load(open(p))
            except ValueError as e:
                bad(f"{rel} is not valid JSON: {e}")
    settings = json.load(open(os.path.join(t, ".claude/settings.json")))
    hooks = json.dumps(settings.get("hooks", {}).get("PreToolUse", []))
    if "scripts/guard.sh" not in hooks:
        bad(".claude/settings.json has no PreToolUse hook running scripts/guard.sh")
    # 4. relative links
    sources = ["AGENTS.md", "CLAUDE.md"]
    for base in ("harness", "project", ".claude"):
        for f in files_under(os.path.join(t, base), exts=".md"):
            rel = os.path.relpath(f, t)
            if rel.startswith(("harness/templates/", ".claude/skills/")):
                continue
            sources.append(rel)
    for rel in sources:
        p = os.path.join(t, rel)
        if not os.path.exists(p):
            continue
        for target in re.findall(r"\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)", strip_code(read(p))):
            if re.match(r"^[a-z]+:", target) or target.startswith("#") or "<" in target:
                continue
            path = target.split("#", 1)[0]
            if path and not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(p), path))):
                bad(f"broken link in {rel}: {target}")
    # 5. agent frontmatter
    for f in glob.glob(os.path.join(t, ".claude/agents/*.md")):
        fm = re.match(r"^---\n(.*?)\n---\n", read(f), re.S)
        for key in ("name", "description", "model"):
            if not fm or not re.search(rf"^{key}:\s*\S", fm.group(1), re.M):
                bad(f"{os.path.relpath(f, t)} frontmatter lacks {key}")
    # 6. named checks have commands, and no row names an unknown check
    cfg = lambda key: run(["bash", "-c", f'. scripts/lib/config.sh; config_get {key}'], t).stdout.strip()
    names = set()
    for key in ("checks.before_qa", "checks.before_signoff"):
        names |= {n.strip() for n in cfg(key).strip("[]").split(",") if n.strip()}
    if names != set(fx["checks"]["before_qa"]) | set(fx["checks"]["before_signoff"]):
        bad(f"config_get reads checks as {sorted(names)}")
    controls = read(os.path.join(t, "project/CONTROLS.md"))
    section = controls.split("## Named checks", 1)[-1].split("\n## ", 1)[0]
    rows = dict(re.findall(r"^\| `([a-z0-9-]+)` \| `([^`]*)`", section, re.M))
    for n in sorted(names - rows.keys()):
        bad(f"check {n} has no row in project/CONTROLS.md § Named checks")
    for n, command in rows.items():
        if n not in names:
            bad(f"project/CONTROLS.md § Named checks has a row for {n}, which isn't in checks")
        if not command.strip() or command.strip().lower() in ("none", "not configured"):
            bad(f"check {n} has no real command")
    # 7. YAML parses
    if yaml:
        for rel in ["harness.config.yml"] + [os.path.relpath(p, t) for p in glob.glob(os.path.join(t, ".github/workflows/*.yml"))]:
            try:
                yaml.safe_load(open(os.path.join(t, rel)))
            except yaml.YAMLError as e:
                bad(f"{rel} is not valid YAML: {e}")
    if shutil.which("actionlint") and os.path.isdir(os.path.join(t, ".github/workflows")):
        r = run(["actionlint"], t)
        if r.returncode:
            bad("actionlint:\n" + r.stdout)
    # 8. environments and apps
    if fx["environments"]:
        if fx["environments"][0]["branch"] != cfg("branches.integration"):
            bad("first environment doesn't run branches.integration")
        if fx["environments"][-1]["branch"] != cfg("branches.production"):
            bad("last environment doesn't run branches.production")
    # 8b. without the security module the markdown and config the project reads name no security module text:
    # the marker command ran, so this catches a sentence that mentions the module but was never marked
    # (other modules keep conditional "with the `x` module" wording on purpose; security does not)
    if "security" not in fx["modules"]:
        r = run(["bash", "-c", "grep -rnE --include='*.md' --include='*.yml' --include='*.yaml' 'module:security -->|[Ss]ecurity[ -]module|Security feature: yes|Security review before QA|plan\\.md. § Security' AGENTS.md CLAUDE.md harness harness.config.yml project .claude .github 2>/dev/null"], t)
        for line in r.stdout.splitlines():
            bad(f"security module text left in a project without it: {line[:160]}")
    # 9. scripts
    for f in sorted(glob.glob(os.path.join(t, "scripts/*.sh")) + glob.glob(os.path.join(t, "scripts/lib/*.sh"))):
        r = run(["bash", "-n", f], t)
        if r.returncode:
            bad(f"bash -n {os.path.relpath(f, t)}: {r.stderr.strip()}")
    if not os.access(os.path.join(t, "scripts/session-start.sh"), os.X_OK):
        bad("scripts/session-start.sh is not executable")
    if cfg("branches.integration") != fx["branches"]["integration"]:
        bad("config_get branches.integration doesn't print the integration branch")
    r = run(["bash", "scripts/prune-counter.sh"], t)
    lines = r.stdout.splitlines()
    if r.returncode or not lines or lines[0] != "Prune counter: 0/10":
        bad(f"prune-counter.sh printed {r.stdout!r} (exit {r.returncode}, stderr {r.stderr.strip()!r})")
    if not any(re.match(r"^Rules: \d+(\.\d)?/\d+ KB always loaded", l) for l in lines):
        bad(f"prune-counter.sh printed no Rules gauge line: {r.stdout!r}")
    if any(l.startswith("Prune is DUE") for l in lines):
        bad(f"a fresh install is already due a prune: {r.stdout!r}")
    r = run(["bash", "scripts/prune-counter.sh", "--prune"], t)
    if r.returncode or "Last 0 features: no features" not in r.stdout or "Rule tags: 0 " not in r.stdout:
        bad(f"prune-counter.sh --prune on a fresh install printed {r.stdout!r} (stderr {r.stderr.strip()!r})")
    # prune states: proposed and approved are open (named, no DUE); declined, applied and README are not
    pdir, ldir = os.path.join(t, "_harness/prunes"), os.path.join(t, "_harness/learnings")
    os.makedirs(pdir, exist_ok=True)
    os.makedirs(ldir, exist_ok=True)
    made = [os.path.join(ldir, f"selftest{i}-v1.md") for i in range(10)]
    for f in made:
        open(f, "w").write("x\n")
    for status, want in (("proposed", "waiting"), ("approved", "waiting"), ("declined", "DUE"), ("applied", "DUE")):
        pf = os.path.join(pdir, "2026-01-01.md")
        open(pf, "w").write(f"# Prune\n\n**Status:** {status}  \n")
        open(os.path.join(pdir, "README.md"), "w").write("**Status:** proposed\n")
        out = run(["bash", "scripts/prune-counter.sh"], t).stdout
        waiting = "Prune proposal waiting: _harness/prunes/2026-01-01.md" in out
        due = "Prune is DUE" in out
        if (want == "waiting") != waiting or waiting == due or "README.md" in out:
            bad(f"prune-counter.sh with a {status} proposal and 10 learnings printed {out!r}")
    for f in made + [pf, os.path.join(pdir, "README.md")]:
        os.remove(f)
    r = run(["bash", "scripts/feature-cost.sh"], t, env=dict(os.environ, HOME=t))
    if r.returncode or "Traceback" in r.stdout + r.stderr:
        bad(f"feature-cost.sh failed: {r.stdout}{r.stderr}")
    # guard hook cases
    branches = {"{I}": fx["branches"]["integration"], "{P}": fx["branches"]["production"]}
    for case in cases:
        # "extra" adds top-level event fields (a ConfigChange event has no tool).
        raw = json.dumps({"tool_name": case["tool"], "tool_input": case["input"], **case.get("extra", {})})
        for k, v in branches.items():
            raw = raw.replace(k, v)
        here = case.get("branch", "feature/selftest")
        for k, v in branches.items():
            here = here.replace(k, v)
        raw = raw.replace("{ROOT}", t)
        run(["git", "checkout", "-q", "-B", here], t)
        cfg_path = os.path.join(t, "harness.config.yml")
        saved = open(cfg_path, encoding="utf-8").read()
        if case.get("guard"):
            # "guard": {"deploys": "off"} switches that ask off for this case only.
            pairs = ", ".join(f"{k}: {v}" for k, v in case["guard"].items())
            open(cfg_path, "w", encoding="utf-8").write(re.sub(r"(?m)^guard:.*$", "guard: { " + pairs + " }", saved))
        r = run(["bash", "scripts/guard.sh"], t, input=raw, env=dict(os.environ, CLAUDE_PROJECT_DIR=t))
        open(cfg_path, "w", encoding="utf-8").write(saved)
        got = "deny" if r.returncode == 2 else "ask" if '"ask"' in r.stdout else "pass" if r.returncode == 0 else f"exit {r.returncode}"
        expect = case["expect"]
        if got != expect:
            bad(f"guard: expected {expect}, got {got} for {raw} on branch {here} ({r.stderr.strip()})")
    run(["git", "checkout", "-q", fx["branches"]["integration"]], t)

work = tempfile.mkdtemp(prefix="morphness-selftest-")
for path in fixtures:
    name = os.path.splitext(os.path.basename(path))[0]
    fx = json.load(open(path))
    t = os.path.join(work, name)
    render(fx, t)
    before = len(failures)
    check(name, fx, t)
    print(f"{name}: {'ok' if len(failures) == before else str(len(failures) - before) + ' problem(s)'}")
if os.environ.get("KEEP") == "1":
    print(f"rendered copies kept in {work}")
else:
    shutil.rmtree(work)
for f in failures:
    print("FAIL " + f)
print(f"kit self-test: {len(fixtures)} sample project(s), {len(failures)} problem(s)")
sys.exit(1 if failures else 0)
PY
