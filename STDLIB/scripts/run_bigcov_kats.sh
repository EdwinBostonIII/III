#!/usr/bin/env bash
# run_bigcov_kats.sh -- gate for the BIGINT-backed full-resolution symmetric 2D coverage (ui_exact_big.iii).
# Distinct from run_ui_kats because it links libiii_native.a (for numera/bigint + memoria/arena).
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
LIB="$III/STDLIB/build/iii/libiii_native.a"
OUT="$(mktemp -d)"
pass=0; fail=0

"$I2" "$A/ui_exact_big.iii" --compile-only --out "$OUT/ui_exact_big.o" 2>"$OUT/big.log" || { echo "FAIL ui_exact_big compile"; cat "$OUT/big.log"; exit 1; }
# 2119 (the full-2D-exact curve render) links ui_exact (ui_pt_below_arc, the independent subsampler's point test) which
# in turn externs ui_blend from ui_raster -- so both are compiled and passed as extra objects to that run only.
"$I2" "$A/ui_exact.iii"  --compile-only --out "$OUT/ui_exact.o"  2>"$OUT/ex.log"  || { echo "FAIL ui_exact compile"; cat "$OUT/ex.log"; exit 1; }
"$I2" "$A/ui_raster.iii" --compile-only --out "$OUT/ui_raster.o" 2>"$OUT/ras.log" || { echo "FAIL ui_raster compile"; cat "$OUT/ras.log"; exit 1; }
"$I2" "$A/ui_exact_sym.iii" --compile-only --out "$OUT/ui_exact_sym.o" 2>"$OUT/sym.log" || { echo "FAIL ui_exact_sym compile"; cat "$OUT/sym.log"; exit 1; }
# the render-scale bigint-coefficient coverage tier + its EXACT 2-surd sign + the N-surd sign it de-islanded.
"$I2" "$A/ui_exact_bigcov.iii"  --compile-only --out "$OUT/ui_exact_bigcov.o"  2>"$OUT/bcov.log" || { echo "FAIL ui_exact_bigcov compile"; cat "$OUT/bcov.log"; exit 1; }
"$I2" "$A/sqrt_sum_sign.iii"    --compile-only --out "$OUT/sqrt_sum_sign.o"    2>"$OUT/ssg.log"  || { echo "FAIL sqrt_sum_sign compile"; cat "$OUT/ssg.log"; exit 1; }
"$I2" "$A/kfield.iii"  --compile-only --out "$OUT/kfield.o"  2>"$OUT/kfw.log" || { echo "FAIL kfield compile"; cat "$OUT/kfw.log"; exit 1; }

run() {  # $1 name  $2 expected  $3.. extra .o's (besides ui_exact_big.o + $LIB)
    local name="$1" want="$2"; shift 2
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" || { echo "FAIL  $name : compile"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$@" "$OUT/ui_exact_big.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB" -lws2_32 -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head; fail=$((fail+1)); return; }
    local st="$OUT/${name}.run.exe"; cp "$OUT/$name.exe" "$st"
    timeout 120 "$st"; local rc=$?
    rm -f "$st"
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1)); else echo "FAIL  $name : exit $rc (want $want)"; fail=$((fail+1)); fi
}

run 2103_bsign_big 99 "$OUT/ui_exact_bigcov.o" "$OUT/ui_exact_sym.o" "$OUT/ui_exact.o" "$OUT/ui_raster.o"   # ui_exact_big is independent (sym_big moved to ui_exact_sym) -> no ui_exact link needed
# 2142 proves III's bigint EARNS its place in the exact-geometry stack: a faithful superset of the i64 cover2d path
# (bit-identical where i64 is valid, exact where i64 overflows and refuses -1).  Links ui_exact (the i64 path it
# supersedes + the independent valpha anchor) which pulls ui_raster (ui_blend).
run 2160_bigint_supersedes_i64 99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"
# 2161 proves the exact-geometry sign is now AUTO-ESCALATING (i64 -> 128-bit -> bigint-flagged): the ui_pt_below_arc/
# ui_arc_valpha silent-overflow bug fixed at the class level (ui_alg_sign_g), witnessed by the bigint ui_bsign1.
run 2161_exact_sign_escalation 99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"
# 2162 proves the GENERAL exact per-pixel coverage (ui_arc_cover2d_sym_big) closing cover2d's steep/corner limit:
# gentle/steep/corner/interior/exterior pixels all exact vs the independent subsampler (per-x clamp, degree-4, bigint sign).
run 2162_curve_coverage_sym 99 "$OUT/ui_exact_sym.o" "$OUT/ui_exact.o" "$OUT/ui_raster.o"
# 2163 proves the t-RANGE CLAMP of the coverage engine (ui_arc_cover2d_sym_big_t restricted to [t0,t1]) is exact vs an
# x-CLIPPED subsampler -- the unit proof under ui_arc_cover_full: t1 killing the full-piece, the RATIONAL full-piece edge,
# and t0 clamping the lower bound.
run 2163_curve_coverage_trange 99 "$OUT/ui_exact_sym.o" "$OUT/ui_exact.o" "$OUT/ui_raster.o"
# 2165 proves the FULL-ARC DRIVER ui_arc_cover_full on a dome (split at the y-extremum + the extremum-column EXACT SUM):
# LEG A de Casteljau-exact split (vs the proven re-param sym_big, to the bit), LEG B the real t*=4/7 dome vs subsampler,
# LEG C teeth (round-ONCE strictly beats the +-1 round-each).  Driver stabilized + proven -> wired.
run 2165_dome_full 99 "$OUT/ui_exact_sym.o" "$OUT/ui_exact.o" "$OUT/ui_raster.o"
# 2166 pins the RENDER-SCALE bigint-coefficient tier (ui_exact_bigcov): bc == the proven i64 sym EXACTLY at small +
# coord-480 across all pixel classes, with the ROUNDING cap removed -- the exact 2-surd sign ui_bigsign2 (bigint port
# of ui_sign_bi) replacing the N-surd ui_sqrt_sum_sign_big, whose separation bound false-zeros near-cancellations at
# scale.  (The render-scale SELECTION cap -- ui_sym_sel's i64 ui_tcmp -- is the next increment, not claimed here.)
run 2166_cover_bigcoeff 99 "$OUT/ui_exact_bigcov.o" "$OUT/ui_exact_sym.o" "$OUT/ui_exact.o" "$OUT/ui_raster.o"

echo "=== BIGINT-COVERAGE KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
