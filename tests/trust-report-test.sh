#!/usr/bin/env bash
# Checks that the results page cannot show a failure as a pass: renders scripts/trust-report.sh --render-only
# from small fixture data (no tools run) and looks at the HTML. Then checks the gitleaks download against a
# fake release served from a local folder and a local server (no network): pinned checksum, Pythons without
# tar filters, and servers that stall or drip.
# Usage: tests/trust-report-test.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
check() { if ! grep -q -- "$2" "$tmp/out/trust.html"; then echo "FAIL $1: page lacks: $2"; fail=1; fi; }
row() { # status group summary error
  printf '{"group":"%s","name":"%s","url":"","version":"1","what":"w","command":"c","status":"%s","summary":"%s","error":"%s","findings":[%s],"logs":[],"finished":"2026-01-01 00:00 UTC"}' "$2" "$1" "$3" "$4" "$5" "${6:-}"
}
# 1. a tool that did not run, and a finding without a verdict
echo "{\"schema\":1,\"generated\":\"2026-01-01 00:00 UTC\",\"commit\":\"0000000000000000000000000000000000000000\",\"release\":\"x\",\"dirty\":false,\"limits\":[\"A limit.\"],\"rows\":[
$(row crashed public did-not-run "" "boom"),
$(row noisy public untriaged "1 finding(s), 1 untriaged" "" '{"rule":"R1","path":"a/b","line":3,"level":"warning","message":"m","triage":null}'),
$(row selftest own fail "1 problem" "")]}" >"$tmp/bad.json"
"$ROOT/scripts/trust-report.sh" --render-only "$tmp/bad.json" --out "$tmp/out" >/dev/null
check bad "did not run: boom"
check bad "This run has problems: crashed, noisy, selftest"
check bad 'class="untriaged">untriaged'
check bad "A limit."
grep -q "problem(s)" "$tmp/out/trust/badge.json" && grep -q red "$tmp/out/trust/badge.json" || { echo "FAIL bad: badge does not show the problems"; fail=1; }
# 2. everything fine
echo "{\"schema\":1,\"generated\":\"2026-01-01 00:00 UTC\",\"commit\":\"0000000000000000000000000000000000000000\",\"release\":\"x\",\"dirty\":false,\"limits\":[],\"rows\":[
$(row selftest own pass "all fine" "")]}" >"$tmp/good.json"
"$ROOT/scripts/trust-report.sh" --render-only "$tmp/good.json" --out "$tmp/out" >/dev/null
check good "Every check in this run finished"
grep -q brightgreen "$tmp/out/trust/badge.json" || { echo "FAIL good: badge is not green"; fail=1; }
if grep -q "This run has problems" "$tmp/out/trust.html"; then echo "FAIL good: page claims problems"; fail=1; fi
# 3. gitleaks download: checked against the pinned checksum (not one fetched from the same place), extracted
# on a Python without tar extraction filters, and a server that never answers fails the row instead of hanging.
# Every other tool is faked to fail, and gitleaks itself is a fake served from a local folder.
gl() { # <python3 dir or ""> <extra env...>: runs the report, prints the gitleaks row as "status: summary/error"
  local pydir="$1"; shift
  rm -rf "$tmp/gl-out"
  ${bound:+$bound 60} env ${pydir:+PATH="$pydir:$PATH"} TRUST_FAKE_FAIL=selftest,agnix,shellcheck,skillspector "$@" \
    "$ROOT/scripts/trust-report.sh" --skip-selftest --allow-untriaged --out "$tmp/gl-out" >/dev/null 2>&1 || true
  python3 -I -c 'import json, sys
for r in json.load(open(sys.argv[1]))["rows"]:
    if r["name"] == "gitleaks": print(r["status"] + ": " + (r.get("summary") or "") + (r.get("error") or ""))' "$tmp/gl-out/trust/results.json" 2>/dev/null || echo "no results.json written"
}
bound="$(command -v timeout || command -v gtimeout || true)"   # a hang shows as a failed row, not a stuck test
sysn="$(uname -s | tr 'A-Z' 'a-z')"; arch="$(uname -m)"
case "$arch" in x86_64|amd64) arch=x64 ;; aarch64|arm64) arch=arm64 ;; esac
ver="$(sed -n 's/^ *"gitleaks": "\([0-9.]*\)",$/\1/p' "$ROOT/scripts/trust-report.sh")"
mkdir -p "$tmp/rel/pkg"
printf '#!/bin/sh\nwhile [ $# -gt 0 ]; do [ "$1" = -r ] && rep="$2"; shift; done\necho "[]" > "$rep"; echo "3 commits scanned" >&2\n' >"$tmp/rel/pkg/gitleaks"
chmod +x "$tmp/rel/pkg/gitleaks"
name="gitleaks_${ver}_${sysn}_${arch}.tar.gz"
tar -czf "$tmp/rel/$name" -C "$tmp/rel/pkg" gitleaks
sum="$(python3 -I -c 'import hashlib, sys; print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())' "$tmp/rel/$name")"
echo "$sum  $name" >"$tmp/rel/gitleaks_${ver}_checksums.txt"   # a matching checksums file next to it, as a release has
url="file://$tmp/rel/"
got="$(gl "" TRUST_GITLEAKS_URL="$url" TRUST_GITLEAKS_SHA256="$sum")"
case "$got" in "clean: "*) ;; *) echo "FAIL gitleaks: a tarball matching its checksum gave: $got"; fail=1 ;; esac
got="$(gl "" TRUST_GITLEAKS_URL="$url")"
case "$got" in "did-not-run: "*"does not match the pinned checksum"*) ;; *) echo "FAIL gitleaks: a tarball that isn't the pinned one gave: $got"; fail=1 ;; esac
# A python3 whose TarFile.extract has no filter argument, as before 3.9.17, 3.10.12 and 3.11.4.
mkdir -p "$tmp/oldpy"
cat >"$tmp/oldpy/python3" <<SH
#!/bin/sh
prog="\$(cat)"
exec $(command -v python3) "\$@" <<PROG
import tarfile
_extract = tarfile.TarFile.extract
def extract(self, member, path="", set_attrs=True, *, numeric_owner=False, **kw):
    if kw:
        raise TypeError("extract() got an unexpected keyword argument " + repr(next(iter(kw))))
    return _extract(self, member, path, set_attrs, numeric_owner=numeric_owner)
tarfile.TarFile.extract = extract
\$prog
PROG
SH
chmod +x "$tmp/oldpy/python3"
got="$(gl "$tmp/oldpy" TRUST_GITLEAKS_URL="$url" TRUST_GITLEAKS_SHA256="$sum")"
case "$got" in "clean: "*) ;; *) echo "FAIL gitleaks: on a Python without tar filters it gave: $got"; fail=1 ;; esac
# A server that accepts the connection and never answers.
port_file="$tmp/port"
python3 -I -c 'import socket, sys, time
s = socket.socket(); s.bind(("127.0.0.1", 0)); s.listen(5)
open(sys.argv[1], "w").write(str(s.getsockname()[1]))
conns = []
while True: conns.append(s.accept())' "$port_file" &
server=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$port_file" ] && break; sleep 0.2; done
start=$(date +%s)
got="$(gl "" TRUST_NET_TIMEOUT=2 TRUST_GITLEAKS_URL="http://127.0.0.1:$(cat "$port_file")/" TRUST_GITLEAKS_SHA256="$sum" no_proxy=127.0.0.1 NO_PROXY=127.0.0.1)"
took=$(( $(date +%s) - start ))
kill "$server" 2>/dev/null; wait "$server" 2>/dev/null || true
case "$got" in "did-not-run: "*"timed out"*) ;; *) echo "FAIL gitleaks: a server that never answers gave: $got (after ${took}s)"; fail=1 ;; esac
# A server that answers, then sends one byte every half second: only the whole-download limit stops it.
python3 -I -c 'import socket, sys, threading, time
s = socket.socket(); s.bind(("127.0.0.1", 0)); s.listen(5)
open(sys.argv[1], "w").write(str(s.getsockname()[1]))
def drip(c):
    c.recv(4096)
    c.sendall(b"HTTP/1.0 200 OK\r\nContent-Length: 100000\r\n\r\n")
    while True:
        c.sendall(b"x"); time.sleep(0.5)
while True:
    c, _ = s.accept(); threading.Thread(target=drip, args=(c,), daemon=True).start()' "$port_file.drip" &
server=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$port_file.drip" ] && break; sleep 0.2; done
got="$(gl "" TRUST_NET_TIMEOUT=1 TRUST_GITLEAKS_URL="http://127.0.0.1:$(cat "$port_file.drip")/" TRUST_GITLEAKS_SHA256="$sum" no_proxy=127.0.0.1 NO_PROXY=127.0.0.1)"
kill "$server" 2>/dev/null; wait "$server" 2>/dev/null || true
case "$got" in "did-not-run: "*"took over 5s"*) ;; *) echo "FAIL gitleaks: a server that drips a byte at a time gave: $got"; fail=1 ;; esac
[ "$fail" = 0 ] && echo "trust-report render test: ok"
exit "$fail"
