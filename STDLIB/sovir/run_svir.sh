#!/usr/bin/env bash
# run_svir.sh -- PHASE 1 + 1b GATE: TWO hand-authored SVIR programs x TWO independent translators, every
# combination executes to 99 on THIS host -- x86-64 (fully sovereign, sovas+sovld, no gcc) AND WASM (node).
#   svir_prog : straight-line arithmetic (gauss closed-form == 4950 -> 99)
#   svir_loop : a real COUNTED LOOP (BLOCK/LOOP/BR/BR_IF + locals + GE_S; sum 0..99 == 4950 -> 99)
# The translators are GENERIC (linked against whichever program); the x86 ARTIFACT is sovereign (kernel32-only).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"
W="$ROOT/STDLIB/build/sovir"; mkdir -p "$W" "$BOOT"
fail=0; say(){ echo "[svir] $*"; }

for m in sovas sovparse sovcoff sovld sovas_main sovlink_main crt0; do
  [ -f "$BOOT/$m.o.s" ] || "$IIIS" "$ROOT/STDLIB/sovtc/$m.iii" --compile-only --out "$BOOT/$m.o" >/dev/null 2>&1
done
[ -s "$BOOT/sovas_main.exe" ]   || gcc "$BOOT/sovas_main.o" "$BOOT/sovparse.o" "$BOOT/sovcoff.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovas_main.exe" 2>/dev/null
[ -s "$BOOT/sovlink_main.exe" ] || gcc "$BOOT/sovlink_main.o" "$BOOT/sovld.o" "$BOOT/sovparse.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovlink_main.exe" 2>/dev/null
[ -s "$BOOT/crt0_sov.o" ]       || timeout 30 "$BOOT/sovas_main.exe" "$BOOT/crt0.o.s" > "$BOOT/crt0_sov.o" 2>/dev/null

for m in svir_prog svir_loop svir_x86 svir_wasm; do
  "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; fail=1; }
done

# x86 path (fully sovereign): translator+program -> .s -> sovas -> sovld -> PE -> run; assert 99 + kernel32-only
x86path(){ local prog="$1" lbl="$2"
  gcc "$W/svir_x86.o" "$W/$prog.o" -o "$W/tx86_$lbl.exe" 2>/dev/null || { say "FAIL x86 tool $lbl"; fail=1; return; }
  "$W/tx86_$lbl.exe" > "$W/$lbl.s" 2>/dev/null
  timeout 20 "$BOOT/sovas_main.exe" "$W/$lbl.s" > "$W/$lbl.o" 2>/dev/null
  if [ $? -ne 0 ]; then say "FAIL x86/$lbl: sovas rejected"; fail=1; return; fi
  timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/$lbl.o" > "$W/$lbl.x86.exe" 2>/dev/null
  timeout 10 "$W/$lbl.x86.exe" >/dev/null 2>&1; local rc=$?
  local dlls; dlls=$(objdump -p "$W/$lbl.x86.exe" 2>/dev/null | grep -ic "DLL Name")
  local k32;  k32=$(objdump -p "$W/$lbl.x86.exe" 2>/dev/null | grep -i "DLL Name" | grep -ic kernel32)
  if [ $rc -eq 99 ] && [ "$dlls" = "1" ] && [ "$k32" = "1" ]; then say "x86  $lbl  SOVEREIGN (kernel32-only) -> 99"
  else say "FAIL x86/$lbl: exit=$rc dlls=$dlls k32=$k32"; fail=1; fi; }

# wasm path: translator+program -> .wasm -> node -> run; assert 99
wasmpath(){ local prog="$1" lbl="$2"
  gcc "$W/svir_wasm.o" "$W/$prog.o" -o "$W/twasm_$lbl.exe" 2>/dev/null || { say "FAIL wasm tool $lbl"; fail=1; return; }
  "$W/twasm_$lbl.exe" > "$W/$lbl.wasm" 2>/dev/null
  node "$S/run_wasm.mjs" "$W/$lbl.wasm" >/dev/null 2>&1; local rc=$?
  if [ $rc -eq 99 ]; then say "wasm $lbl  (node) -> 99"; else say "FAIL wasm/$lbl: exit=$rc"; fail=1; fi; }

x86path  svir_prog sum;  x86path  svir_loop loop
wasmpath svir_prog sum;  wasmpath svir_loop loop

if [ $fail -eq 0 ]; then
  say "ALL PASS -- 2 SVIR programs (arith + counted loop) x 2 independent translators, all execute to 99 (x86-64 sovereign + WASM)."
fi
exit $fail
