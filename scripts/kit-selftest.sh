#!/usr/bin/env bash
# Kit self-test: renders template/ for each sample project in tests/fixtures/ the way /morph-init
# would (placeholders, config values, modules on and off, missing checks), then runs the self-checks
# from skills/morph-init/references/render.md § 7 on the result, the guard hook cases in
# tests/guard-cases.jsonl, and the template scripts. It catches kit drift: a placeholder render.md
# doesn't know, a link to a file that moved, a module marker that leaves broken text, a script that
# no longer runs on a fresh install. It also checks that /morph-module can add any module back: each
# module has On install and On remove, and each marked span has a unique anchor line above it. And it
# checks the kit's own cross-references: every `file § Heading` names a heading that file has, every config
# key a doc or script names is in template/harness.config.yml, and every key there is named somewhere.
#
# Usage: scripts/kit-selftest.sh [fixture ...]   (a name such as python-cli, or a path; default: every
#   tests/fixtures/*.json)
#   KEEP=1 keeps the rendered copies and prints where they are.
#   GUARD_FULL=1 replays every guard case on every sample project (default: cases without "every" run once).
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

# ---- once: § references name headings that exist, and config keys match the template config ------
# A reference such as `harness/SETUP.md § Prune` must point at a heading (or a bold lead-in) in that
# file, and a config key the scripts and docs name (`loop.prune_every`, `config_get guard.deploys`)
# must exist in template/harness.config.yml; every key in that file must be named somewhere in the kit.
doc_files = [f for base in ("template", "skills", "docs") for f in files_under(os.path.join(root, base), exts=".md")]
doc_files += [os.path.join(root, n) for n in ("README.md", "INSTALL.md", "UPDATE.md", "CONTRIBUTING.md") if os.path.exists(os.path.join(root, n))]

def anchors(path):
    found, fence = [], False
    for line in read(path).splitlines():
        if line.startswith("```"):
            fence = not fence
        if fence:
            continue
        m = re.match(r"#{1,6}\s+(.*)", line) or re.match(r"\*\*([^*]+?)\.?\*\*", line)
        if m:
            found.append(re.sub(r"[`*]", "", m.group(1)).strip().lower())
    return found

def norm(s):
    return re.sub(r"\s*\(.*?\)", "", s).strip(" .:").lower()

anchor_cache = {p: anchors(p) for p in doc_files}
def kit_target(ref, src):
    rel = ref.lstrip("/")
    skill = re.match(r"(.*?/skills/[^/]+)/", src.replace(os.sep, "/"))
    local = [os.path.join(os.path.dirname(src), rel)] + ([os.path.join(skill.group(1), rel)] if skill else [])
    found = [os.path.normpath(p) for p in local + [os.path.join(template, rel), os.path.join(root, rel), os.path.join(root, "skills/morph-init", rel)] if os.path.normpath(p) in anchor_cache]
    if found:
        return found[0]
    ends = [p for p in doc_files if p.endswith("/" + rel)] if "/" in rel else []
    return ends[0] if len(ends) == 1 else None

SECTION_REF = re.compile(r"`?([A-Za-z0-9_./-]+\.md)(?:#[\w-]+)?[`)]*,? §§? ?([^\n]*)")
section_refs = 0
for src in doc_files:
    for n, line in enumerate(read(src).splitlines(), 1):
        for m in SECTION_REF.finditer(line):
            target = kit_target(m.group(1), src)
            if not target:
                continue    # a file the project writes at run time (progress.md, qa-result.md, ...)
            wanted = norm(re.split(r"[.;,):]|`|—|→|\s(?:and|or)\b|\sfor\b|\sin\b", m.group(2))[0].strip("* "))
            if not wanted:
                continue
            section_refs += 1
            number = re.match(r"(\d+[a-z]?)\b", wanted)
            have = anchor_cache[target]
            if target.endswith("harness/templates/plan.md"):    # plan.md is also the bug and small plan at run time
                have = have + anchor_cache[target.replace("plan.md", "bug-plan.md")] + anchor_cache[target.replace("plan.md", "small-plan.md")]
            ok = any(re.match(re.escape(number.group(1)) + r"[. ]", h) for h in have) if number else \
                any(norm(h).startswith(wanted) or wanted.startswith(norm(h)) for h in have)
            if not ok:
                failures.append(f"kit: {os.path.relpath(src, root)}:{n} refers to {m.group(1)} § {wanted}, which has no such heading")
if section_refs < 100:
    failures.append(f"kit: only {section_refs} § references found; the heading check no longer reads the docs")

if yaml:
    config_text = read(os.path.join(template, "harness.config.yml"))
    config_lines = config_text.splitlines()
    def comment_block(top):    # the comment lines directly above `top:` in the config
        at = next(i for i, l in enumerate(config_lines) if l.startswith(top + ":"))
        block = []
        while at and config_lines[at - 1].startswith("#"):
            at -= 1
            block.append(config_lines[at])
        return "\n".join(block)
    config_keys = set()
    def flatten(node, prefix=""):
        for k, v in node.items():
            config_keys.add(prefix + k)
            if isinstance(v, dict):
                flatten(v, prefix + k + ".")
    flatten(yaml.safe_load(config_text))
    tops = {k for k in config_keys if "." not in k}
    # optional keys the config only describes in a comment (guard.fail_open, guard.allow_hosts) count as there
    known = lambda key: key in config_keys or (key.count(".") == 1 and key.split(".")[0] in tops
                                               and re.search(r"\b%s\b" % re.escape(key.split(".")[1]), comment_block(key.split(".")[0])))
    kit_text = {}
    for p in doc_files + list(files_under(os.path.join(template, "scripts"))) + list(files_under(os.path.join(root, ".github"))):
        try:
            kit_text[p] = read(p)
        except (UnicodeDecodeError, FileNotFoundError):
            pass
    dotted = re.compile(r"`((?:%s)\.[a-z_][a-z0-9_.]*)`" % "|".join(sorted(tops)))
    mentioned = ""
    reads = 0
    for p, text in kit_text.items():
        rel = os.path.relpath(p, root)
        mentioned += text
        if rel.endswith("render.md"):
            continue    # § 3 names render-time placeholders (environments.names), not config keys
        for key in set(dotted.findall(text)) | set(re.findall(r"config_get\s+([a-z_]+\.[a-z_.]+)", text)):
            key = key.rstrip(".")
            reads += 1
            if not known(key):
                failures.append(f"kit: {rel} names config key {key}, which is not in template/harness.config.yml")
    for key in sorted(config_keys):
        last = key.split(".")[-1]
        if key not in mentioned and f"`{last}`" not in mentioned and not re.search(rf"\b{re.escape(last)}:", mentioned):
            failures.append(f"kit: config key {key} in template/harness.config.yml is not named in any doc or script")
    if reads < 30 or len(config_keys) < 40:
        failures.append(f"kit: only {reads} config key mentions and {len(config_keys)} config keys found; the key check no longer reads the kit")

# ---- once: every README promise has a ledger entry, and every entry's proof still exists -------------
# tests/claims.jsonl maps each README promise (a "Why use it" row, "What it isn't", the install routes and
# "Requirements and cost") to the guard cases, self-test checks and files that back it. tests/claims.md
# explains the format. A promise without an entry, an entry whose promise left the README, and a proof
# that no longer exists are all failures; the summary line counts how much is tested, present or judgement.
def readme_promises():
    text = read(os.path.join(root, "README.md"))
    strip = lambda s: re.sub(r"^[^\w]+", "", s).strip().rstrip(".:").strip()
    keys = []
    why = re.search(r"## \S+ Why use it\n(.*?)\n## ", text, re.S)
    for row in (why.group(1).splitlines() if why else []):
        m = re.match(r"\|\s*\S+\s+\*\*(.+?)\*\*\s*\|", row)
        if m:
            keys.append(strip(m.group(1)))
    isnt = re.search(r"\*\*(What it isn't)\.\*\*", text)
    if isnt:
        keys.append(strip(isnt.group(1)))
    inst = re.search(r"## \S+ Install\n(.*?)\n### ", text, re.S)
    for m in re.finditer(r"(?m)^\*\*(.+?)\*\*|<summary><b>(.+?)</b>", inst.group(1) if inst else ""):
        keys.append(strip(m.group(1) or m.group(2)))
    return keys

claims_path = os.path.join(root, "tests/claims.jsonl")
claims = [json.loads(l) for l in read(claims_path).splitlines() if l.strip()]
promises = readme_promises()
if len(promises) < 12:
    failures.append(f"claims: only {len(promises)} README promises found; the parser no longer reads README.md")
entry_ids = [c.get("id") for c in claims]
for dup in sorted({i for i in entry_ids if entry_ids.count(i) > 1}):
    failures.append(f"claims: id {dup} appears twice in tests/claims.jsonl")
for p in promises:
    if not any(c.get("readme") == p for c in claims):
        failures.append(f"claims: the README promises \"{p}\" but tests/claims.jsonl has no entry for it (add one, see tests/claims.md)")
for c in claims:
    cid = c.get("id", "?")
    bad_c = lambda msg: failures.append(f"claims: {cid}: {msg}")
    if c.get("readme") not in promises:
        bad_c(f"names the README promise \"{c.get('readme')}\", which README.md no longer has")
    if c.get("status") not in ("tested", "present", "judgement"):
        bad_c("status must be tested, present or judgement")
    if not c.get("claim") or not c.get("note"):
        bad_c("needs a claim (what the README says) and a note (what the proof does not cover)")
    kinds = {p.get("kind") for p in c.get("proofs", [])}
    if c.get("status") == "tested" and not kinds & {"guard", "selftest"}:
        bad_c("is marked tested but has no guard case or self-test proof")
    if c.get("status") != "judgement" and not c.get("proofs"):
        bad_c("has no proofs")
    for p in c.get("proofs", []):
        if p.get("kind") == "guard":
            hit = [k for k in cases if k["expect"] == p["expect"] and p["contains"] in json.dumps(k["input"])
                   and p.get("tool", k["tool"]) == k["tool"] and bool(p.get("raw")) == ("raw" in k)]
            if not hit:
                bad_c(f"no guard case expects {p['expect']} for {p.get('tool') or 'any tool'} containing {p['contains']!r}")
        elif p.get("kind") in ("check", "selftest"):
            fp = os.path.join(root, p.get("path", ""))
            if not os.path.isfile(fp):
                bad_c(f"proof file {p.get('path')} does not exist")
            elif p["contains"].lower() not in read(fp).lower():
                bad_c(f"proof file {p['path']} no longer contains {p['contains']!r}")
        else:
            bad_c(f"unknown proof kind {p.get('kind')!r}")
tally = {s: sum(c.get("status") == s for c in claims) for s in ("tested", "present", "judgement")}
print(f"claims ledger: {len(promises)} README promises, {tally['tested']} tested, {tally['present']} present in the kit text, {tally['judgement']} judgement")

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

def env_block(e):
    return [f"  - name: {e['name']}", f"    branch: {e['branch']}", f"    deploy: {e['deploy']}",
            f"    real_data: {str(e['real_data']).lower()}"]

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
            if not fx["environments"]:
                out.append("environments: []")
            elif fx.get("environments_style") == "block":
                out += ["environments:"] + [l for e in fx["environments"] for l in env_block(e)]
            else:
                out += ["environments:"] + [env_line(e) for e in fx["environments"]]
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

def render(fx, t, tpl=None):
    tpl = tpl or template
    all_modules = sorted(os.listdir(os.path.join(tpl, "harness/modules")))
    shutil.copytree(tpl, t)
    modules = [m for m in fx["modules"] if m in all_modules]
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

    for name in all_modules:
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

# KB of always-loaded rules (CLAUDE.md, its imports, unscoped .claude/rules) a fresh install may carry.
ALWAYS_LOADED_CEILING_KB = 35

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
        # an unquoted "word: word" in the description is invalid YAML for any strict reader
        d = re.search(r"^description:[ \t]*(.*)$", fm.group(1), re.M) if fm else None
        if d and re.search(r":\s", d.group(1)) and d.group(1)[:1] not in "\"'|>":
            bad(f"{os.path.relpath(f, t)} description has an unquoted colon: quote it")
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
    # 7b. workflows pin every action to a commit and render ci.on_drafts as a boolean
    for wf in glob.glob(os.path.join(t, ".github/workflows/*.yml")):
        for m in re.finditer(r"^\s*-?\s*uses:\s*(\S+)", read(wf), re.M):
            if m.group(1).startswith("./"):
                continue
            if not re.fullmatch(r"[\w./-]+@[0-9a-f]{40}", m.group(1)):
                bad(f"{os.path.relpath(wf, t)}: action not pinned to a commit: {m.group(1)}")
    ci_wf = os.path.join(t, ".github/workflows/ci.yml")
    if os.path.exists(ci_wf):
        drafts = re.search(r"^\s*if: \$\{\{ !github\.event\.pull_request\.draft \|\| (\S+) \}\}", read(ci_wf), re.M)
        if not drafts or drafts.group(1) not in ("true", "false"):
            bad(f"ci.yml draft condition is not a rendered boolean: {drafts.group(1) if drafts else 'line not found'}")
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
    # session-start.sh: prints the command, reports a failure with the tail of its output, times out, and
    # adds --ignore-scripts to an npm install; always exits 0
    src = open(os.path.join(template, "scripts/session-start.sh"), encoding="utf-8").read()
    def start(tool, install, limit="3", extra=()):
        body = re.sub(r"^TOOLCHAIN_SETUP=.*$", lambda m: f"TOOLCHAIN_SETUP='{tool}'", src, flags=re.M)
        body = re.sub(r"^INSTALL_CMD=.*$", lambda m: f"INSTALL_CMD='{install}'", body, flags=re.M)
        f = os.path.join(t, "scripts/.session-start-test.sh")
        open(f, "w").write(body)
        env = dict(os.environ, MORPHNESS_START_TIMEOUT=limit, CLAUDE_PROJECT_DIR=t)
        env.pop("CLAUDE_ENV_FILE", None)
        r = run(["bash", f, *extra], t, env=env)
        os.remove(f)
        return r
    pin = run(["git", "rev-parse", "--git-path", "morphness-session-commands"], t).stdout.strip()
    pin = os.path.join(t, pin) if pin else ""
    def repin():
        if pin and os.path.exists(pin):
            os.remove(pin)
    repin()
    r = start("", "echo one; echo boom >&2; exit 3")
    if r.returncode or "dependency install failed (exit 3)" not in r.stdout or "| boom" not in r.stdout:
        bad(f"session-start.sh on a failing install printed {r.stdout!r} (exit {r.returncode})")
    repin()
    if shutil.which("timeout") or shutil.which("gtimeout"):
        r = start("", "sleep 30", "1")
        if r.returncode or "timed out after 1s" not in r.stdout:
            bad(f"session-start.sh on a hanging install printed {r.stdout!r} (exit {r.returncode})")
    repin()
    r = start("false", "")
    if r.returncode or "toolchain setup failed (exit 1)" not in r.stdout:
        bad(f"session-start.sh on a failing toolchain setup printed {r.stdout!r}")
    repin()
    r = start("", "npm ci")
    if r.returncode or "npm ci --ignore-scripts" not in r.stdout:
        bad(f"session-start.sh did not add --ignore-scripts to npm ci: {r.stdout!r}")
    # pinned commands: a changed command runs nothing until --accept
    r = start("", "echo changed")
    if r.returncode or "NOT RUN" not in r.stdout or "dependency install:" in r.stdout:
        bad(f"session-start.sh ran or stayed quiet on changed commands: {r.stdout!r}")
    r = start("", "echo changed", extra=("--accept",))
    if "NOT RUN" in r.stdout or "dependency install: echo changed" not in r.stdout:
        bad(f"session-start.sh --accept did not run the new commands: {r.stdout!r}")
    repin()
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
    # the kit's own always-loaded text is paid for in every session: keep it under a ceiling
    m = next((re.match(r"^Rules: (\d+(?:\.\d)?)/", l) for l in lines if l.startswith("Rules:")), None)
    if m and float(m.group(1)) > ALWAYS_LOADED_CEILING_KB:
        bad(f"a fresh install loads {m.group(1)} KB of rules in every session, over the kit ceiling of {ALWAYS_LOADED_CEILING_KB} KB: trim the kit's rule text, or raise the ceiling in scripts/kit-selftest.sh on purpose")
    r = run(["bash", "scripts/prune-counter.sh", "--prune"], t)
    if r.returncode or "Last 0 features: no features" not in r.stdout or "Rule tags: 0 " not in r.stdout or "Loop: 0 escapes and 0 rule tags" not in r.stdout:
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
    # an exceeded size budget fails the hand-off until a proposal is open
    big = os.path.join(t, "project/SELFTEST-BIG.md")
    open(big, "w").write("x" * (50 * 1024))
    r = run(["bash", "scripts/prune-counter.sh"], t)
    if r.returncode != 1 or "Prune is DUE" not in r.stdout:
        bad(f"prune-counter.sh with the project docs over budget and no proposal exited {r.returncode}: {r.stdout!r}")
    pf = os.path.join(pdir, "2026-01-01.md")
    open(pf, "w").write("# Prune\n\n**Status:** proposed\n")
    r = run(["bash", "scripts/prune-counter.sh"], t)
    if r.returncode or "Prune proposal waiting" not in r.stdout:
        bad(f"prune-counter.sh with the project docs over budget and a proposal open exited {r.returncode}: {r.stdout!r}")
    os.remove(big)
    os.remove(pf)
    r = run(["bash", "scripts/feature-cost.sh"], t, env=dict(os.environ, HOME=t))
    if r.returncode or "Traceback" in r.stdout + r.stderr:
        bad(f"feature-cost.sh failed: {r.stdout}{r.stderr}")
    r = run(["bash", "scripts/evidence.sh"], t)
    if r.returncode or "# Morphness evidence summary" not in r.stdout or "0 features finished" not in r.stdout or "Traceback" in r.stdout + r.stderr:
        bad(f"evidence.sh on a fresh install printed {r.stdout!r} (stderr {r.stderr.strip()!r})")
    # evidence.sh reads the older entry form and suffixed prune names, and refuses a history it can't read
    lf, pf = os.path.join(t, "_harness/LEARNINGS.md"), os.path.join(t, "_harness/prunes/2026-01-02-b.md")
    keep = open(lf).read()
    os.makedirs(os.path.dirname(pf), exist_ok=True)
    open(lf, "w").write(keep.split("## Entries")[0] + "## Entries\n\n- **one v1** (2026-01-01): pass; QA 1; x\n- two v2, 2026-01-02: pass, QA rounds 2, ≈ $1.50; y\n")
    open(pf, "w").write("# Prune\n\n**Status:** approved by the owner\n\n## 2. Rule audit\n\n| # | Rule | Added by | Evidence | Verdict |\n|---|---|---|---|---|\n| R1 | r | a | fired: x | keep |\n\n## 3. Open\n")
    r = run(["bash", "scripts/evidence.sh"], t)
    if r.returncode or "2 features finished" not in r.stdout or "1 of 1 prune files" not in r.stdout or "1 fired" not in r.stdout or "50% passed QA first time" not in r.stdout:
        bad(f"evidence.sh misread the older record forms: {r.stdout!r} (stderr {r.stderr.strip()!r})")
    open(lf, "w").write(keep.split("## Entries")[0] + "## Entries\n\n- not an entry\n- nor this\n- **one v1** (2026-01-01): pass; QA 1\n")
    r = run(["bash", "scripts/evidence.sh"], t)
    if r.returncode != 3 or r.stdout:
        bad(f"evidence.sh printed a summary that left most entries out (exit {r.returncode}): {r.stdout!r}")
    open(lf, "w").write(keep)
    os.remove(pf)
    # guard hook cases
    # {I^} and {P^} are the same branches in capitals (a guard case for `git push origin Main`).
    branches = {"{I}": fx["branches"]["integration"], "{P}": fx["branches"]["production"],
                "{I^}": fx["branches"]["integration"].upper(), "{P^}": fx["branches"]["production"].upper()}
    # config_env_branches lists every environment branch, in flow or block style alike.
    r = run(["bash", "-c", ". scripts/lib/config.sh; config_env_branches"], t)
    want = [e["branch"] for e in fx["environments"]]
    if r.stdout.split() != want:
        bad(f"config_env_branches printed {r.stdout.split()}, harness.config.yml lists {want}")
    for case in cases:
        if case.get("only") and case["only"] != name:
            continue   # "only": "<fixture>" runs a case on that sample project alone
        if not (case.get("every") or case.get("only") or FULL or name == once_on):
            continue   # a case that doesn't read the project's config runs once, on the canonical sample project
        # "extra" adds top-level event fields (a ConfigChange event has no tool).
        raw = json.dumps({"tool_name": case["tool"], "tool_input": case["input"], **case.get("extra", {})})
        for k, v in branches.items():
            raw = raw.replace(k, v)
        here = case.get("branch", "feature/selftest")
        for k, v in branches.items():
            here = here.replace(k, v)
        raw = raw.replace("{ROOT}", t).replace("{ENC}", re.sub(r"[^A-Za-z0-9]", "-", t))   # {ENC}: how Claude Code names this project's folder under ~/.claude/projects
        if "raw" in case:
            raw = case["raw"]   # input that is not a tool event at all (broken JSON)
        run(["git", "checkout", "-q", "-B", here], t)
        cfg_path = os.path.join(t, "harness.config.yml")
        saved = open(cfg_path, encoding="utf-8").read()
        # "files": {".env": "K=1"} puts those files in the project for this case only (a recursive grep reads them).
        made = []
        for rel, text in case.get("files", {}).items():
            os.makedirs(os.path.dirname(os.path.join(t, rel)) or t, exist_ok=True)
            open(os.path.join(t, rel), "w", encoding="utf-8").write(text)
            made.append(os.path.join(t, rel))
        if case.get("guard"):
            # "guard": {"deploys": "off"} switches that ask off for this case only.
            pairs = ", ".join(f"{k}: {v}" for k, v in case["guard"].items())
            open(cfg_path, "w", encoding="utf-8").write(re.sub(r"(?m)^guard:.*$", "guard: { " + pairs + " }", saved))
        # "origin": "<url>" points the remote at that address for this case only (a PR tool must name the project's own repo).
        old_origin = run(["git", "remote", "get-url", "origin"], t).stdout.strip() if case.get("origin") else ""
        if case.get("origin"):
            run(["git", "remote", "remove", "origin"], t)
            run(["git", "remote", "add", "origin", case["origin"]], t)
        env = dict(os.environ, CLAUDE_PROJECT_DIR=t)
        lib = os.path.join(t, "scripts/lib/config.sh")
        if case.get("without") == "python3":
            # A PATH holding only the tools the script itself needs, so `command -v python3` fails.
            bindir = os.path.join(work, "bin-no-python")
            os.makedirs(bindir, exist_ok=True)
            for tool in ("bash", "git", "awk", "tr", "sed", "grep", "cat", "dirname", "sort"):
                src = shutil.which(tool)
                if src and not os.path.exists(os.path.join(bindir, tool)):
                    os.symlink(src, os.path.join(bindir, tool))
            env["PATH"] = bindir
        if case.get("without") == "config":
            os.rename(lib, lib + ".off")
        r = run(["bash", "scripts/guard.sh"], t, input=raw, env=env)
        if case.get("origin"):
            run(["git", "remote", "remove", "origin"], t)
            if old_origin:
                run(["git", "remote", "add", "origin", old_origin], t)
        if case.get("without") == "config":
            os.rename(lib + ".off", lib)
        open(cfg_path, "w", encoding="utf-8").write(saved)
        for path in made:
            os.remove(path)
        got = "deny" if r.returncode == 2 else "ask" if '"ask"' in r.stdout else "pass" if r.returncode == 0 else f"exit {r.returncode}"
        expect = case["expect"]
        if got != expect:
            bad(f"guard: expected {expect}, got {got} for {raw} on branch {here} ({r.stderr.strip()})")
    run(["git", "checkout", "-q", fx["branches"]["integration"]], t)

# ---- update from the previous release and the oldest supported one ----------------------------
# A project installed from the newest release tag (and from OLDEST_SUPPORTED, below), brought up to
# date the way skills/morph-update does it: the kit updates added since (updates/ notes) merged
# against the template at that release. Without local edits the result must equal a fresh install;
# with edits, they must survive with no conflict. The merged project then goes through the same
# self-checks as a fresh one.
RELEASE_NAME = re.compile(r"v\d+\.\d+\.\d+|\d{4}-\d{2}-\d{2}(?:\.[2-9]|\.[1-9]\d+)?")

def release_key(tag):
    # Dated tags (the first sixteen releases) sort before every semantic version; versions compare as numbers.
    if tag.startswith("v"):
        return (1, tuple(int(x) for x in tag[1:].split(".")))
    date, _, n = tag.partition(".")
    return (0, (int(date.replace("-", "")), int(n or 1)))

_order = sorted(["v0.10.0", "2026-10-20.5", "v0.9.0", "2026-10-14.2", "2026-10-14", "2026-10-14.10", "v1.0.0"], key=release_key)
if _order != ["2026-10-14", "2026-10-14.2", "2026-10-14.10", "2026-10-20.5", "v0.9.0", "v0.10.0", "v1.0.0"]:
    failures.append(f"update: release tags sort wrong: {_order}")

def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    out, key = {}, None
    for line in (m.group(1).splitlines() if m else []):
        item = re.match(r"^\s+-\s+(.*?)\s*(#.*)?$", line)
        if item and key:
            out.setdefault(key, []).append(item.group(1).strip('"'))
            continue
        kv = re.match(r"^([a-z_]+):\s*(.*?)\s*(#.*)?$", line)
        if kv:
            key = kv.group(1)
            out[key] = [] if kv.group(2) in ("", "[]") else kv.group(2)
    return out

def release_tags():
    return sorted((t for t in run(["git", "tag", "--list"], root).stdout.split() if RELEASE_NAME.fullmatch(t)), key=release_key)

def previous_release():
    if os.environ.get("UPDATE_FROM"):
        return os.environ["UPDATE_FROM"]
    tags = release_tags()
    return tags[-1] if tags else None

# The oldest release an install may update from (STABILITY.md § Supported releases). Its update is
# replayed too, once the tag exists; before that release is tagged there is nothing to replay.
OLDEST_SUPPORTED = "v0.13.0"
if f"| {OLDEST_SUPPORTED} and later |" not in read(os.path.join(root, "STABILITY.md")):
    failures.append(f"update: STABILITY.md § Supported releases doesn't start at {OLDEST_SUPPORTED}, the release the self-test replays")

def old_template(tag, dest):
    r = subprocess.run(["git", "-C", root, "archive", tag, "template"], capture_output=True)
    if r.returncode:
        return False
    import io, tarfile
    with tarfile.open(fileobj=io.BytesIO(r.stdout)) as tar:
        try:
            tar.extractall(dest, filter="data")
        except TypeError:
            tar.extractall(dest)
    return True

# Local edits an owner's project would carry: (file, text appended or inserted after an anchor).
EDITS = [
    ("AGENTS.md", None, "\n- Never edit vendor/ by hand.\n"),
    (".claude/rules/testing.md", None, "\n- Run `make fmt` before every commit.\n"),
    ("project/STACK.md", None, "\nOwner note: the staging database is shared.\n"),
    (".claude/settings.json", '"allow": [', '\n      "Bash(make:*)",'),
]

def edit_file(path, anchor, text):
    s = read(path)
    write(path, s + text if anchor is None else s.replace(anchor, anchor + text, 1))

def update_case(name, fx, tag, base_tpl, edits):
    bad = lambda msg: failures.append(f"{name} (update from {tag}{', local edits' if edits else ''}): {msg}")
    work_u = tempfile.mkdtemp(prefix="morphness-update-")
    old, new, proj = (os.path.join(work_u, d) for d in ("old", "new", "proj"))
    render(fx, old, base_tpl)               # what the owner installed at <tag>
    render(fx, new, template)               # what a fresh install of this checkout gives
    shutil.copytree(old, proj)
    if edits:
        for rel, anchor, text in EDITS:
            edit_file(os.path.join(proj, rel), anchor, text)
    ls = lambda ref, d: set(run(["git", "ls-tree", "-r", "--name-only", ref, d], root).stdout.split()) if ref else set()
    added = sorted(f for f in glob.glob(os.path.join(root, "updates", "*.md"))
                   if os.path.basename(f) != "README.md" and f"updates/{os.path.basename(f)}" not in ls(tag, "updates/"))
    files, removed, moved = [], [], {}
    for f in added:
        fm = frontmatter(read(f))
        files += fm.get("files", [])
        removed += fm.get("removed", [])
        for pair in fm.get("moved", []):
            src, _, dst = pair.partition(" -> ")
            moved[src] = dst
    # every template file that differs from the release is named by some new note
    r = run(["git", "diff", "--name-only", tag, "--", "template"], root)
    changed = {p[len("template/"):] for p in r.stdout.split()} | \
              {os.path.relpath(p, template) for p in run(["git", "ls-files", "--others", "--exclude-standard", "--", "template"], root).stdout.split() for p in [os.path.join(root, p)]}
    for p in sorted(changed - set(files) - set(removed) - set(moved) - set(moved.values())):
        bad(f"template/{p} changed since {tag} but no kit update note lists it")
    rd = lambda base, rel: read(os.path.join(base, rel)) if os.path.exists(os.path.join(base, rel)) else None
    def merge(rel_ours, rel_base, rel_theirs, out_rel):
        ours = os.path.join(proj, rel_ours)
        r = run(["git", "merge-file", "-p", ours, os.path.join(old, rel_base), os.path.join(new, rel_theirs)], root)
        if r.returncode > 0:
            bad(f"{rel_ours}: {r.returncode} merge conflict(s) against the template at {tag}")
        os.makedirs(os.path.dirname(os.path.join(proj, out_rel)), exist_ok=True)
        write(os.path.join(proj, out_rel), r.stdout)
    for src, dst in moved.items():
        if rd(proj, src) is None:
            continue
        merge(src, src, dst, dst)
        if src != dst:
            os.remove(os.path.join(proj, src))
    for rel in sorted(set(files)):
        if rel in moved.values() or rd(new, rel) is None:
            continue    # moved (done above), or not part of this project: a module it lacks, a file a later note removed
        targets = [rel]
        scaffold = re.fullmatch(r"harness/modules/ci-cd/github/(.+)", rel)
        if scaffold and rd(new, f".github/workflows/{scaffold.group(1)}") is not None:
            targets.append(f".github/workflows/{scaffold.group(1)}")   # the live copy the scaffold was filled into
        for t_rel in targets:
            if rd(proj, t_rel) is None or rd(old, t_rel) is None:
                os.makedirs(os.path.dirname(os.path.join(proj, t_rel)), exist_ok=True)
                write(os.path.join(proj, t_rel), rd(new, t_rel))
            elif rd(proj, t_rel) == rd(old, t_rel):
                shutil.copy2(os.path.join(new, t_rel), os.path.join(proj, t_rel))
            elif rd(proj, t_rel) != rd(new, t_rel):
                merge(t_rel, t_rel, t_rel, t_rel)
    for rel in removed:
        if rd(proj, rel) is not None and rd(proj, rel) == rd(old, rel):
            os.remove(os.path.join(proj, rel))
    expected = new
    if edits:
        expected = os.path.join(work_u, "expected")
        shutil.copytree(new, expected)
        for rel, anchor, text in EDITS:
            edit_file(os.path.join(expected, rel), anchor, text)
    for base in (expected, proj):
        other = proj if base == expected else expected
        for f in files_under(base):
            rel = os.path.relpath(f, base)
            if rel.startswith(".git/"):
                continue
            a, b = rd(base, rel), rd(other, rel)
            if b is None:
                bad(f"{rel} is {'missing from' if base == expected else 'left in'} the updated project")
            elif base == expected and a != b:
                bad(f"{rel} differs from a fresh install of this checkout")
    return proj, work_u

# Guard cases marked "every" (branches, environments, guard switches, broken input) or "only" replay on each
# sample project; the rest test rules that don't read the project's config, so they run once, on
# nextjs-supabase (closest to the install default; python-cli has integration == production). GUARD_FULL=1,
# or a run that leaves out nextjs-supabase, replays every case on every sample project.
FULL = os.environ.get("GUARD_FULL") == "1"
names = [os.path.splitext(os.path.basename(f))[0] for f in fixtures]
once_on = "nextjs-supabase"
if once_on not in names:
    FULL = True

work = tempfile.mkdtemp(prefix="morphness-selftest-")
prev_tag, old_tpl = previous_release(), None
if prev_tag:
    tpl_dir = tempfile.mkdtemp(prefix="morphness-previous-")
    old_tpl = os.path.join(tpl_dir, "template") if old_template(prev_tag, tpl_dir) else None
if not old_tpl:
    msg = f"no release tag {prev_tag or ''} in this checkout (fetch the tags: git fetch --tags, or checkout with fetch-depth: 0)"
    if os.environ.get("STRICT") == "1":
        failures.append("update: " + msg)
    else:
        print("note: " + msg + "; the update-from-the-previous-release case is skipped")
starts = [(prev_tag, old_tpl)] if prev_tag and old_tpl else []
if not os.environ.get("UPDATE_FROM") and OLDEST_SUPPORTED != prev_tag and OLDEST_SUPPORTED in release_tags():
    tpl_dir = tempfile.mkdtemp(prefix="morphness-oldest-")
    if old_template(OLDEST_SUPPORTED, tpl_dir):
        starts.append((OLDEST_SUPPORTED, os.path.join(tpl_dir, "template")))
for path in fixtures:
    name = os.path.splitext(os.path.basename(path))[0]
    fx = json.load(open(path))
    t = os.path.join(work, name)
    render(fx, t)
    before = len(failures)
    check(name, fx, t)
    for tag, base_tpl in starts:
        for edits in (False, True):
            proj, work_u = update_case(name, fx, tag, base_tpl, edits)
            if edits:
                check(f"{name} (updated from {tag})", fx, proj)
            shutil.rmtree(work_u, ignore_errors=True)
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
