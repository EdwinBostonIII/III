#!/usr/bin/env bash
# run_ui_kats.sh -- gate for the III-GLASS UI KATs (2080-2082).
#
# The III-GLASS UI is an APPLICATION built on III, not core runtime, so its modules (ui_raster/ui_exact/ui_font)
# are deliberately NOT aggregated into the coverage-gated libiii_native.a (that gate is for the core library's
# exports).  This runner links the UI .o's DIRECTLY and asserts each KAT's real exit code.  run_corpus.sh
# delegates 2080-2082 here (a SKIP-case) so it never phantom-FAILs them on the generic archive link.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB="$(cd "$SCRIPT_DIR/.." && pwd)"
III="$(cd "$STDLIB/.." && pwd)"
LIB="$STDLIB/build/iii/libiii_native.a"
I2="$III/COMPILED/iiis-2.exe"
A="$STDLIB/iii/aether"
C="$STDLIB/corpus"
OUT="$STDLIB/build/uikats"
mkdir -p "$OUT"
fail=0; pass=0

cc() { "$I2" "$1" --compile-only --out "$2" 2>/dev/null; }

# pure UI library .o's (framebuffer/math; no Windows APIs)
# + the app shells for the live root exes (atlas = ui_egraph_app, topo = ui_topo): compile-gated
#   here so their sources can never silently rot (whole-tree sweep 2026-07-02 found them orphaned).
for m in ui_raster ui_font_data ui_exact ui_exact_cubic ui_font ui_vfont ui_vfont_data ui_present studio_theme studio_sample ui_win ui_morphic ui_destiny ui_morphic_app ui_destiny_app ui_egraph ui_egraph_app ui_topo; do
    cc "$A/$m.iii" "$OUT/$m.o" || { echo "FAIL  lib $m : compile"; fail=$((fail+1)); }
done

run() {  # $1 name  $2 expected  $3.. extra .o's
    local name="$1"; local exp="$2"; shift 2
    cc "$C/$name.iii" "$OUT/$name.o" || { echo "FAIL  $name : compile"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$@" -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.linkerr" || { echo "FAIL  $name : link"; sed -n "1,4p" "$OUT/$name.linkerr"; fail=$((fail+1)); return; }
    local st="/tmp/uik_$$_$name.exe"; cp "$OUT/$name.exe" "$st" 2>/dev/null
    timeout 30 "$st" >/dev/null 2>&1; local rc=$?; rm -f "$st"
    if [[ "$rc" == "$exp" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1));
    else echo "FAIL  $name : exit $rc (expected $exp)"; fail=$((fail+1)); fi
}

run 2080_ui_raster 99 "$OUT/ui_raster.o"
run 2081_ui_exact  99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"
run 2082_ui_font   99 "$OUT/ui_font.o" "$OUT/ui_font_data.o" "$OUT/ui_raster.o"
run 2095_exact_coverage 99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"   # exact polygon coverage (shoelace + Pick)
run 2097_exact_aa       99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"   # exact ANALYTIC AA (homogeneous clip + rational area)
run 2098_exact_aa_poly  99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"   # exact AA for GENERAL polygons (signed-fan: non-convex + holes)
run 2099_exact_bezier   99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"   # exact Bezier area (Green) + exact ALGEBRAIC crossing (Q(sqrt D))
run 2100_biquad_coverage 99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"  # SYMBOLIC 2D coverage: bi-quadratic sign (degree-4, no interval refinement)
run 2101_hausdorff_dim  99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"   # continuous HAUSDORFF DIMENSION (smooth d=1; self-similar fractal d in (1,2))
run 2102_cover2d        99 "$OUT/ui_exact.o" "$OUT/ui_raster.o"   # FULL symmetric 2D coverage (Green: G(t2)-G(t1)-py degree-4; overflow detected)
run 2453_glass_surface  99 "$OUT/ui_vfont.o" "$OUT/ui_vfont_data.o" "$OUT/ui_exact.o" "$OUT/ui_exact_cubic.o" "$OUT/ui_raster.o" "$OUT/ui_present.o" "$OUT/studio_theme.o" "$OUT/studio_sample.o" "$OUT/ui_font.o" "$OUT/ui_font_data.o"   # reunification W0.2: the cubic/coverage seam + present/theme/sample surface
run 2476_morphic_writeback 99 "$OUT/ui_morphic.o" "$OUT/ui_raster.o" "$OUT/ui_font.o" "$OUT/ui_font_data.o" "$LIB" -lws2_32   # W4b-i.11: autopoietic SVIR write-back headless (byte-diff EXACT + re-prove + re-lift)
run 2477_destiny_closed_form 99 "$OUT/ui_destiny.o" "$OUT/ui_raster.o" "$OUT/ui_font.o" "$OUT/ui_font_data.o" "$LIB" -lws2_32   # W4b-i.11: holographic destiny -- 4 real SVIR fns, exact eval + exact closed-form max

echo "=== UI KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
