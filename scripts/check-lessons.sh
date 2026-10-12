#!/usr/bin/env bash
# Validate Morphness lesson files. Usage: scripts/check-lessons.sh [file ...]  (default: every lessons/**/*.md)
# Optional: DENY="word1|word2" adds project-specific terms that must not appear (used by /morph-share).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -I - "$ROOT" "$@" <<'PY'
import os, re, sys, glob
root, files = sys.argv[1], sys.argv[2:]
if not files:
    files = [f for f in glob.glob(os.path.join(root, "lessons", "**", "*.md"), recursive=True)
             if os.path.basename(f) != "README.md"]
kinds = {"checklist-item", "rule", "testing-rule", "module-rule", "agent-rule"}
targets_ok = lambda t: os.path.exists(os.path.join(root, "template", t)) or t.startswith("harness/modules/") or t.startswith("project/")
secretish = re.compile(r"(sk_live_|sk_test_|ghp_[A-Za-z0-9]{20}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|eyJhbGciOi|xox[bp]-)")
deny = os.environ.get("DENY")
deny_re = re.compile(deny, re.I) if deny else None
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
    if t and not targets_ok(t): errors.append(f"{rel}: target '{t}' not found in template/")
    a = field("added")
    if a and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", a): errors.append(f"{rel}: added must be YYYY-MM-DD")
    for h in ("## Rule", "## Why"):
        if h not in body: errors.append(f"{rel}: missing '{h}' section")
    if secretish.search(text): errors.append(f"{rel}: looks like it contains a secret")
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
print(f"{len(files)} lesson file(s) checked, {len(errors)} problem(s)")
sys.exit(1 if errors else 0)
PY
