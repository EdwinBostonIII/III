#!/usr/bin/env bash
# run_topo_kats.sh -- gate for the Topological Windowing suite (2088-2092).
#
# These KATs exercise the crush engine ser_antiunify + the observation trace ser_petri -- both LIB, heavily
# corpus-gated, STABLE since 2026-06-27 (the old "concurrent task's WIP" note was stale doc-drift; adjudicated
# by III-PERFECTION-LEDGER §8b and struck by the reunification W2).  The family stays delegated for the REAL
# reason: it links directly against the whole libiii_native.a (resolving the au_*/sp_*/cg_synth closure), so the
# core gate stays decoupled from ser_* signature churn -- the same discipline as the UI app KATs.  run_corpus.sh
# SKIP-delegates 2088-2092 to this runner.  Each KAT must exit 99 (its real falsifier code).
#
# HONEST SCOPE (calibrated): the load-bearing results are 2088's LINEAR arm and 2092 -- au_topo_amputate /
# au_crush_module run real SVIR and bit-blast step==acc+delta over 2^64 (a genuine loop->closed-form proof).
# 2088's quadratic arm fits the orbit + proves the UNIVERSAL Gauss identity (not this orbit over 2^64); 2089 is a
# bb_equal verification of a hand-derived affine layout (not a constraint solver); 2090 is a composition test of
# closed forms (no III faculty); 2091 is an lgg generalization + a sampled bound (not a symbolic all-t proof).
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB="$(cd "$SCRIPT_DIR/.." && pwd)"
III="$(cd "$STDLIB/.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
C="$STDLIB/corpus"
ARCH="$STDLIB/build/iii/libiii_native.a"
OUT="$STDLIB/build/topokats"
mkdir -p "$OUT"
fail=0; pass=0

run() {
    local name="$1"
    "$I2" "$C/$name.iii" --compile-only --out "$OUT/$name.o" 2>/dev/null || { echo "FAIL  $name : compile"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$ARCH" -lws2_32 -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.linkerr" || { echo "FAIL  $name : link"; sed -n "1,4p" "$OUT/$name.linkerr"; fail=$((fail+1)); return; }
    local st="/tmp/topok_$$_${name}.exe"; cp "$OUT/$name.exe" "$st" 2>/dev/null
    timeout 90 "$st" >/dev/null 2>&1; local rc=$?; rm -f "$st"
    if [[ "$rc" == 99 ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1));
    else echo "FAIL  $name : exit $rc (expected 99)"; fail=$((fail+1)); fi
}

run 2088_frp_kinematics
run 2089_constraint_layout
run 2090_topological_field
run 2091_association_invariant
run 2092_raster_crush
run 2093_pixel_crush

echo "=== Topological Windowing gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
