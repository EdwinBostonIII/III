#!/usr/bin/env bash
# run_svir_v2.sh -- SVIR v2 CONTAINER + CALL2 gate (the >255-function enabler; Phi1/Lambda0 prerequisite).
#
#   v1 saturates at 255 functions twice over: the container header is [nfunc:u8] and CALL is
#   [0x70][fi:u8][ac:u8].  main.c already registers FN=334 (container silently truncates: 334&0xFF=78;
#   calls to fi>=256 wrap -> the measured rc=9 class), and the linked whole-seed (~2,300 fns) is
#   impossible without a wider form.  v2 is ADDITIVE + VERSIONED: first byte 0x00 (illegal in v1) then
#   [nfunc:u16 LE], funcs from offset 3, data-section length u32; CALL2 = 0x74 [fi:u16 LE][ac:u8].
#   Every v1 module stays byte-identical; emitters use v2/CALL2 only when counts demand it.
#
#   Arms (all real exit codes, stale artifacts rm -f'd first):
#     verify(_svir_v2_gen)   = 99  (valid 300-fn v2 module; fn0: CALL2 299 + 92 -> 99)
#     verify(_svir_v2_oob)   = 9   (TEETH: CALL2 fi==nfunc must be rejected)
#     verify(_svir_v2_trunc) = 1   (TEETH: header claims 300 fns, bytes stop early)
#     interp(gen) = 99 ; sovereign x86(gen) = 99 (kernel32-only) ; wasm(gen) = 99 ; dis(gen) rc=0
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"
mkdir -p "$W" "$BOOT"; fail=0; say(){ echo "[svir-v2] $*"; }

# self-sufficient on a pristine clone: bootstrap the sovereign as/ld (same recipe as run_svir.sh) --
# the conscience sweep runs discovered gates in ITS order, so this gate must not assume run_svir.sh ran first.
for m in sovas sovparse sovcoff sovld sovas_main sovlink_main crt0; do
  [ -f "$BOOT/$m.o" ] || "$IIIS" "$ROOT/STDLIB/sovtc/$m.iii" --compile-only --out "$BOOT/$m.o" >/dev/null 2>&1
done
[ -s "$BOOT/sovas_main.exe" ]   || gcc "$BOOT/sovas_main.o" "$BOOT/sovparse.o" "$BOOT/sovcoff.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovas_main.exe" 2>/dev/null
[ -s "$BOOT/sovlink_main.exe" ] || gcc "$BOOT/sovlink_main.o" "$BOOT/sovld.o" "$BOOT/sovparse.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovlink_main.exe" 2>/dev/null
[ -s "$BOOT/crt0_sov.o" ]       || timeout 30 "$BOOT/sovas_main.exe" "$BOOT/crt0.o.s" > "$BOOT/crt0_sov.o" 2>/dev/null

for m in svir_verify verify_main svir_interp svir_x86 svir_wasm svir_dis _svir_v2_gen _svir_v2_oob _svir_v2_trunc; do
    "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m.iii"; exit 1; }
done

# --- verify arms (raw rc via verify_main: 99 == valid, else the anchor's error code) ---
declare -A EXP=( [gen]=99 [oob]=9 [trunc]=1 )
for m in gen oob trunc; do
    rm -f "$W/_v2v_$m.exe"
    gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/_svir_v2_$m.o" -o "$W/_v2v_$m.exe" 2>/dev/null
    "$W/_v2v_$m.exe" >/dev/null 2>&1; rc=$?
    if [ "$rc" -eq "${EXP[$m]}" ]; then say "verify $m : rc=$rc (expect ${EXP[$m]}) OK"
    else say "FAIL verify $m : rc=$rc expect ${EXP[$m]}"; fail=1; fi
done

# --- interp arm ---
rm -f "$W/_v2_in.exe"
gcc "$W/svir_interp.o" "$W/_svir_v2_gen.o" -o "$W/_v2_in.exe" 2>/dev/null
timeout 20 "$W/_v2_in.exe" >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 99 ]; then say "interp gen : 99 OK"; else say "FAIL interp gen : rc=$rc expect 99"; fail=1; fi

# --- sovereign x86 arm ---
rm -f "$W/_v2_tx.exe" "$W/_v2.s" "$W/_v2.o2" "$W/_v2.x86.exe"
gcc "$W/svir_x86.o" "$W/_svir_v2_gen.o" -o "$W/_v2_tx.exe" 2>/dev/null
"$W/_v2_tx.exe" > "$W/_v2.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/_v2.s" > "$W/_v2.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/_v2.o2" > "$W/_v2.x86.exe" 2>/dev/null
timeout 10 "$W/_v2.x86.exe" >/dev/null 2>&1; rc=$?
k=$(objdump -p "$W/_v2.x86.exe" 2>/dev/null | grep -ic "DLL Name")
if [ "$rc" -eq 99 ] && [ "$k" -eq 1 ]; then say "sovereign x86 gen : 99, DLLs=$k (kernel32-only) OK"
else say "FAIL x86 gen : rc=$rc dlls=$k (expect 99, 1)"; fail=1; fi

# --- wasm arm ---
rm -f "$W/_v2_tw.exe" "$W/_v2.wasm"
gcc "$W/svir_wasm.o" "$W/_svir_v2_gen.o" -o "$W/_v2_tw.exe" 2>/dev/null
"$W/_v2_tw.exe" > "$W/_v2.wasm" 2>/dev/null
node "$S/run_wasm.mjs" "$W/_v2.wasm" >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 99 ]; then say "wasm gen : 99 OK"; else say "FAIL wasm gen : rc=$rc expect 99"; fail=1; fi

# --- dis arm (clean decode walk) ---
rm -f "$W/_v2_dis.exe"
gcc "$W/svir_dis.o" "$W/_svir_v2_gen.o" -o "$W/_v2_dis.exe" 2>/dev/null
timeout 20 "$W/_v2_dis.exe" >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] || [ "$rc" -eq 99 ]; then say "dis gen : rc=$rc OK"; else say "FAIL dis gen : rc=$rc"; fail=1; fi

if [ "$fail" -eq 0 ]; then say "SVIR-V2 GREEN -- v2 container + CALL2 verified on all five consumers, teeth proven (oob=9, trunc=1)."; fi
exit $fail
