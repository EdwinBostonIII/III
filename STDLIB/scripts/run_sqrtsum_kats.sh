#!/usr/bin/env bash
# run_sqrtsum_kats.sh -- gate for the GENERAL sum-of-square-roots sign predicate (sqrt_sum_sign.iii):
# bigint_isqrt (handle-frugal) + ui_sqrt_sum_sign (separation-bound, arbitrary n, exact-zero detection).
# Links libiii_native.a (bigint/arena) and, for the agreement KAT, ui_exact_big.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
LIB="$III/STDLIB/build/iii/libiii_native.a"
OUT="$(mktemp -d)"
pass=0; fail=0

"$I2" "$A/sqrt_sum_sign.iii" --compile-only --out "$OUT/sqrt_sum_sign.o" 2>"$OUT/s.log" || { echo "FAIL sqrt_sum_sign compile"; cat "$OUT/s.log"; exit 1; }
"$I2" "$A/ui_exact_big.iii"  --compile-only --out "$OUT/ui_exact_big.o"  2>"$OUT/u.log" || { echo "FAIL ui_exact_big compile"; cat "$OUT/u.log"; exit 1; }
"$I2" "$A/verb_geom.iii"     --compile-only --out "$OUT/verb_geom.o"     2>"$OUT/v.log" || { echo "FAIL verb_geom compile"; cat "$OUT/v.log"; exit 1; }
"$I2" "$A/traj_kinematics.iii" --compile-only --out "$OUT/traj_kinematics.o" 2>"$OUT/t.log" || { echo "FAIL traj_kinematics compile"; cat "$OUT/t.log"; exit 1; }

run() {
    local name="$1" want="$2"; shift 2
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" || { echo "FAIL  $name : compile"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$@" -lws2_32 -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head; fail=$((fail+1)); return; }
    local st="$OUT/${name}.run.exe"; cp "$OUT/$name.exe" "$st"
    timeout 150 "$st"; local rc=$?
    rm -f "$st"
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1)); else echo "FAIL  $name : exit $rc (want $want)"; fail=$((fail+1)); fi
}

run 2120_bigint_isqrt   99   "$OUT/sqrt_sum_sign.o" "$LIB"
run 2121_sqrt_sum_sign  99   "$OUT/sqrt_sum_sign.o" "$OUT/ui_exact_big.o" "$LIB"
run 2122_lazy_real      99   "$OUT/sqrt_sum_sign.o" "$OUT/ui_exact_big.o" "$LIB"   # lazy tier-1 interval + tier-3 escalation, counted
run 2123_lazy3          99   "$OUT/sqrt_sum_sign.o" "$OUT/ui_exact_big.o" "$LIB"   # ATTACK 1+3: canonicalization Tier 2 + adaptive-F windowing
run 2124_transcendental 99   "$OUT/sqrt_sum_sign.o" "$OUT/ui_exact_big.o" "$LIB"   # ATTACK 2: transcendental tristate (UNKNOWN, no panic)
run 2125_verb_geom      99   "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/ui_exact_big.o" "$LIB"   # GRAPH RESTORED: e-class equivalence substrate + sign cache
run 2137_adaptive_sign  99   "$OUT/sqrt_sum_sign.o" "$LIB"   # TIER 2.5: linear-independence + adaptive precision -- bypasses the exponential separation bound per-instance
run 2138_symmetry_quotient 99 "$OUT/sqrt_sum_sign.o" "$LIB"  # SYMMETRY QUOTIENT: real Euclidean perimeter comparisons -- pay the exact-sign wall once per distinct shape (similarity/relabel/swap orbit)
run 2139_padic_barrier   99   "$OUT/sqrt_sum_sign.o" "$LIB"  # P-ADIC WALL FACE: factoring-free modular sieve is UNSOUND (mod p destroys perfect-square factors); sound arm needs factoring => redundant
run 2140_adaptive_big    99   "$OUT/sqrt_sum_sign.o" "$LIB"  # TIER 2.5 BIGINT-COEFF: adaptive sign for caller-owned bigint magnitudes (the ui_sqrt_sum_sign_big / ui_arc_cover_full render-scale path)
run 2141_cyclotomic_rotation 99 "$LIB"  # EXACT cyclotomic rotation: rational-multiple-of-π angles in ℚ(√2,√3); 24×15° returns bit-exact to identity (zero drift) where fixed-point drifts
run 2142_se3_screw       99   "$LIB"  # EXACT SE(3) screw: 3D rotation closure + SO(3) non-commutativity + exact screw translation in ℚ(√2,√3); zero drift vs fixed-point
run 2143_traj_arclen     99   "$OUT/traj_kinematics.o" "$OUT/sqrt_sum_sign.o" "$LIB"  # LOAD-BEARING: traj_len_sign consumes the bigint adaptive tier -- exact gantry-trajectory length comparison (3+ independent surds at bigint scale)

echo "=== SQRT-SUM-SIGN KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
