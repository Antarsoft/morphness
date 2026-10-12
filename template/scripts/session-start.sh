#!/usr/bin/env bash
# SessionStart hook (.claude/settings.json): set up the toolchain, then install dependencies.
# morph-init fills the two commands below from project/STACK.md; an empty one is skipped.
# Never fails session start: no `set -e`, always exits 0.

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 0

TOOLCHAIN_SETUP='{{stack.toolchain_setup}}'
INSTALL_CMD='{{stack.install_cmd}}'

run_step() {
  local label="$1" cmd="$2"
  # Skip an empty command or one morph-init left unrendered.
  case "$cmd" in ''|*'{''{'*) return 0 ;; esac
  # eval in this shell so a toolchain setup (a version manager's `use`) changes PATH here.
  if ! eval "$cmd" >/dev/null 2>&1; then
    echo "session-start: $label failed; run it manually: $cmd"
  fi
}

start_path="$PATH"

run_step "toolchain setup" "$TOOLCHAIN_SETUP"

# Persist a changed PATH for later Bash calls in this session.
if [ "$PATH" != "$start_path" ] && [ -n "$CLAUDE_ENV_FILE" ]; then
  line="export PATH=\"$PATH\""
  grep -qxF "$line" "$CLAUDE_ENV_FILE" 2>/dev/null || echo "$line" >> "$CLAUDE_ENV_FILE"
fi

run_step "dependency install" "$INSTALL_CMD"

echo "session-start: done"
exit 0
