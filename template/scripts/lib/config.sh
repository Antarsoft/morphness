#!/usr/bin/env bash
# Shared reader for harness.config.yml, sourced by the scripts in scripts/. Reads block style
# (`branches:` then indented `integration: dev`) and one-line flow maps (`branches: { integration: dev }`)
# alike. List items (`- ...`) aren't read by config_get (config_env_branches below reads the environments).
# A `#` starts a comment only after a space or at the start.
# Usage: . scripts/lib/config.sh; config_get loop.prune_every   (prints nothing when the key is missing)

config_get() {
  awk -v want="$1" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function unquote(s) {
      s = trim(s)
      if (s ~ /^".*"$/ || s ~ /^\047.*\047$/) s = substr(s, 2, length(s) - 2)
      return s
    }
    function emit(key, value) { if (key == want) { print unquote(value); exit } }
    {
      line = $0
      sub(/(^|[ \t])#.*$/, "", line)
      if (line ~ /^[ \t]*$/) next
      match(line, /^[ \t]*/); indent = RLENGTH
      rest = substr(line, indent + 1)
      if (rest ~ /^-/) next
      if (!match(rest, /^[A-Za-z0-9_.-]+[ \t]*:/)) next
      key = rest; sub(/[ \t]*:.*$/, "", key)
      value = trim(substr(rest, RLENGTH + 1))
      while (depth > 0 && indent <= indents[depth]) depth--
      path = ""
      for (i = 1; i <= depth; i++) path = path keys[i] "."
      path = path key
      if (value == "") { depth++; indents[depth] = indent; keys[depth] = key; next }
      if (value ~ /^\{.*\}$/) {
        count = split(substr(value, 2, length(value) - 2), pairs, ",")
        for (j = 1; j <= count; j++) {
          colon = index(pairs[j], ":")
          if (colon) emit(path "." trim(substr(pairs[j], 1, colon - 1)), substr(pairs[j], colon + 1))
        }
        next
      }
      emit(path, value)
    }
  ' "${2:-harness.config.yml}" 2>/dev/null
}

# Prints the branch of every entry under `environments:`, one per line. Both list styles work:
#   - { name: staging, branch: staging, deploy: host }
#   - name: staging
#     branch: staging
config_env_branches() {
  awk '
    { line = $0; sub(/(^|[ \t])#.*$/, "", line) }
    line ~ /^environments[ \t]*:/ { inside = 1; next }
    inside && line ~ /^[A-Za-z0-9_-]+[ \t]*:/ { inside = 0 }
    inside && match(line, /(^|[ \t{,-])branch[ \t]*:[ \t]*[^ \t,}]+/) {
      v = substr(line, RSTART, RLENGTH); sub(/^.*branch[ \t]*:[ \t]*/, "", v); gsub(/["\047]/, "", v); print v
    }
  ' "${1:-harness.config.yml}" 2>/dev/null
}
