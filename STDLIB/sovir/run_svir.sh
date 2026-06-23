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

for m in svir_prog svir_loop svir_call svir_fact svir_bignum svir_x86 svir_wasm iiisv; do
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

x86path  svir_prog sum;  x86path  svir_loop loop;  x86path  svir_call call
wasmpath svir_prog sum;  wasmpath svir_loop loop;  wasmpath svir_call call

# ---- svir_fact: a real RECURSIVE program (factorial + recursive decimal print).  The DIFFERENTIAL is the
#      superiority claim, gated: x86 stdout == wasm stdout == an independent golden 20!, both exit 99. ----
gcc "$W/svir_x86.o"  "$W/svir_fact.o" -o "$W/tx_fact.exe"  2>/dev/null
gcc "$W/svir_wasm.o" "$W/svir_fact.o" -o "$W/tw_fact.exe"  2>/dev/null
"$W/tx_fact.exe" > "$W/fact.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/fact.s" > "$W/fact.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/fact.o2" > "$W/fact.x86.exe" 2>/dev/null
timeout 10 "$W/fact.x86.exe" > "$W/fact.x86.out" 2>/dev/null; xrc=$?
"$W/tw_fact.exe" > "$W/fact.wasm" 2>/dev/null
node "$S/run_wasm.mjs" "$W/fact.wasm" > "$W/fact.wasm.out" 2>/dev/null; wrc=$?
node -e 'let f=1n;for(let i=1n;i<=20n;i++)f*=i;process.stdout.write(f.toString()+"\n")' > "$W/fact.gold.out"
xk=$(objdump -p "$W/fact.x86.exe" 2>/dev/null | grep -i "DLL Name" | grep -ic kernel32)
xn=$(objdump -p "$W/fact.x86.exe" 2>/dev/null | grep -ic "DLL Name")
if [ $xrc -eq 99 ] && [ $wrc -eq 99 ] && [ "$xn" = "1" ] && [ "$xk" = "1" ] \
   && cmp -s "$W/fact.x86.out" "$W/fact.wasm.out" && cmp -s "$W/fact.x86.out" "$W/fact.gold.out"; then
  say "fact RECURSIVE 20! : x86(sovereign,kernel32-only)==wasm==golden [$(cat "$W/fact.x86.out" | tr -d '\n')], both exit 99"
else say "FAIL fact: x86exit=$xrc wasmexit=$wrc dlls=$xn k32=$xk  x86out=[$(cat "$W/fact.x86.out" 2>/dev/null)] wasmout=[$(cat "$W/fact.wasm.out" 2>/dev/null)]"; fail=1; fi

# ---- svir_bignum: ARBITRARY-PRECISION factorial (100! exact, 158 digits, in SVIR linear memory).  A C
#      long long overflows at 21!; this computes 100! exactly.  Gated differential: x86==wasm==node-bignum. ----
gcc "$W/svir_x86.o"  "$W/svir_bignum.o" -o "$W/tx_bn.exe" 2>/dev/null
gcc "$W/svir_wasm.o" "$W/svir_bignum.o" -o "$W/tw_bn.exe" 2>/dev/null
"$W/tx_bn.exe" > "$W/bn.s" 2>/dev/null
timeout 25 "$BOOT/sovas_main.exe" "$W/bn.s" > "$W/bn.o2" 2>/dev/null
timeout 25 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/bn.o2" > "$W/bn.x86.exe" 2>/dev/null
timeout 10 "$W/bn.x86.exe" > "$W/bn.x86.out" 2>/dev/null; bxr=$?
"$W/tw_bn.exe" > "$W/bn.wasm" 2>/dev/null
node "$S/run_wasm.mjs" "$W/bn.wasm" > "$W/bn.wasm.out" 2>/dev/null; bwr=$?
node -e 'let f=1n;for(let i=1n;i<=100n;i++)f*=i;process.stdout.write(f.toString()+"\n")' > "$W/bn.gold.out"
bxk=$(objdump -p "$W/bn.x86.exe" 2>/dev/null | grep -i "DLL Name" | grep -ic kernel32)
bxn=$(objdump -p "$W/bn.x86.exe" 2>/dev/null | grep -ic "DLL Name")
ndig=$(tr -d '\n' < "$W/bn.x86.out" | wc -c)
if [ $bxr -eq 99 ] && [ $bwr -eq 99 ] && [ "$bxn" = "1" ] && [ "$bxk" = "1" ] \
   && cmp -s "$W/bn.x86.out" "$W/bn.wasm.out" && cmp -s "$W/bn.x86.out" "$W/bn.gold.out"; then
  say "bignum ARBITRARY-PRECISION 100! : x86(sovereign,kernel32-only)==wasm==golden, $ndig digits EXACT, both exit 99"
else say "FAIL bignum: x86exit=$bxr wasmexit=$bwr dlls=$bxn k32=$bxk digits=$ndig"; fail=1; fi

# ---- iiisv: an INDEPENDENT .iii -> SVIR compiler (shares zero code with cg_r3).  Compile the REAL
#      indep_toolchain.iii source through it -> SVIR -> both machines -> 99; then the differential vs cg_r3. ----
gcc "$W/iiisv.o" -o "$W/iiisv.exe" 2>/dev/null || { say "FAIL link iiisv tool"; fail=1; }
"$W/iiisv.exe" "$ROOT/STDLIB/independence/indep_toolchain.iii" > "$W/gen_svir.iii" 2>/dev/null
"$IIIS" "$W/gen_svir.iii" --compile-only --out "$W/gen_svir.o" >/dev/null 2>&1 || { say "FAIL compile iiisv output"; fail=1; }
gcc "$W/svir_x86.o"  "$W/gen_svir.o" -o "$W/tx_ind.exe" 2>/dev/null
gcc "$W/svir_wasm.o" "$W/gen_svir.o" -o "$W/tw_ind.exe" 2>/dev/null
"$W/tx_ind.exe" > "$W/ind.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/ind.s" > "$W/ind.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/ind.o2" > "$W/ind.x86.exe" 2>/dev/null
timeout 10 "$W/ind.x86.exe" >/dev/null 2>&1; ivx=$?
"$W/tw_ind.exe" > "$W/ind.wasm" 2>/dev/null
node "$S/run_wasm.mjs" "$W/ind.wasm" >/dev/null 2>&1; ivw=$?
"$IIIS" "$ROOT/STDLIB/independence/indep_toolchain.iii" --compile-only --out "$W/indep_cg.o" >/dev/null 2>&1
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/indep_cg.o" > "$W/indep_cg.exe" 2>/dev/null
timeout 10 "$W/indep_cg.exe" >/dev/null 2>&1; cgx=$?
ik=$(objdump -p "$W/ind.x86.exe" 2>/dev/null | grep -ic "DLL Name")
if [ $ivx -eq 99 ] && [ $ivw -eq 99 ] && [ $cgx -eq 99 ] && [ "$ik" = "1" ]; then
  say "iiisv INDEPENDENT compiler : real indep_toolchain.iii -> SVIR -> x86(sovereign)=$ivx & wasm=$ivw ; cg_r3 differential=$cgx -> all agree (99)"
else say "FAIL iiisv: x86=$ivx wasm=$ivw cg_r3=$cgx dlls=$ik"; fail=1; fi

if [ $fail -eq 0 ]; then
  say "ALL PASS -- 5 SVIR programs (arith, loop, CALL, recursive factorial, ARBITRARY-PRECISION 100!) x 2 translators; PLUS iiisv: an INDEPENDENT .iii->SVIR compiler that lowers REAL III source to x86(sovereign)+wasm and agrees with cg_r3 (independent differential compilation -- the foundation for DDC).  20!=long-long-equiv (toolchain superiority); 100!=arbitrary precision (PROGRAM superiority); iiisv=real source, independent compiler, 2 machines, cross-verified (TRUST + PORTABILITY superiority)."
fi
exit $fail
