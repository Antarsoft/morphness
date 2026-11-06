#!/usr/bin/env bash
# Runs a command (usually `claude -p ...`) with a clean environment, so a headless try of a kit change
# doesn't inherit the Claude Code session it was started from: that session's memory, settings, plugins,
# commit trailers and git config otherwise leak into the run (tests/known-gaps.md). CONTRIBUTING.md says
# when to use it.
#
# What the command gets: PATH, TERM, LANG, LC_ALL, TZ; every ANTHROPIC_* variable (sign-in and API base); the
# proxy and CA variables (HTTPS_PROXY, HTTP_PROXY, NO_PROXY in both cases, SSL_CERT_FILE, NODE_EXTRA_CA_CERTS,
# REQUESTS_CA_BUNDLE, GIT_SSL_CAINFO); a fresh HOME and CLAUDE_CONFIG_DIR (an empty folder, so no memory,
# settings or plugins); and CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0, so -p waits for background subagents.
# Nothing else: no CLAUDE_* or CLAUDECODE variable, no GIT_CONFIG_* override, no tokens.
#
# Usage: bash scripts/headless.sh [--home DIR] [--keep VAR]... [--set VAR=VALUE]... -- <command> [args...]
#   --home DIR       use DIR as HOME (CLAUDE_CONFIG_DIR is DIR/.claude); default: a new folder under $TMPDIR
#   --keep VAR       pass VAR through as it is (for example GH_TOKEN for a run that opens a PR)
#   --set VAR=VALUE  set VAR (for example GIT_AUTHOR_NAME=...; the fresh HOME has no git identity)
# The command runs in the current folder. Exit: the command's own; 2 on a usage error.

set -u
home="" keep=() set=()
while [ $# -gt 0 ]; do
  case "$1" in
    --home) [ $# -ge 2 ] || { echo "headless.sh: --home needs a folder" >&2; exit 2; }; home=$2; shift 2 ;;
    --keep) [ $# -ge 2 ] || { echo "headless.sh: --keep needs a variable name" >&2; exit 2; }; keep+=("$2"); shift 2 ;;
    --set)  [ $# -ge 2 ] && [ "${2#*=}" != "$2" ] || { echo "headless.sh: --set needs VAR=VALUE" >&2; exit 2; }; set+=("$2"); shift 2 ;;
    --) shift; break ;;
    *) echo "headless.sh: unknown option $1 (put the command after --)" >&2; exit 2 ;;
  esac
done
[ $# -ge 1 ] || { echo "usage: bash scripts/headless.sh [--home DIR] [--keep VAR]... [--set VAR=VALUE]... -- <command> [args...]" >&2; exit 2; }

if [ -z "$home" ]; then
  home=$(mktemp -d "${TMPDIR:-/tmp}/morph-headless.XXXXXX") || { echo "headless.sh: cannot make a fresh HOME" >&2; exit 2; }
fi
mkdir -p "$home/.claude" || { echo "headless.sh: cannot create $home/.claude" >&2; exit 2; }

pass=(PATH="$PATH" HOME="$home" CLAUDE_CONFIG_DIR="$home/.claude" CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0)
for v in TERM LANG LC_ALL TZ HTTPS_PROXY HTTP_PROXY NO_PROXY https_proxy http_proxy no_proxy \
         SSL_CERT_FILE NODE_EXTRA_CA_CERTS REQUESTS_CA_BUNDLE GIT_SSL_CAINFO; do
  [ -n "${!v+x}" ] && pass+=("$v=${!v}")
done
while IFS= read -r v; do
  pass+=("$v=${!v}")
done < <(compgen -e | grep '^ANTHROPIC_')
for v in "${keep[@]+"${keep[@]}"}"; do
  case "$v" in *[!A-Za-z0-9_]*|"") echo "headless.sh: --keep $v is not a variable name" >&2; exit 2 ;; esac
  [ -n "${!v+x}" ] && pass+=("$v=${!v}")
done
pass+=("${set[@]+"${set[@]}"}")

exec env -i "${pass[@]}" "$@"
