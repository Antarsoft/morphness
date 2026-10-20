#!/usr/bin/env bash
# Checks that the results page cannot show a failure as a pass: renders scripts/trust-report.sh --render-only
# from small fixture data (no tools run) and looks at the HTML.
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
# 2. everything fine
echo "{\"schema\":1,\"generated\":\"2026-01-01 00:00 UTC\",\"commit\":\"0000000000000000000000000000000000000000\",\"release\":\"x\",\"dirty\":false,\"limits\":[],\"rows\":[
$(row selftest own pass "all fine" "")]}" >"$tmp/good.json"
"$ROOT/scripts/trust-report.sh" --render-only "$tmp/good.json" --out "$tmp/out" >/dev/null
check good "Every check in this run finished"
if grep -q "This run has problems" "$tmp/out/trust.html"; then echo "FAIL good: page claims problems"; fail=1; fi
[ "$fail" = 0 ] && echo "trust-report render test: ok"
exit "$fail"
