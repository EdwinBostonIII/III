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

echo "=== SQRT-SUM-SIGN KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
