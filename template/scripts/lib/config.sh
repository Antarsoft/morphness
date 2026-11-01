#!/usr/bin/env bash
# Shared reader for harness.config.yml, sourced by the scripts in scripts/. Reads block style
# (`branches:` then indented `integration: dev`) and one-line flow maps (`branches: { integration: dev }`)
# alike. List items (`- ...`) aren't read by config_get (config_env_branches below reads the environments).
# A `#` starts a comment only after a space or at the start. A UTF-8 byte order mark, Windows line endings
# (CRLF), quoted keys (`"branches":`) and an anchor before a value (`production: &p main`) are read too.
# The byte order mark is stripped as "anything before the first key character on line 1", so an awk that reads
# the file as UTF-8 and one that reads bytes both drop it.
# Usage: . scripts/lib/config.sh; config_get loop.prune_every   (prints nothing when the key is missing)
#        config_get_all branches.production                    (every value, when the key is repeated)

# _config_read <key> <file> <all>: the awk reader behind config_get and config_get_all.
_config_read() {
  LC_ALL=C awk -v want="$1" -v all="$3" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function unquote(s) {
      s = trim(s)
      if (s ~ /^".*"$/ || s ~ /^\047.*\047$/) s = substr(s, 2, length(s) - 2)
      return s
    }
    function emit(key, value) {
      if (key != want) return
      value = trim(value)
      sub(/^&[^ \t]+[ \t]+/, "", value)
      print unquote(value)
      if (!all) exit
    }
    {
      line = $0
      if (NR == 1) sub(/^[^#"\047A-Za-z0-9_ \t-]+/, "", line)   # a byte order mark, however this awk reads it
      sub(/\r$/, "", line)
      sub(/(^|[ \t])#.*$/, "", line)
      if (line ~ /^[ \t]*$/) next
      match(line, /^[ \t]*/); indent = RLENGTH
      rest = substr(line, indent + 1)
      if (rest ~ /^-/) next
      if (!match(rest, /^("[A-Za-z0-9_.-]+"|\047[A-Za-z0-9_.-]+\047|[A-Za-z0-9_.-]+)[ \t]*:/)) next
      key = rest; sub(/[ \t]*:.*$/, "", key); key = unquote(key)
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
          if (colon) emit(path "." unquote(substr(pairs[j], 1, colon - 1)), substr(pairs[j], colon + 1))
        }
        next
      }
      emit(path, value)
    }
  ' "$2" 2>/dev/null
}

config_get() {
  _config_read "$1" "${2:-harness.config.yml}" 0
}

config_get_all() {
  _config_read "$1" "${2:-harness.config.yml}" 1
}

# Prints the branch of every entry under `environments:`, one per line. Every list style works:
#   - { name: staging, branch: staging, deploy: host }
#   - name: staging
#     branch: staging
#   environments: [ { name: staging, branch: staging }, { name: production, branch: main } ]
config_env_branches() {
  LC_ALL=C awk '
    {
      line = $0
      if (NR == 1) sub(/^[^#"\047A-Za-z0-9_ \t-]+/, "", line)
      sub(/\r$/, "", line)
      sub(/(^|[ \t])#.*$/, "", line)
    }
    match(tolower(line), /^("environments"|\047environments\047|environments)[ \t]*:/) {
      inside = 1
      line = substr(line, RLENGTH + 1)   # a one-line flow list carries its entries on this line
    }
    !inside { next }
    line ~ /^("[A-Za-z0-9_-]+"|\047[A-Za-z0-9_-]+\047|[A-Za-z0-9_-]+)[ \t]*:/ { inside = 0; next }
    {
      # An anchor before the value (`branch: &s staging`) is dropped; a `branch:` whose value this reader cannot see (on the
      # next line) prints `?`, which the guard reports instead of leaving that branch out.
      while (match(line, /(^|[ \t{,"\047-])branch["\047]?[ \t]*:[ \t]*(&[^ \t,}]+[ \t]+)?[^ \t,}]*/)) {
        v = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
        sub(/^.*branch["\047]?[ \t]*:[ \t]*/, "", v); sub(/^&[^ \t,}]+[ \t]+/, "", v); gsub(/["\047]/, "", v)
        print (v == "" ? "?" : v)
      }
    }
  ' "${1:-harness.config.yml}" 2>/dev/null
}
