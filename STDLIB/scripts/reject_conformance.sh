#!/usr/bin/env bash
# reject_conformance.sh -- the STANDING compiler-rejection conformance gate.
#
# Every fixture in STDLIB/corpus_reject/ is a deliberately-malformed .iii program
# the self-hosting compiler (iiis-2) MUST reject: a non-zero exit AND no object
# file emitted. This is the ONLY gate on the compiler's diagnostic / rejection
# path -- the run_corpus.sh corpus exercises only programs that COMPILE and RUN,
# so without this gate a regression that made the front-end silently ACCEPT
# malformed input (a swallowed sema/parse error) would pass every other check.
#
# A fixture that COMPILES (rc 0), or emits an object despite a non-zero rc, FAILS
# the gate. Usage: reject_conformance.sh [path-to-iiis]   (defaults to COMPILED/iiis-2.exe)
# Exit: 0 = all rejected; 3 = no fixtures; 4 = a fixture was accepted.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
REJDIR="$ROOT/STDLIB/corpus_reject"
TMPO="${TMPDIR:-/tmp}/_reject_conf_$$.o"
fail=0
n=0
for f in "$REJDIR"/*.iii; do
    [ -e "$f" ] || continue
    n=$((n + 1))
    rm -f "$TMPO"
    "$IIIS" --compile-only "$f" --out "$TMPO" >/dev/null 2>&1
    rc=$?
    base="$(basename "$f")"
    if [ "$rc" -eq 0 ]; then
        echo "[reject-conformance] FAIL: $base COMPILED (rc=0) -- the compiler must REJECT it" >&2
        fail=1
    elif [ -f "$TMPO" ]; then
        echo "[reject-conformance] FAIL: $base emitted an object despite rc=$rc" >&2
        fail=1
    else
        echo "[reject-conformance] OK: $base rejected (rc=$rc, no object)"
    fi
done
rm -f "$TMPO"
if [ "$n" -eq 0 ]; then
    echo "[reject-conformance] FAIL: no fixtures found in $REJDIR" >&2
    exit 3
fi
if [ "$fail" -ne 0 ]; then
    exit 4
fi
echo "[reject-conformance] PASS: $n/$n fixtures rejected"
exit 0
