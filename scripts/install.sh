#!/usr/bin/env bash
# Copy the Morphness template into a target repository without overwriting anything.
# Usage: scripts/install.sh [--dry-run] <target-repo>
# After copying, open Claude Code in the target and run /morph-init to answer the setup questions
# and fill in the placeholders. Files that already exist are skipped and listed; morph-init merges them.
set -euo pipefail

DRY=0
if [ "${1:-}" = "--dry-run" ]; then DRY=1; shift; fi
[ "${1:-}" = "--no-clobber" ] && shift   # accepted for clarity; never overwriting is the only mode
TARGET="${1:-}"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "usage: $0 [--dry-run] <target-repo>" >&2; exit 2
fi
SRC="$(cd "$(dirname "$0")/.." && pwd)/template"
TARGET="$(cd "$TARGET" && pwd)"

if [ -f "$TARGET/harness.config.yml" ] && grep -q '{{' "$TARGET/harness.config.yml"; then
  echo "Morphness files are already copied into $TARGET but not set up yet. Run /morph-init there." >&2
  exit 1
fi
if [ -f "$TARGET/harness.config.yml" ]; then
  echo "Morphness is already installed in $TARGET (harness.config.yml exists). Run /morph-update there for upstream changes, or /morph-doctor for a health check." >&2
  exit 1
fi

if [ ! -f "$TARGET/harness.config.yml" ] && { [ -f "$TARGET/HARNESS_VERSION" ] || \
     { [ -d "$TARGET/_harness" ] && [ -f "$TARGET/harness/SETUP.md" ]; }; }; then
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

copied=0; skipped=()
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  dest="$TARGET/$rel"
  if [ -e "$dest" ]; then skipped+=("$rel"); continue; fi
  if [ "$DRY" = 1 ]; then echo "would copy $rel"; else
    mkdir -p "$(dirname "$dest")"; cp -p "$f" "$dest"
  fi
  copied=$((copied + 1))
done < <(find "$SRC" -type f -print0 | sort -z)

[ "$DRY" = 1 ] || chmod +x "$TARGET/scripts/session-start.sh" "$TARGET/scripts/prune-counter.sh" "$TARGET/scripts/learned-rules.sh" "$TARGET/scripts/feature-cost.sh" "$TARGET/scripts/evidence.sh" "$TARGET/scripts/guard.sh" 2>/dev/null || true

echo "Morphness: $copied file(s) $( [ "$DRY" = 1 ] && echo 'to copy' || echo 'copied' ) into $TARGET"
if [ "${#skipped[@]}" -gt 0 ]; then
  echo "Skipped (already exist; /morph-init merges these):"
  printf '  %s\n' "${skipped[@]}"
fi
if [ "${#missing[@]}" -gt 0 ]; then
  echo
  echo "Missing tools (install them; /morph-doctor checks this again):"
  printf '  %s\n' "${missing[@]}"
fi
cat <<MSG

Next: open Claude Code in $TARGET and run /morph-init
(no plugin? paste: "Follow $(cd "$SRC/.." && pwd)/skills/morph-init/SKILL.md to set up the harness here")
MSG
