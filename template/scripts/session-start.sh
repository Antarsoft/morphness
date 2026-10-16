#!/usr/bin/env bash
# SessionStart hook (.claude/settings.json): set up the toolchain, then install dependencies.
# morph-init fills the two commands below from project/STACK.md; an empty one is skipped.
# The install is skipped while the lockfiles and the command are unchanged since its last successful
# run in this clone (hash in the git folder; delete morphness-install.hash there to force it).
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
    return 1
  fi
}

start_path="$PATH"

run_step "toolchain setup" "$TOOLCHAIN_SETUP"

# Persist a changed PATH for later Bash calls in this session.
if [ "$PATH" != "$start_path" ] && [ -n "$CLAUDE_ENV_FILE" ]; then
  line="export PATH=\"$PATH\""
  grep -qxF "$line" "$CLAUDE_ENV_FILE" 2>/dev/null || echo "$line" >> "$CLAUDE_ENV_FILE"
fi

# Lockfiles at the repo root, any stack; with none, the install runs every session.
LOCKFILES="package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb
  poetry.lock uv.lock Pipfile.lock pdm.lock Cargo.lock go.sum Gemfile.lock composer.lock mix.lock
  pubspec.lock Package.resolved packages.lock.json gradle.lockfile flake.lock"
hash_file="$(git rev-parse --git-path morphness-install.hash 2>/dev/null)"
lock_hash=""
for f in $LOCKFILES; do
  [ -f "$f" ] && lock_hash="$lock_hash $f $(cksum < "$f")"
done
[ -n "$lock_hash" ] && lock_hash="$(printf '%s\n%s' "$INSTALL_CMD" "$lock_hash" | cksum)"

if [ -n "$lock_hash" ] && [ -n "$hash_file" ] && [ "$(cat "$hash_file" 2>/dev/null)" = "$lock_hash" ]; then
  echo "session-start: dependencies unchanged since the last install; skipped"
elif run_step "dependency install" "$INSTALL_CMD" && [ -n "$lock_hash" ] && [ -n "$hash_file" ]; then
  echo "$lock_hash" > "$hash_file" 2>/dev/null
fi

echo "session-start: done"
exit 0
