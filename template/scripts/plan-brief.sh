#!/usr/bin/env bash
# Gathers what the Technical Lead reads to write a full-mode or bug-mode plan into one file, so the plan step
# takes one script run and one Read instead of a print per doc (harness/TECHNICAL_LEAD.md § Full mode, step by
# step). It runs scripts/risk-check.sh on the files the change will touch and prints its answer. On
# `Mode: full` it writes the brief to _harness/features/<slug>/<version>/Plan/brief.md:
#   the risk check's output; harness/MODES.md § Full harness (--bug: and § Bug mode); .claude/rules/testing.md;
#   harness/SETUP.md § Effort per feature (less § Model of the Technical Lead) and § Where QA can run; the plan checklist's rules and the groups that always
#   run, with project/PLAN_CHECKLIST.md (--bug: § Planning and scope only); the plan template (--bug: bug-plan.md).
# The brief is a copy, made again on each run: it is never edited, and a one-line .gitignore next to it keeps it
# out of commits. Read it with the Read tool, which isn't cut at this size (a print this big would be).
# On `Mode: plain` it writes nothing, with or without --bug: the change runs alone, in light or small mode
# (AGENTS.md § Golden rules). It can stand in for the first risk-check.sh call: it prints the same answer.
# --version N (default 1) is the feature version, as in _harness/features/<slug>/<N>/; it says so when that
# version already has a plan.md.
# Exits as risk-check.sh does (2 when it can't decide, which reads as full), and 2 on a usage error.
# Usage: bash scripts/plan-brief.sh [--bug] [--version N] [--force full|plain] <slug> [file ...]

bug=0; version=1; force=(); slug=""; files=()
usage() { echo "usage: bash scripts/plan-brief.sh [--bug] [--version N] [--force full|plain] <slug> [file ...]" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --bug) bug=1; shift ;;
    --version) [ $# -ge 2 ] || usage; version="$2"; shift 2 ;;
    --version=*) version="${1#--version=}"; shift ;;
    --force) [ $# -ge 2 ] || usage; force=(--force "$2"); shift 2 ;;
    --force=*) force=(--force "${1#--force=}"); shift ;;
    --) shift; if [ -z "$slug" ] && [ $# -gt 0 ]; then slug="$1"; shift; fi; files+=("$@"); break ;;
    -*) echo "plan-brief: unknown option $1" >&2; usage ;;
    *) if [ -z "$slug" ]; then slug="$1"; else files+=("$1"); fi; shift ;;
  esac
done
case "$slug" in ''|*[!a-z0-9-]*|-*) echo "plan-brief: the slug must be lowercase letters, digits and hyphens, such as tag-filter (got '$slug')" >&2; usage ;; esac
case "$version" in ''|*[!0-9]*|0*) echo "plan-brief: --version takes a number from 1 (got '$version')" >&2; usage ;; esac
case "${force[1]:-full}" in full|plain) ;; *) echo "plan-brief: --force takes full or plain (got '${force[1]}')" >&2; usage ;; esac
if [ -n "${MORPH_AUTO_FEATURE:-}" ] && [ "$slug" != "$MORPH_AUTO_FEATURE" ]; then
  # an autonomous run checks the feature's records under its exact slug (harness/modules/autonomous/README.md)
  echo "plan-brief: this autonomous session builds '$MORPH_AUTO_FEATURE', so its folder is _harness/features/$MORPH_AUTO_FEATURE/: run bash scripts/plan-brief.sh $MORPH_AUTO_FEATURE (got '$slug')" >&2
  exit 2
fi
command -v python3 >/dev/null 2>&1 || { echo "plan-brief: python3 is missing" >&2; exit 2; }
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"

risk="$(bash "$here/risk-check.sh" "${force[@]}" -- "${files[@]}")"; rc=$?
printf '%s\n' "$risk"
mode_line="${risk%%$'\n'*}"
if [ "$rc" = 0 ] && [ "${mode_line#Mode: plain}" != "$mode_line" ]; then
  echo "plan-brief: no brief written: the change is plain, so it runs alone in light or small mode (AGENTS.md § Golden rules, Pick the mode first)."
  exit 0
fi

dir="$root/_harness/features/$slug/$version/Plan"
if [ -f "$dir/plan.md" ]; then
  echo "plan-brief: $slug version $version already has a plan ($dir/plan.md). Rerun with --version $((version + 1)) for a new version; the brief below is for editing the existing plan, never for overwriting an approved one."
fi
mkdir -p "$dir" || { echo "plan-brief: can't create $dir" >&2; exit 2; }
[ -f "$dir/.gitignore" ] || printf 'brief.md\n' > "$dir/.gitignore"
bug_repro="$(cd "$root" && . scripts/lib/config.sh 2>/dev/null && config_get mode.bug_repro)"
FILES="${files[*]}" RISK="$risk" BUG="$bug" BUG_REPRO="$bug_repro" python3 -I - "$root" "$dir/brief.md" "$slug" "$version" <<'PY' || exit 2
import os, re, subprocess, sys, datetime
root, out, slug, version = sys.argv[1:5]
bug = os.environ["BUG"] == "1"

def doc(rel):
    try:
        return open(os.path.join(root, rel), encoding="utf-8-sig", errors="replace").read()
    except OSError:
        return None

def sections(rel, *names):
    r = subprocess.run(["bash", os.path.join(root, "scripts/doc-section.sh"), os.path.join(root, rel), *names],
                       capture_output=True, text=True, cwd=root)
    text = "\n".join(l for l in r.stdout.splitlines() if not l.startswith("doc-section: this print is "))
    if r.returncode:
        text += f"\n\n(plan-brief: doc-section.sh exited {r.returncode} on {rel}: {r.stderr.strip()[:300]})"
    return text.strip() or f"(plan-brief: nothing printed from {rel})"

def body(rel):
    text = doc(rel)
    if text is None:
        return f"(plan-brief: {rel} is missing)"
    m = re.match(r"\A---\n.*?\n---\n", text, re.S)   # the rule file's paths: header
    return (text[m.end():] if m else text).strip()

try:
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True, cwd=root).stdout.strip()
except OSError:
    commit = ""
mode = "bug" if bug else "full"
template = "harness/templates/bug-plan.md" if bug else "harness/templates/plan.md"
parts = [
    f"# Plan brief: {slug} v{version} ({mode} mode)\n\n"
    f"Made by `scripts/plan-brief.sh` on {datetime.date.today().isoformat()} at commit `{commit or 'none'}`. "
    "A copy of the docs below, made again on each run and never committed: don't edit it. "
    f"Write the plan to `_harness/features/{slug}/{version}/Plan/plan.md` from the template at the end.",
    "## Risk check\n\nFiles: " + (", ".join(os.environ["FILES"].split()) or "none") + "\n\n```\n" + os.environ["RISK"].strip() + "\n```",
    sections("harness/MODES.md", *(["Full harness", "Bug mode"] if bug else ["Full harness"])),
    "## .claude/rules/testing.md\n\n" + body(".claude/rules/testing.md"),
    # the Technical Lead's own model is set at install, not per plan, so the brief leaves that subsection out
    re.sub(r"^### Model of the Technical Lead\n.*?(?=^#{2,3} |^---$|\Z)", "",
           sections("harness/SETUP.md", "Effort per feature", "Where QA can run"), flags=re.S | re.M),
    "# Plan checklist: the groups that always run\n\n"
    + ("Bug mode runs § Planning and scope only (harness/TECHNICAL_LEAD.md § Before asking for approval)."
       if bug else
       "Print only the other groups that apply, in one call, or none (harness/TECHNICAL_LEAD.md § Before asking for "
       "approval, its group index); these are here already.") + "\n\n"
    + sections("harness/PLAN_CHECKLIST.md", *(["How to use it", "Planning and scope"] if bug
                                               else ["How to use it", "Planning and scope", "Testing", "Process"]))
    + ("" if bug else "\n\n## project/PLAN_CHECKLIST.md\n\n" + re.sub(r"^(#+) ", r"##\1 ", (doc("project/PLAN_CHECKLIST.md") or "(plan-brief: project/PLAN_CHECKLIST.md is missing)").strip(), flags=re.M)),
    f"## Template: {template}\n\n" + (doc(template) or f"(plan-brief: {template} is missing)").strip(),
]
text = "\n\n---\n\n".join(parts) + "\n"
open(out, "w", encoding="utf-8").write(text)
print(f"Brief: _harness/features/{slug}/{version}/Plan/brief.md ({len(text)} characters). "
      "Read it with the Read tool in one call; it holds the mode section, testing.md, the effort and QA-run sections, "
      "the plan checklist groups that always run and the plan template, so don't print those again. "
      + (f"Next: bash scripts/handoff.sh {'fullstack-bug' if os.environ.get('BUG_REPRO') == 'fullstack' else 'qa-repro'} {slug}{'' if version == '1' else ' --version ' + version} once the plan is approved." if bug else
         f"Next: bash scripts/handoff.sh scout {slug}{'' if version == '1' else ' --version ' + version} prints the code scout's prompt, filled; launch the code-scout agent with it."))
PY
exit "$rc"
