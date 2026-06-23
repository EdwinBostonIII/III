#!/usr/bin/env bash
# run_svir.sh -- PHASE 1 GATE: one hand-authored SVIR program (svir_prog.iii), two INDEPENDENT translators,
# both execute to 99 on THIS host -- x86-64 (fully sovereign, sovas+sovld, no gcc) AND WASM (via node).
# The translators are tools (bootstrap-linked with gcc); the x86 ARTIFACT is sovereign (kernel32-only PE).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"
W="$ROOT/STDLIB/build/sovir"; mkdir -p "$W" "$BOOT"
fail=0; say(){ echo "[svir] $*"; }

# ensure the sovereign assembler/linker tools + crt0 exist (from the sovereign-toolchain build)
for m in sovas sovparse sovcoff sovld sovas_main sovlink_main crt0; do
  [ -f "$BOOT/$m.o.s" ] || "$IIIS" "$ROOT/STDLIB/sovtc/$m.iii" --compile-only --out "$BOOT/$m.o" >/dev/null 2>&1
done
[ -s "$BOOT/sovas_main.exe" ]   || gcc "$BOOT/sovas_main.o" "$BOOT/sovparse.o" "$BOOT/sovcoff.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovas_main.exe" 2>/dev/null
[ -s "$BOOT/sovlink_main.exe" ] || gcc "$BOOT/sovlink_main.o" "$BOOT/sovld.o" "$BOOT/sovparse.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovlink_main.exe" 2>/dev/null
[ -s "$BOOT/crt0_sov.o" ]       || timeout 30 "$BOOT/sovas_main.exe" "$BOOT/crt0.o.s" > "$BOOT/crt0_sov.o" 2>/dev/null

# build the SVIR program + the two translator tools
"$IIIS" "$S/svir_prog.iii" --compile-only --out "$W/svir_prog.o" >/dev/null 2>&1 || { say "FAIL compile svir_prog"; fail=1; }
"$IIIS" "$S/svir_x86.iii"  --compile-only --out "$W/svir_x86.o"  >/dev/null 2>&1 || { say "FAIL compile svir_x86"; fail=1; }
"$IIIS" "$S/svir_wasm.iii" --compile-only --out "$W/svir_wasm.o" >/dev/null 2>&1 || { say "FAIL compile svir_wasm"; fail=1; }
gcc "$W/svir_x86.o"  "$W/svir_prog.o" -o "$W/svir_x86.exe"  2>/dev/null || { say "FAIL link svir_x86 tool"; fail=1; }
gcc "$W/svir_wasm.o" "$W/svir_prog.o" -o "$W/svir_wasm.exe" 2>/dev/null || { say "FAIL link svir_wasm tool"; fail=1; }

# ---- machine A: x86-64, fully sovereign ----
"$W/svir_x86.exe" > "$W/prog_sum.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/prog_sum.s" > "$W/prog_sum.o" 2>/dev/null
sa=$?
if [ $sa -eq 0 ]; then
  timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/prog_sum.o" > "$W/prog_sum.x86.exe" 2>/dev/null
  timeout 10 "$W/prog_sum.x86.exe" >/dev/null 2>&1; ra=$?
  imp=$(objdump -p "$W/prog_sum.x86.exe" 2>/dev/null | grep -ic "DLL Name")
  dllk=$(objdump -p "$W/prog_sum.x86.exe" 2>/dev/null | grep -i "DLL Name" | grep -ic kernel32)
  if [ $ra -eq 99 ] && [ "$imp" = "1" ] && [ "$dllk" = "1" ]; then
    say "MACHINE A  x86-64 SOVEREIGN (sovas+sovld, kernel32-only PE) -> exit 99"
  else say "FAIL x86 path: exit=$ra imports=$imp kernel32=$dllk"; fail=1; fi
else say "FAIL sovas rejected prog_sum.s (exit $sa)"; fail=1; fi

# ---- machine B: WASM via node ----
"$W/svir_wasm.exe" > "$W/prog_sum.wasm" 2>/dev/null
node "$S/run_wasm.mjs" "$W/prog_sum.wasm" >/dev/null 2>&1; rb=$?
if [ $rb -eq 99 ]; then say "MACHINE B  WASM (node) -> exit 99"; else say "FAIL wasm path: exit=$rb"; fail=1; fi

if [ $fail -eq 0 ]; then
  say "ALL PASS -- ONE SVIR program, TWO independent translators, BOTH execute to 99 on this host (x86-64 sovereign + WASM)."
fi
exit $fail
