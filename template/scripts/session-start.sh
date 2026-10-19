#!/usr/bin/env bash
# SessionStart hook (.claude/settings.json): set up the toolchain, then install dependencies.
# morph-init fills the two commands below from project/STACK.md; an empty one is skipped.
# Each command is printed before it runs, runs under a timeout (MORPHNESS_START_TIMEOUT seconds,
# default 300; needs `timeout` or `gtimeout`, without one it runs unbounded and says so), and on
# failure the last lines of its output are printed. A package install of npm, pnpm, bun or yarn 1 gets
# --ignore-scripts, so a dependency's lifecycle scripts don't run at session start; to run them, write
# the flag yourself (`--ignore-scripts=false`) or run the install by hand.
# The install is skipped while the lockfiles and the command are unchanged since its last successful
# run in this clone (hash in the git folder; delete morphness-install.hash there to force it).
# Never fails session start: no `set -e`, always exits 0.

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 0

TOOLCHAIN_SETUP='{{stack.toolchain_setup}}'
INSTALL_CMD='{{stack.install_cmd}}'

LIMIT="${MORPHNESS_START_TIMEOUT:-300}"
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout)"
out_file="$(mktemp 2>/dev/null || echo /tmp/morphness-start.$$)"
trap 'rm -f "$out_file" "$out_file.path"' EXIT

# Package installs skip dependency lifecycle scripts where the manager supports the flag.
safe_install() {
  local cmd="$1"
  case "$cmd" in *ignore-scripts*) printf '%s' "$cmd"; return ;; esac
  case "$cmd" in
    npm\ ci*|npm\ install*|npm\ i|npm\ i\ *|pnpm\ install*|pnpm\ i|pnpm\ i\ *|bun\ install*|bun\ i|bun\ i\ *)
      printf '%s --ignore-scripts' "$cmd" ;;
    yarn|yarn\ install*)
      case "$(yarn --version 2>/dev/null)" in 1.*) printf '%s --ignore-scripts' "$cmd" ;; *) printf '%s' "$cmd" ;; esac ;;
    *) printf '%s' "$cmd" ;;
  esac
}

# Runs "$2" in a child bash under the timeout, output kept in $out_file; "$3" = path: afterwards PATH
# is taken over from the child, so a version manager's `use` still reaches the next step.
run_step() {
  local label="$1" cmd="$2" keep_path="$3" rc
  # Skip an empty command or one morph-init left unrendered.
  case "$cmd" in ''|*'{''{'*) return 0 ;; esac
  echo "session-start: $label: $cmd"
  if [ "$keep_path" = path ]; then
    set -- bash -c "$cmd"$'\n''rc=$?; printf %s "$PATH" > "$MORPHNESS_PATH_FILE"; exit $rc'
  else
    set -- bash -c "$cmd"
  fi
  export MORPHNESS_PATH_FILE="$out_file.path"
  if [ -n "$TIMEOUT_BIN" ]; then
    "$TIMEOUT_BIN" "$LIMIT" "$@" >"$out_file" 2>&1
  else
    echo "session-start: no timeout command found; $label runs without a time limit"
    "$@" >"$out_file" 2>&1
  fi
  rc=$?
  if [ "$rc" -ne 0 ]; then
    if [ "$rc" -eq 124 ]; then
      echo "session-start: $label timed out after ${LIMIT}s; run it manually: $cmd"
    else
      echo "session-start: $label failed (exit $rc); run it manually: $cmd"
    fi
    tail -n 15 "$out_file" | sed 's/^/  | /'
    return 1
  fi
  if [ "$keep_path" = path ] && [ -s "$out_file.path" ]; then PATH="$(cat "$out_file.path")"; export PATH; fi
}

start_path="$PATH"

run_step "toolchain setup" "$TOOLCHAIN_SETUP" path

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
elif run_step "dependency install" "$(safe_install "$INSTALL_CMD")" nopath && [ -n "$lock_hash" ] && [ -n "$hash_file" ]; then
  echo "$lock_hash" > "$hash_file" 2>/dev/null
fi

echo "session-start: done"
exit 0
