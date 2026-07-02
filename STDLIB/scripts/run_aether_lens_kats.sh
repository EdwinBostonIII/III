#!/usr/bin/env bash
# run_aether_lens_kats.sh -- STANDALONE gate for the EXACT floating-point-free ray-cast interface:
#   aether_lens.iii        (ray-quadric hit/depth/shade/CSG-membership, composing sqrt_sum_sign)
#   aether_lens_frame.iii  (the rendered 3D scene: exact occlusion + CSG + derived Lambert -> 24-bit BMP)
# Kept DISJOINT from run_sqrtsum_kats.sh so concurrent edits to that shared gate cannot collide with this one.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
LIB="$III/STDLIB/build/iii/libiii_native.a"
OUT="$(mktemp -d)"
pass=0; fail=0

"$I2" "$A/sqrt_sum_sign.iii"     --compile-only --out "$OUT/sqrt_sum_sign.o"     2>"$OUT/ss.log"  || { echo "FAIL sqrt_sum_sign compile";     cat "$OUT/ss.log";  exit 1; }
"$I2" "$A/kfield.iii"  --compile-only --out "$OUT/kfield.o"  2>"$OUT/kfw.log" || { echo "FAIL kfield compile"; cat "$OUT/kfw.log"; exit 1; }
"$I2" "$A/aether_lens.iii"       --compile-only --out "$OUT/aether_lens.o"       2>"$OUT/al.log"  || { echo "FAIL aether_lens compile";       cat "$OUT/al.log";  exit 1; }
"$I2" "$A/aether_lens_frame.iii" --compile-only --out "$OUT/aether_lens_frame.o" 2>"$OUT/alf.log" || { echo "FAIL aether_lens_frame compile"; cat "$OUT/alf.log"; exit 1; }
"$I2" "$A/aether_lens_view.iii"  --compile-only --out "$OUT/aether_lens_view.o"  2>"$OUT/alv.log" || { echo "FAIL aether_lens_view compile";  cat "$OUT/alv.log"; exit 1; }
echo "PASS  aether_lens_view : compiles (the live interactive terminal viewer)"
"$I2" "$A/aether_lens_win.iii"   --compile-only --out "$OUT/aether_lens_win.o"   2>"$OUT/alw.log" || { echo "FAIL aether_lens_win compile"; cat "$OUT/alw.log"; exit 1; }
echo "PASS  aether_lens_win  : compiles (the REAL native Win32/GDI window viewer)"
"$I2" "$A/world_graph.iii"    --compile-only --out "$OUT/world_graph.o"    2>"$OUT/wgd.log" || { echo "FAIL world_graph compile"; cat "$OUT/wgd.log"; exit 1; }
echo "PASS  world_graph      : compiles (783 real modules + 5108 dependency edges, extracted from III's own source)"
"$I2" "$A/aether_world.iii"   --compile-only --out "$OUT/aether_world.o"   2>"$OUT/awd.log" || { echo "FAIL aether_world compile"; cat "$OUT/awd.log"; exit 1; }
echo "PASS  aether_world     : compiles (the resizable 3D sovereign-geometry explorer: photons + shapes + CSG + wireframe)"
"$I2" "$A/cyclotomic_se3.iii"    --compile-only --out "$OUT/cyclotomic_se3.o"   2>"$OUT/cse3.log" || { echo "FAIL cyclotomic_se3 compile"; cat "$OUT/cse3.log"; exit 1; }
# III STUDIO: the sovereign exact-mathematics IDE (shell + six live workspaces on the GLASS substrate)
for sm in wb_kernel studio_theme studio_trig ws_home ws_forge ws_bench ws_lens ws_zoom ws_console iii_studio studio_sample; do
    "$I2" "$A/$sm.iii" --compile-only --out "$OUT/$sm.o" 2>"$OUT/$sm.log" || { echo "FAIL $sm compile"; cat "$OUT/$sm.log"; exit 1; }
done
echo "PASS  iii_studio       : compiles (shell + HOME/FORGE/BENCH/LENS/ZOOM/CONSOLE -- all six live workspaces)"

# run <corpus-name> <want-exit> <workdir> <link objs...>
run() {
    local name="$1" want="$2" wd="$3"; shift 3
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" || { echo "FAIL  $name : compile"; sed -n '1,20p' "$OUT/$name.c.log"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$@" -lws2_32 -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head; fail=$((fail+1)); return; }
    local st="$OUT/${name}.run.exe"; cp "$OUT/$name.exe" "$st"
    ( cd "$wd" && timeout 150 "$st" ); local rc=$?
    rm -f "$st"
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1)); else echo "FAIL  $name : exit $rc (want $want)"; fail=$((fail+1)); fi
}

run 2155_aether_lens          99 "$OUT" "$OUT/aether_lens.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"                          # EXACT RAY-CAST core: hit/miss/tangent + z-fight-killer depth near-tie + derived 8-bit Lambert; first-light shaded sphere
run 2158_aether_lens_render   99 "$III" "$OUT/aether_lens_frame.o" "$OUT/aether_lens.o" "$OUT/cyclotomic_se3.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # THE INTERFACE: determinism + exact CSG membership + occlusion + bigint==i64 shade + cyclotomic_se3 zero-drift ORBIT; writes aether_lens.bmp
run 2169_studio_kernel        99 "$OUT" "$OUT/wb_kernel.o" "$OUT/studio_trig.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"        # III STUDIO's pure organs: collide/order/relay exact signs (hand-derived quadratics + marquee near-tie + surd-identity zero) + trig-table symmetries

echo "=== AETHER-LENS gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
