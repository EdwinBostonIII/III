#!/usr/bin/env bash
# run_sovbuild.sh -- GATE for the LIVE sovereign build (sovbuild.sh).
#   (1) FULL sovereign : prog_sat (a real 805-line DPLL SAT solver) assembles ENTIRELY through sovas and
#       links through sovld -- gcc NOWHERE -- and the OS runs the PE to exit 99.  Asserts witness=0.
#   (2) ROUTED         : prog_egraph (28-module faculty) assembles 25 modules sovereign + routes the
#       SIMD/wide-mul tail (sha256/keccak/bigint) to the gcc-as witness, links ALL through sovld (no ld),
#       and runs to 99.  Asserts a nonempty witness tail AND exit 99 (the consequential route is exercised).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOVTC="$ROOT/STDLIB/sovtc"; W="$ROOT/STDLIB/build/sovbuild"; mkdir -p "$W"
fail=0

echo "[gate] === (1) FULL sovereign: prog_sat ==="
o1="$(bash "$SOVTC/sovbuild.sh" "$SOVTC/prog_sat.iii" "$W/prog_sat.sov.exe" 2>&1)"; echo "$o1" | sed 's/^/  /'
echo "$o1" | grep -q "witness=0"   || { echo "[gate] FAIL prog_sat is not FULLY sovereign (witness tail present)"; fail=1; }
echo "$o1" | grep -q "RUN exit=99" || { echo "[gate] FAIL prog_sat did not run to 99"; fail=1; }

echo "[gate] === (2) ROUTED: prog_egraph ==="
o2="$(bash "$SOVTC/sovbuild.sh" "$SOVTC/prog_egraph.iii" "$W/prog_egraph.sov.exe" 2>&1)"; echo "$o2" | sed 's/^/  /'
echo "$o2" | grep -qE "witness=[1-9]" || { echo "[gate] FAIL prog_egraph routed no witness module (expected a SIMD tail)"; fail=1; }
echo "$o2" | grep -q "RUN exit=99"    || { echo "[gate] FAIL prog_egraph did not run to 99"; fail=1; }

if [ $fail -eq 0 ]; then echo "[gate] ALL PASS -- LIVE sovereign build: full + routed, sovld-linked (no ld); SIMD tail = declared gcc-as witness"; fi
exit $fail
