#!/usr/bin/env bash
# run_sovbuild.sh -- GATE for the LIVE sovereign build (sovbuild.sh) + the sovas Tier-2 flip.
#   (0) refresh the gen1 sovereign tools from the CURRENT sovas/sovparse/sovld sources (so the gate tests them).
#   (1) FULL sovereign : prog_sat (805-line DPLL SAT solver) assembles ENTIRELY through sovas, links via sovld
#       -- gcc NOWHERE -- and the OS runs the PE to exit 99 (asserts witness=0).
#   (2) ROUTED         : prog_egraph (28 modules) routes the SIMD/wide-mul tail (sha256/keccak/bigint) to the
#       gcc-as witness, links ALL via sovld (no ld), runs to 99 (asserts a nonempty witness tail).
#   (3) TIER-2 FLIP    : prog_sha256ni (the hardware SHA-NI core: sha256rnds2/msg1/msg2 + SSE) builds FULLY
#       sovereign (witness=0) and runs to 99 -- a previously-routed program flipped by sovas Tier-2.
#   (4) BYTE-IDENTITY  : sovas's sha256_ni .text == gcc-as's .text (ADR-1: the assembler is provably correct).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; SOVTC="$ROOT/STDLIB/sovtc"
BOOT="$ROOT/STDLIB/build/_sovboot"; W="$ROOT/STDLIB/build/sovbuild"; mkdir -p "$BOOT" "$W"
fail=0

echo "[gate] === (0) refresh sovereign tools from current sources ==="
for m in sovas sovparse sovcoff sovld sovas_main sovlink_main crt0; do
  "$IIIS" "$SOVTC/$m.iii" --compile-only --out "$BOOT/$m.o" >/dev/null 2>&1 || { echo "[gate] FAIL compile $m"; fail=1; }
done
gcc "$BOOT/sovas_main.o" "$BOOT/sovparse.o" "$BOOT/sovcoff.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovas_main.exe" 2>/dev/null || fail=1
gcc "$BOOT/sovlink_main.o" "$BOOT/sovld.o" "$BOOT/sovparse.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovlink_main.exe" 2>/dev/null || fail=1
timeout 30 "$BOOT/sovas_main.exe" "$BOOT/crt0.o.s" > "$BOOT/crt0_sov.o" 2>/dev/null

echo "[gate] === (1) FULL sovereign: prog_sat ==="
o1="$(bash "$SOVTC/sovbuild.sh" "$SOVTC/prog_sat.iii" "$W/prog_sat.sov.exe" 2>&1)"; echo "$o1" | sed 's/^/  /'
echo "$o1" | grep -q "witness=0"   || { echo "[gate] FAIL prog_sat not FULLY sovereign"; fail=1; }
echo "$o1" | grep -q "RUN exit=99" || { echo "[gate] FAIL prog_sat did not run to 99"; fail=1; }

echo "[gate] === (2) ROUTED: prog_egraph ==="
o2="$(bash "$SOVTC/sovbuild.sh" "$SOVTC/prog_egraph.iii" "$W/prog_egraph.sov.exe" 2>&1)"; echo "$o2" | sed 's/^/  /'
echo "$o2" | grep -qE "witness=[1-9]" || { echo "[gate] FAIL prog_egraph routed no witness tail"; fail=1; }
echo "$o2" | grep -q "RUN exit=99"    || { echo "[gate] FAIL prog_egraph did not run to 99"; fail=1; }

echo "[gate] === (3) TIER-2 FLIP: prog_sha256ni (SHA-NI core) FULLY sovereign ==="
o3="$(bash "$SOVTC/sovbuild.sh" "$SOVTC/prog_sha256ni.iii" "$W/prog_sha256ni.sov.exe" 2>&1)"; echo "$o3" | sed 's/^/  /'
echo "$o3" | grep -q "witness=0"   || { echo "[gate] FAIL prog_sha256ni still routed (sovas Tier-2 regressed)"; fail=1; }
echo "$o3" | grep -q "RUN exit=99" || { echo "[gate] FAIL prog_sha256ni did not run to 99"; fail=1; }

echo "[gate] === (4) BYTE-IDENTITY: sovas sha256_ni .text == gcc-as ==="
"$IIIS" "$ROOT/STDLIB/iii/numera/sha256_ni.iii" --compile-only --out "$W/sha256_ni.o" >/dev/null 2>&1
timeout 30 "$BOOT/sovas_main.exe" "$W/sha256_ni.o.s" > "$W/sha256_ni_sov.o" 2>/dev/null
gcc -c -x assembler "$W/sha256_ni.o.s" -o "$W/sha256_ni_g.o" 2>/dev/null
objcopy -O binary --only-section=.text "$W/sha256_ni_sov.o" "$W/_ni_sov.text" 2>/dev/null
objcopy -O binary --only-section=.text "$W/sha256_ni_g.o"   "$W/_ni_g.text"   2>/dev/null
if cmp -s "$W/_ni_sov.text" "$W/_ni_g.text"; then echo "  sha256_ni .text BYTE-IDENTICAL vs gcc-as ($(stat -c%s "$W/_ni_sov.text") bytes)"; else echo "[gate] FAIL sha256_ni .text differs from gcc-as"; fail=1; fi

if [ $fail -eq 0 ]; then echo "[gate] ALL PASS -- sovereign build LIVE (full + routed) + sovas Tier-2 flip (SHA-NI, byte-identical, fully sovereign, runs 99)"; fi
exit $fail
