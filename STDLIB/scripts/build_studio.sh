#!/usr/bin/env bash
# build_studio.sh -- build III STUDIO (iii_studio.exe): the sovereign exact-mathematics IDE.
# Compiles every studio + substrate + organ module with the in-tree iiis-2 and links one native exe.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
N="$III/STDLIB/iii/numera"
LIB="$III/STDLIB/build/iii/libiii_native.a"
O="${STUDIO_OUT:-/tmp/studio}"
mkdir -p "$O" "$III/build"

MODS_A="ui_raster ui_font_data ui_font ui_vfont_data ui_vfont ui_exact ui_win ui_egraph studio_theme studio_trig wb_kernel sqrt_sum_sign exact_denest aether_lens aether_lens_frame cyclotomic_se3 kfield world_graph ws_home ws_forge ws_bench ws_lens ws_zoom ws_console iii_studio studio_sample"
MODS_N="ser_egraph ser_kinduct_sym"

for m in $MODS_A; do
    "$I2" "$A/$m.iii" --compile-only --out "$O/$m.o" 2>"$O/$m.log" || { echo "FAIL compile $m"; cat "$O/$m.log"; exit 1; }
done
for m in $MODS_N; do
    "$I2" "$N/$m.iii" --compile-only --out "$O/$m.o" 2>"$O/$m.log" || { echo "FAIL compile $m"; cat "$O/$m.log"; exit 1; }
done
echo "compile: all modules OK"

gcc "$O/iii_studio.o" "$O/studio_theme.o" "$O/studio_trig.o" \
    "$O/ws_home.o" "$O/ws_forge.o" "$O/ws_bench.o" "$O/ws_lens.o" "$O/ws_zoom.o" "$O/ws_console.o" \
    "$O/ui_win.o" "$O/ui_raster.o" "$O/ui_font.o" "$O/ui_font_data.o" "$O/ui_vfont.o" "$O/ui_vfont_data.o" "$O/ui_exact.o" \
    "$O/ui_egraph.o" "$O/ser_egraph.o" "$O/ser_kinduct_sym.o" \
    "$O/wb_kernel.o" "$O/sqrt_sum_sign.o" "$O/exact_denest.o" \
    "$O/aether_lens.o" "$O/aether_lens_frame.o" "$O/cyclotomic_se3.o" "$O/kfield.o" "$O/world_graph.o" \
    "$LIB" -luser32 -lgdi32 -lkernel32 -lws2_32 -o "$III/iii_studio.exe" 2>"$O/link.log" \
    || { echo "FAIL link"; grep -i "undefined" "$O/link.log" | head -30; exit 1; }
echo "link: iii_studio.exe OK"
ls -la "$III/iii_studio.exe"

# real corpus gates for the CONSOLE's `gate` verb: build the KAT binaries the studio spawns.
mkdir -p "$III/STDLIB/build/kats"
for k in 2155_aether_lens 2158_aether_lens_render; do
    n="${k%%_*}"
    "$I2" "$III/STDLIB/corpus/$k.iii" --compile-only --out "$O/$k.o" 2>"$O/$k.log" || { echo "FAIL compile $k"; cat "$O/$k.log"; exit 1; }
    gcc "$O/$k.o" "$O/aether_lens_frame.o" "$O/aether_lens.o" "$O/cyclotomic_se3.o" "$O/sqrt_sum_sign.o" "$O/exact_denest.o" "$O/kfield.o" "$LIB" \
        -lws2_32 -lkernel32 -o "$III/STDLIB/build/kats/$n.exe" 2>"$O/$k.l.log" || { echo "FAIL link $k"; grep -i undefined "$O/$k.l.log" | head; exit 1; }
    echo "gate binary: STDLIB/build/kats/$n.exe"
done
