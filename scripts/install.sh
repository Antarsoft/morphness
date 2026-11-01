#!/usr/bin/env bash
# Copy the Morphness template into a target repository without overwriting anything.
# Usage: scripts/install.sh [--dry-run] [--merge] <target-repo>
# After copying, open Claude Code in the target and run /morph-init to answer the setup questions
# and fill in the placeholders. Files that already exist are kept and listed; morph-init merges them.
#
# The install either ends with every kit file in place or stops before copying and says why:
# - a kit script path (scripts/guard.sh, scripts/session-start.sh, ...) already holds a different file,
#   which the hooks would run in place of the kit's;
# - .claude/settings.json exists without the guard hook (morph-init merges it: it passes --merge);
# - the repo's .gitignore would leave kit files such as .claude/settings.json out of every commit;
# - a file stands where the kit needs a folder.
# Files are copied into a staging folder first and moved into place one by one, with harness.config.yml
# (the "copied, not set up yet" marker) last, so a copy that stops half way is finished by running the
# script again: it copies only what is missing.
set -euo pipefail

usage() { echo "usage: $0 [--dry-run] [--merge] <target-repo>" >&2; exit 2; }
DRY=0; MERGE=0; TARGET=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --merge) MERGE=1 ;;            # morph-init: it writes .claude/settings.json itself, last (render.md § 6b)
    --no-clobber) ;;               # accepted for clarity; never overwriting is the only mode
    -*) usage ;;
    *) [ -z "$TARGET" ] || usage; TARGET="$arg" ;;
  esac
done
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then usage; fi
SRC="$(cd "$(dirname "$0")/.." && pwd)/template"
TARGET="$(cd "$TARGET" && pwd)"

REPAIR=0   # harness.config.yml with the kit's placeholders: an earlier copy; fill in what it left out
# (only the kit's keys count: a filled-in config may quote a project's own {{name}} text)
if [ -f "$TARGET/harness.config.yml" ] && grep -qE '\{\{ *(project|human|morphness)\.' "$TARGET/harness.config.yml"; then
  REPAIR=1
elif [ -f "$TARGET/harness.config.yml" ]; then
  if [ ! -f "$TARGET/.claude/settings.json" ] || ! grep -q 'scripts/guard.sh' "$TARGET/.claude/settings.json"; then
    echo "Morphness is set up in $TARGET but .claude/settings.json doesn't run the guard yet (/morph-init stopped before its last file). Run /morph-init there: it finishes that step." >&2
  elif git -C "$TARGET" rev-parse --verify -q HEAD >/dev/null 2>&1 && [ -z "$(git -C "$TARGET" ls-files harness.config.yml)" ]; then
    echo "Morphness is set up in $TARGET but not committed yet (/morph-init stopped before its end). Run /morph-init there: it runs the last checks and commits." >&2
  else
    echo "Morphness is already installed in $TARGET (harness.config.yml exists). Run /morph-update there for upstream changes, or /morph-doctor for a health check." >&2
  fi
  exit 1
fi

# (a harness/SETUP.md identical to the kit's is from a copy of this script that stopped, not an earlier harness)
if [ "$REPAIR" = 0 ] && { [ -f "$TARGET/HARNESS_VERSION" ] || \
     { [ -d "$TARGET/_harness" ] && [ -f "$TARGET/harness/SETUP.md" ] && ! cmp -s "$SRC/harness/SETUP.md" "$TARGET/harness/SETUP.md"; }; }; then
  echo "$TARGET already runs an earlier harness (harness/ and _harness/ exist). Copying without" >&2
  echo "overwriting would skip every kit file. Run /morph-init there: it migrates the earlier harness." >&2
  exit 1
fi

# Tools the installed kit calls. A missing one never stops the install; it is named here and in /morph-doctor.
missing=()
need() {  # need <tool> <what breaks without it>
  command -v "$1" >/dev/null 2>&1 || missing+=("$1: $2")
}
need git "the branch, PR and release process (the installed scripts call git throughout)"
need python3 "scripts/guard.sh blocks every tool call (unless harness.config.yml sets guard.fail_open: true), and the cost, evidence and learned-rules scripts do not run (the prune counter runs without its trial and rule-tag counts)"
# A python3 that is a stub (macOS before the Command Line Tools, the Microsoft Store alias) or older than 3.7
# passes command -v but can't run the guard.
if command -v python3 >/dev/null 2>&1 && [ "$(python3 -I -c 'import sys; print(sys.version_info >= (3, 7))' 2>/dev/null)" != True ]; then
  missing+=("python3: $(command -v python3) is not a working Python 3.7 or later, so scripts/guard.sh can't check tool calls (it blocks every call, or lets them through unchecked); install Python 3.7 or later")
fi
need awk "scripts/lib/config.sh reads harness.config.yml with awk: without it every setting reads as empty, so scripts/guard.sh protects no branch and the other scripts run on their defaults or stop with a not-measured line"
need perl "removing a module (/morph-module remove) cannot strip its marked text, and scripts/session-start.sh has no time limit where there is no timeout command (stock macOS)"
for tool in grep sed sort tr wc; do
  need "$tool" "scripts/prune-counter.sh stops with a not-measured line, and without grep, sort or tr scripts/guard.sh protects no branch"
done

# ---- plan: what to copy, what is already there, and whether anything stops the install ----
if ! command -v cmp >/dev/null 2>&1; then   # tells the kit's own files (from a copy that stopped) from the user's
  echo "Morphness: stopped, nothing was copied: cmp is missing (it comes with diffutils or busybox); install it and run install.sh again." >&2
  exit 1
fi
exists() { [ -e "$1" ] || [ -L "$1" ]; }   # a dangling link counts: cp would refuse to write through it
LINKED=0   # AGENTS.md and CLAUDE.md are one file (a link either way): morph-init writes the kit text into it once
links_to() {  # links_to <name> <other>: <name> is a symlink whose text names <other>, even when <other> is missing
  [ -L "$TARGET/$1" ] || return 1
  case "$(readlink "$TARGET/$1")" in "$2"|"./$2"|"$TARGET/$2") return 0 ;; esac
  return 1
}
if links_to AGENTS.md CLAUDE.md || links_to CLAUDE.md AGENTS.md; then LINKED=1; fi
if [ -L "$TARGET/AGENTS.md" ] && [ -L "$TARGET/CLAUDE.md" ] && [ "$(readlink "$TARGET/AGENTS.md")" = "$(readlink "$TARGET/CLAUDE.md")" ]; then LINKED=1; fi
if [ -e "$TARGET/AGENTS.md" ] && [ "$TARGET/AGENTS.md" -ef "$TARGET/CLAUDE.md" ]; then LINKED=1; fi

all=(); wired() {  # wired <settings.json>: a PreToolUse hook command runs scripts/guard.sh (text search without python3)
  if python3 -I -c 'import sys; sys.exit(0 if sys.version_info >= (3, 7) else 1)' 2>/dev/null; then
    python3 -I - "$1" <<'PY' 2>/dev/null
import json, sys
try:
    entries = json.load(open(sys.argv[1], encoding="utf-8-sig")).get("hooks", {}).get("PreToolUse", [])
    sys.exit(0 if any("scripts/guard.sh" in str(h.get("command", "")) for e in entries for h in e.get("hooks", [])) else 1)
except Exception:
    sys.exit(1)
PY
  else
    grep -q 'scripts/guard\.sh' "$1" 2>/dev/null
  fi
}
copy=(); kept=(); present=0; stops=(); own_scripts=(); bad_parents=(); linked_parents=(); settings_kept=0; settings_left=0
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  all+=("$rel")
  dest="$TARGET/$rel"
  parent="$(dirname "$rel")"
  while [ "$parent" != . ]; do
    if [ -L "$TARGET/$parent" ]; then   # files would land wherever the link points, outside git's view
      case " ${linked_parents[*]-} " in *" $parent "*) ;; *) linked_parents+=("$parent") ;; esac
      break
    fi
    if exists "$TARGET/$parent" && [ ! -d "$TARGET/$parent" ]; then
      case " ${bad_parents[*]-} " in *" $parent "*) ;; *) bad_parents+=("$parent") ;; esac
      break
    fi
    parent="$(dirname "$parent")"
  done
  if [ "$LINKED" = 1 ] && { [ "$rel" = AGENTS.md ] || [ "$rel" = CLAUDE.md ]; }; then continue; fi
  if exists "$dest"; then
    if [ ! -L "$dest" ] && [ -f "$dest" ] && cmp -s "$f" "$dest"; then present=$((present + 1)); continue; fi
    kept+=("$rel")
    case "$rel" in
      # The hooks and the agents run these paths: a different file there acts as the kit's. After an
      # earlier copy (REPAIR) morph-init may have filled in a script's placeholders (session-start.sh).
      scripts/*)
        if [ "$REPAIR" = 0 ] || ! grep -qE '\{\{ *[a-z][a-z0-9_.-]* *\}\}' "$f"; then own_scripts+=("$rel"); fi ;;
      .claude/settings.json) wired "$dest" || settings_kept=1 ;;
    esac
    continue
  fi
  # morph-init writes the settings itself once the rest is in place: the guard turns on with the last file
  if [ "$MERGE" = 1 ] && [ "$rel" = .claude/settings.json ]; then settings_left=1; continue; fi
  copy+=("$rel")
done < <(find "$SRC" -type f -print0 | sort -z)

if [ "${#bad_parents[@]}" -gt 0 ]; then
  stops+=("These are files where the kit needs a folder of the same name: ${bad_parents[*]}. Move or rename them, then run install.sh again.")
fi
if [ "${#linked_parents[@]}" -gt 0 ]; then
  stops+=("These kit folders are symbolic links, so the kit's files would land wherever they point and git would not track them: ${linked_parents[*]}. Make them real folders, then run install.sh again.")
fi
if [ "${#own_scripts[@]}" -gt 0 ]; then
  stops+=("These kit script paths already hold your own files: ${own_scripts[*]}. The hooks and the agents run these paths, so your file would stand in for the kit's (scripts/guard.sh would be the guard). Rename or move yours, then run install.sh again; install.sh never changes them.")
fi
if [ "$settings_kept" = 1 ] && [ "$MERGE" = 0 ]; then
  stops+=(".claude/settings.json exists and does not run scripts/guard.sh. install.sh never overwrites it, so the guard would not be wired. Run /morph-init in $TARGET instead: it merges the guard hook into your settings and copies the files with this script's --merge option.")
fi
if [ "${#linked_parents[@]}" -eq 0 ] && command -v git >/dev/null 2>&1 && git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ignored=(); ignore_rc=0
  ignore_out="$(cd "$TARGET" && printf '%s\n' "${all[@]}" | git check-ignore --stdin 2>/dev/null)" || ignore_rc=$?
  # the files the guard rests on first, so they are named even when many are ignored
  while IFS= read -r rel; do [ -z "$rel" ] || ignored+=("$rel"); done < <(printf '%s\n' "$ignore_out" \
    | awk '/^(\.claude\/settings\.json|scripts\/guard\.sh|scripts\/lib\/config\.sh|harness\.config\.yml)$/ { print; next } { rest[++n] = $0 } END { for (i = 1; i <= n; i++) print rest[i] }')
  if [ "$ignore_rc" -gt 1 ]; then   # 1 = nothing ignored; anything else means git could not say
    stops+=("git could not say whether the repo's .gitignore leaves kit files out (git check-ignore exited $ignore_rc). Run \`git check-ignore -v .claude/settings.json scripts/guard.sh\` in $TARGET to see why, then run install.sh again.")
  elif [ "${#ignored[@]}" -gt 0 ]; then
    more=""; [ "${#ignored[@]}" -le 8 ] || more=" and $(( ${#ignored[@]} - 8 )) more"
    stops+=("The repo's .gitignore leaves these kit files out of every commit, so teammates and CI would run without them (the guard lives in .claude/settings.json and scripts/): ${ignored[*]:0:8}$more. Change the rule that matches (\`git check-ignore -v <path>\` names it), or add a line that takes the kit's folder back in, such as \`!scripts/lib/\` after a \`lib/\` rule; to keep personal Claude Code settings out, ignore only .claude/settings.local.json. Then run install.sh again.")
  fi
fi
if [ "${#stops[@]}" -gt 0 ]; then
  echo "Morphness: stopped, nothing was copied into $TARGET." >&2
  for s in "${stops[@]}"; do echo "- $s" >&2; done
  exit 1
fi

if [ "${#copy[@]}" -eq 0 ] && [ "$REPAIR" = 1 ] && [ "$MERGE" = 0 ]; then
  echo "Morphness files are already copied into $TARGET but not set up yet. Run /morph-init there." >&2
  exit 1
fi

# ---- copy: stage every file, then move them into place with the marker last ----
ordered=(); marker=""
for rel in ${copy[@]+"${copy[@]}"}; do
  if [ "$rel" = harness.config.yml ]; then marker="$rel"; else ordered+=("$rel"); fi
done
[ -z "$marker" ] || ordered+=("$marker")

if [ "$DRY" = 1 ]; then
  for rel in ${ordered[@]+"${ordered[@]}"}; do echo "would copy $rel"; done
else
  find "$TARGET" -maxdepth 1 -type d -name '.morphness-staging.*' -exec rm -rf {} +   # left by a killed run
  STAGE="$(mktemp -d "$TARGET/.morphness-staging.XXXXXX")"
  moved=0; done_copy=0
  on_exit() {
    rm -rf "$STAGE"
    if [ "$done_copy" = 0 ]; then
      echo "Morphness: the copy stopped after $moved of ${#ordered[@]} file(s). harness.config.yml, which marks the copy as done, is not in place, so fix the error above and run install.sh again: it copies only what is missing." >&2
    fi
  }
  trap on_exit EXIT
  for rel in ${ordered[@]+"${ordered[@]}"}; do
    mkdir -p "$STAGE/$(dirname "$rel")"
    cp -p "$SRC/$rel" "$STAGE/$rel"
    case "$rel" in scripts/*/*) ;; scripts/*.sh) chmod +x "$STAGE/$rel" ;; esac   # only files this run copies
  done
  for rel in ${ordered[@]+"${ordered[@]}"}; do
    mkdir -p "$(dirname "$TARGET/$rel")"
    mv "$STAGE/$rel" "$TARGET/$rel"
    moved=$((moved + 1))
  done
  done_copy=1
fi

verb="$( [ "$DRY" = 1 ] && echo 'to copy' || echo 'copied' )"
[ "$REPAIR" = 1 ] && verb="$( [ "$DRY" = 1 ] && echo 'to restore' || echo 'restored' ) (an earlier copy left them out)"
if [ "${#ordered[@]}" -eq 0 ]; then
  echo "Morphness: nothing to copy into $TARGET; every kit file is already there."
else
  echo "Morphness: ${#ordered[@]} file(s) $verb into $TARGET"
fi
[ "$present" = 0 ] || echo "$present file(s) were already in place, identical to the kit's."
if [ "${#kept[@]}" -gt 0 ]; then
  echo "Kept (already exist; /morph-init merges these):"
  printf '  %s\n' "${kept[@]}"
fi
if [ "$LINKED" = 1 ]; then
  echo "Kept: AGENTS.md and CLAUDE.md are one file (a link); /morph-init adds the kit's text to it once."
fi
if [ "$settings_left" = 1 ]; then
  echo "Left for /morph-init: .claude/settings.json (it writes the file last, which turns the guard on)."
fi
if [ "$settings_kept" = 1 ]; then
  echo
  echo "Not wired yet: your .claude/settings.json was kept, so scripts/guard.sh checks nothing until /morph-init merges its hook into that file."
fi
if [ "${#missing[@]}" -gt 0 ]; then
  echo
  echo "Missing tools (install them; /morph-doctor checks this again):"
  printf '  %s\n' "${missing[@]}"
fi
[ "$MERGE" = 1 ] && exit 0
cat <<MSG

Next: open Claude Code in $TARGET and run /morph-init
(no plugin? paste: "Follow $(cd "$SRC/.." && pwd)/skills/morph-init/SKILL.md to set up the harness here")
MSG
