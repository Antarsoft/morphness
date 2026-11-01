#!/usr/bin/env bash
# SessionStart hook (.claude/settings.json): set up the toolchain, then install dependencies.
# morph-init fills the two commands below from project/STACK.md; an empty one is skipped.
# Each command is printed before it runs, runs under a timeout (MORPHNESS_START_TIMEOUT seconds,
# default 300; with `timeout` or `gtimeout`, else perl, which stock macOS has; without any of them it
# runs unbounded and says so), and on failure the last lines of its output are printed. A package install of npm, pnpm, bun or yarn 1 gets
# --ignore-scripts, so a dependency's lifecycle scripts don't run at session start; to run them, write
# the flag yourself (`--ignore-scripts=false`) or run the install by hand.
# The install is skipped while the lockfiles and the command are unchanged since its last successful
# run in this clone (hash in the git folder; delete morphness-install.hash there to force it).
# The two commands are pinned per clone (the text, in the git folder: morphness-session-commands). The
# first run in a clone records them; a later run whose commands differ (a pulled branch changed them) runs
# nothing, prints the old and new commands, and waits: the owner confirms in the session, and only then
# `bash scripts/session-start.sh --accept` records and runs them. A fresh clone has no pin yet, so the
# first run there is covered by Claude Code's own trust prompt for the folder, not by this check.
# It checks that python3 on the hooks' PATH is a working Python 3.7 or later (the guard hook and the
# counting scripts need one) and says so when it isn't: a stub python3, such as macOS's before the
# Command Line Tools are installed or the Microsoft Store alias, passes `command -v` but not this.
# Never fails session start: no `set -e`, always exits 0.

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 0

TOOLCHAIN_SETUP='{{stack.toolchain_setup}}'
INSTALL_CMD='{{stack.install_cmd}}'

pin_file="$(git rev-parse --git-path morphness-session-commands 2>/dev/null)"
# Commands morph-init hasn't filled yet (a copy made by install.sh) are never recorded as the pin, or the
# first session after the install would hold the real ones as "changed". An existing pin is still compared.
unfilled=0
case "$TOOLCHAIN_SETUP$INSTALL_CMD" in *'{''{'*) unfilled=1 ;; esac
if [ -n "$pin_file" ] && [ -n "$TOOLCHAIN_SETUP$INSTALL_CMD" ]; then
  current="toolchain: $TOOLCHAIN_SETUP"$'\n'"install: $INSTALL_CMD"
  if [ "$1" = "--accept" ] || [ ! -f "$pin_file" ]; then
    [ "$unfilled" = 1 ] || printf '%s\n' "$current" > "$pin_file" 2>/dev/null
  elif [ "$(cat "$pin_file" 2>/dev/null)" != "$current" ]; then
    echo "session-start: NOT RUN. The toolchain and install commands changed since this clone last ran them."
    echo "  was:"; sed 's/^/    /' "$pin_file"
    echo "  now:"; printf '%s\n' "$current" | sed 's/^/    /'
    echo "  Show the owner both versions and ask in this chat whether to run the new commands. Only if the"
    echo "  owner says yes, run: bash scripts/session-start.sh --accept"
    exit 0
  fi
fi

LIMIT="${MORPHNESS_START_TIMEOUT:-300}"
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout)"
# Output and PATH go to a private folder (mktemp -d makes it mode 700), never to a guessable name in a
# shared /tmp. Without mktemp the folder goes in the git folder instead.
work="$(mktemp -d "${TMPDIR:-/tmp}/morphness-start.XXXXXX" 2>/dev/null)"
if [ -z "$work" ] || [ ! -d "$work" ]; then
  work="$(git rev-parse --git-path "morphness-start.$$" 2>/dev/null)"
  case "$work" in ''|/*) ;; *) work="$PWD/$work" ;; esac   # absolute: a step may cd elsewhere
  rm -rf "$work" 2>/dev/null
  if [ -z "$work" ] || ! (umask 077 && mkdir "$work") 2>/dev/null; then
    echo "session-start: no private temporary folder (mktemp -d failed, and no git folder); nothing was run"
    exit 0
  fi
fi
trap 'rm -rf "$work"' EXIT
out_file="$work/out"

# bounded <seconds> <command...>: runs the command, and after <seconds> stops it and everything it started
# (exit 124), like `timeout`. Stock macOS has no timeout or gtimeout, so perl does the same there.
bounded() {
  if [ -n "$TIMEOUT_BIN" ]; then "$TIMEOUT_BIN" "$@"; return; fi
  if ! command -v perl >/dev/null 2>&1; then shift; "$@"; return; fi
  perl -e '
    my %unit = ("" => 1, s => 1, m => 60, h => 3600, d => 86400);
    my $spec = shift @ARGV;
    my ($n, $u) = $spec =~ /^(\d+(?:\.\d*)?|\.\d+)([smhd]?)$/
      or do { print STDERR "session-start: invalid time limit: $spec\n"; exit 125 };
    my $secs = $n * $unit{$u};
    my $pid = fork;
    defined $pid or do { print STDERR "session-start: cannot start: $!\n"; exit 125 };
    if (!$pid) { setpgrp(0, 0); exec { $ARGV[0] } @ARGV; print STDERR "session-start: cannot run $ARGV[0]: $!\n"; exit 127 }
    setpgrp($pid, $pid);
    # A TERM, INT or HUP sent to this wrapper (the hook being stopped) goes on to the step it runs.
    for my $sig (qw(TERM INT HUP)) { $SIG{$sig} = sub { kill $sig, -$pid } }
    my $late = 0;
    $SIG{ALRM} = sub { kill($late++ ? "KILL" : "TERM", -$pid); alarm 5 };
    alarm(int($secs) + ($secs > int($secs) ? 1 : 0)) if $secs > 0;
    while (waitpid($pid, 0) == -1 && $!{EINTR}) {}
    alarm 0;
    exit 124 if $late;
    exit($? & 127 ? 128 + ($? & 127) : $? >> 8);
  ' "$@"
}

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
  export MORPHNESS_PATH_FILE="$work/path"
  if [ -n "$TIMEOUT_BIN" ] || command -v perl >/dev/null 2>&1; then
    bounded "$LIMIT" "$@" >"$out_file" 2>&1
  else
    echo "session-start: no timeout, gtimeout or perl found; $label runs without a time limit"
    "$@" >"$out_file" 2>&1
  fi
  rc=$?
  if [ "$rc" -ne 0 ]; then
    if [ "$rc" -eq 124 ]; then
      echo "session-start: $label timed out after ${LIMIT}s; run it manually: $cmd"
    else
      echo "session-start: $label failed (exit $rc); run it manually: $cmd"
    fi
    # $(…) drops the trailing newline, or its absence, so the next message always starts on its own line.
    [ -s "$out_file" ] && printf '%s\n' "$(tail -n 15 "$out_file" | sed 's/^/  | /')"
    return 1
  fi
  if [ "$keep_path" = path ] && [ -s "$work/path" ]; then PATH="$(cat "$work/path")"; export PATH; fi
}

# The guard and the counting scripts need a working Python 3.7 or later. Checked before the toolchain step
# changes PATH: hooks run with the PATH Claude Code gives them, which is this one.
if ! command -v python3 >/dev/null 2>&1; then
  echo "session-start: python3 is not installed. scripts/guard.sh blocks every tool call until it is (or until"
  echo "  harness.config.yml sets guard.fail_open: true), and the cost, evidence and learned-rules scripts don't"
  echo "  run. Install Python 3.7 or later."
elif [ "$(bounded 20 python3 -I -c 'import sys; print(sys.version_info >= (3, 7))' 2>/dev/null)" != True ]; then
  echo "session-start: $(command -v python3) is not a working Python 3.7 or later (a stub or an old version),"
  echo "  so scripts/guard.sh can't check tool calls (it blocks every call, or lets them through unchecked) and"
  echo "  the cost, evidence and learned-rules scripts don't work. Install Python 3.7 or later, first on PATH."
fi

start_path="$PATH"

run_step "toolchain setup" "$TOOLCHAIN_SETUP" path

# Persist a changed PATH for later Bash calls in this session, quoted so that a `"`, `$` or backtick in
# it stays text when the file is sourced.
if [ "$PATH" != "$start_path" ] && [ -n "$CLAUDE_ENV_FILE" ]; then
  line="export PATH=$(printf '%q' "$PATH")"
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
