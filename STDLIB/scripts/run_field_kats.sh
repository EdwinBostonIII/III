#!/usr/bin/env bash
# run_field_kats.sh -- gate for THE UNIFIED FIELD faculties (ui_field.iii): data-is-geometry, structural color, and
# the further higher faculties built on the exact-algebraic core.  Self-contained (ui_field has no heavy deps).
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
LIB="$III/STDLIB/build/iii/libiii_native.a"
OUT="$(mktemp -d)"
pass=0; fail=0

"$I2" "$A/ui_field.iii" --compile-only --out "$OUT/ui_field.o" 2>"$OUT/f.log" || { echo "FAIL ui_field compile"; cat "$OUT/f.log"; exit 1; }

run() {
    local name="$1" want="$2"; shift 2
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" || { echo "FAIL  $name : compile"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$OUT/ui_field.o" "$@" -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head; fail=$((fail+1)); return; }
    local st="$OUT/${name}.run.exe"; cp "$OUT/$name.exe" "$st"
    timeout 90 "$st"; local rc=$?
    rm -f "$st"
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1)); else echo "FAIL  $name : exit $rc (want $want)"; fail=$((fail+1)); fi
}

run 2104_field_kolmogorov 99    # data -> exact complexity-dimension (Kolmogorov honestly proxied by Renyi-2 entropy)
run 2105_field_color       99    # structural color: dimension -> wavelength -> RGB + EXACT grating identity
run 2106_field_time        99    # continuous time as an algebraic variable -- exact kinematics at irrational instants
run 2107_field_inverse     99    # reverse rasterization / optical proofing -- pixels -> exact geometry (constrained inverse)
run 2108_field_slice       99    # N-dimensional algebraic slicing -- 2D plane ∩ N-D quadric -> exact conic cross-section
run 2109_field_quantum     99    # THE QUANTUM UI -- superposition=fractal dimension, collapse=snap to integer baseline
run 2110_field_acoustic    99    # acoustic topology -- shape -> exact overtone series, audible out-of-tune
run 2111_field_reversible  99    # reversible time-travel -- evolve then reverse is the exact identity (zero-entropy undo)
run 2112_field_localweb    99    # THE LOCAL WEB -- global field from purely local relays (relational-ontology evidence)
run 2113_field_selfpop     99    # SELF-POPULATION -- one local rule self-grows the exact Sierpinski fractal
run 2114_field_cf          99    # SELF-POPULATING NUMBERS -- periodic continued fractions, exact irrationals (Pell-proven)
run 2115_field_wave        99    # ALGEBRAIC WAVE OPTICS -- exact interference fringes, no grid
run 2116_field_hash        99    # FRACTAL HASH -- geometry as tamper-evident seal
run 2117_field_superpos    99    "$LIB" -lws2_32   # E-GRAPH SUPERPOSITION -- attached to the REAL egraph.iii
run 2118_field_binding     99    "$LIB" -lws2_32   # THE BINDING -- topo+egraph+exact agree on one conserved invariant


# ── DEMO-MAIN SMOKE (reunification W4b-i.12): the three surviving field/fractal demo mains compile,
#    link against the SAME organ objects, and RUN headless to rc=0.  field_run absorbed field_dim
#    (mode `dim <file>`) + field_full (mode `full`); fractal_dim + mandel_run stay (the falsifiers).
"$I2" "$A/sqrt_sum_sign.iii" --compile-only --out "$OUT/sqrt_sum_sign.o" 2>"$OUT/sss.log" || { echo "FAIL sqrt_sum_sign compile (smoke)"; fail=$((fail+1)); }
"$I2" "$A/kfield.iii"        --compile-only --out "$OUT/kfield.o"        2>"$OUT/kf.log"  || { echo "FAIL kfield compile (smoke)"; fail=$((fail+1)); }
"$I2" "$A/ui_exact_big.iii"  --compile-only --out "$OUT/ui_exact_big.o"  2>"$OUT/ueb.log" || { echo "FAIL ui_exact_big compile (smoke)"; fail=$((fail+1)); }
smoke() {
    local name="$1"; shift
    if ! "$I2" "$A/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.clog"; then
        echo "FAIL  $name : compile"; cat "$OUT/$name.clog"; fail=$((fail+1)); return
    fi
    if ! gcc "$OUT/$name.o" "$OUT/ui_field.o" "$OUT/ui_exact_big.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB" -lws2_32 -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.ld"; then
        echo "FAIL  $name : link"; tail -3 "$OUT/$name.ld"; fail=$((fail+1)); return
    fi
    local st="/tmp/fsmoke_$$_$RANDOM.exe"; cp "$OUT/$name.exe" "$st"
    if timeout 90 "$st" "$@" > /dev/null 2>&1; then echo "PASS  $name $* : runs (rc=0)"; pass=$((pass+1))
    else echo "FAIL  $name $* : run rc=$?"; fail=$((fail+1)); fi
    rm -f "$st"
}
smoke field_run
smoke field_run full
smoke field_run dim "$A/field_run.iii"
smoke fractal_dim
smoke mandel_run
echo "=== UNIFIED-FIELD KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1

