#!/usr/bin/env bash
# run_ccsv.sh -- the non-gcc C compiler FOUNDATION (ccsv): compile C's integer core to a SOVEREIGN x86 PE (no
# gcc in the artifact path), mini-DDC it against gcc's build of the same C, and show the cross-language byte-DDC
# (ccsv(test.c) == iiisv(indep_toolchain.iii) -- same algorithm, two languages, identical canonical SVIR).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"; W="$ROOT/STDLIB/build/sovir"
fail=0; say(){ echo "[ccsv] $*"; }
"$IIIS" "$S/ccsv.iii"    --compile-only --out "$W/ccsv.o"    >/dev/null 2>&1 || { say "FAIL compile ccsv"; fail=1; }
"$IIIS" "$S/iiisv.iii"   --compile-only --out "$W/iiisv.o"   >/dev/null 2>&1
"$IIIS" "$S/svir_x86.iii" --compile-only --out "$W/svir_x86.o" >/dev/null 2>&1
gcc "$W/ccsv.o"  -o "$W/ccsv.exe"  2>/dev/null
gcc "$W/iiisv.o" -o "$W/iiisv.exe" 2>/dev/null
# ccsv: real C -> SVIR -> sovereign x86
"$W/ccsv.exe" "$S/test.c" > "$W/gen_csvir.iii" 2>/dev/null
"$IIIS" "$W/gen_csvir.iii" --compile-only --out "$W/gen_csvir.o" >/dev/null 2>&1 || { say "FAIL ccsv output"; fail=1; }
gcc "$W/svir_x86.o" "$W/gen_csvir.o" -o "$W/tx_c.exe" 2>/dev/null; "$W/tx_c.exe" > "$W/c.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/c.s" > "$W/c.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/c.o2" > "$W/c.x86.exe" 2>/dev/null
timeout 10 "$W/c.x86.exe" >/dev/null 2>&1; cv=$?
k=$(objdump -p "$W/c.x86.exe" 2>/dev/null | grep -ic "DLL Name")
# mini-DDC: gcc build of the same C
gcc "$S/test.c" -o "$W/c_gcc.exe" 2>/dev/null; "$W/c_gcc.exe" >/dev/null 2>&1; gv=$?
# cross-language byte-DDC: ccsv(C) vs iiisv(.iii) for the same algorithm
"$W/iiisv.exe" "$ROOT/STDLIB/independence/indep_toolchain.iii" > "$W/_ii.iii" 2>/dev/null
xl="NO"; cmp -s "$W/gen_csvir.iii" "$W/_ii.iii" && xl="YES"
if [ $cv -eq 99 ] && [ $gv -eq 99 ] && [ "$k" = "1" ] && [ "$xl" = "YES" ]; then
  say "ccsv NON-GCC C COMPILER : real C -> SVIR -> x86(sovereign,kernel32-only)=$cv ; mini-DDC gcc=$gv agree ; cross-language byte-DDC ccsv(C)==iiisv(.iii)=$xl.  Foundation for seed-DDC; full iiis-0 C = the long road."
else say "FAIL: ccsv=$cv gcc=$gv dlls=$k crosslang=$xl"; fail=1; fi

# arbitrary-precision: ccsv compiles a C bignum (100! via global array + putchar) -> sovereign x86 -> the 158
# digits, matching the golden AND (content) gcc.  ccsv now handles global arrays, array index, output, and skips
# #preprocessor lines.
"$W/ccsv.exe" "$S/test_bignum.c" > "$W/gen_bnc.iii" 2>/dev/null
"$IIIS" "$W/gen_bnc.iii" --compile-only --out "$W/gen_bnc.o" >/dev/null 2>&1
gcc "$W/svir_x86.o" "$W/gen_bnc.o" -o "$W/tx_bnc.exe" 2>/dev/null; "$W/tx_bnc.exe" > "$W/bnc.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/bnc.s" > "$W/bnc.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/bnc.o2" > "$W/bnc.x86.exe" 2>/dev/null
timeout 10 "$W/bnc.x86.exe" > "$W/out_ccsv.txt" 2>/dev/null; bv=$?
node -e 'let f=1n;for(let i=1n;i<=100n;i++)f*=i;console.log(f.toString())' > "$W/out_gold.txt" 2>/dev/null
gcc "$S/test_bignum.c" -o "$W/bnc_gcc.exe" 2>/dev/null; "$W/bnc_gcc.exe" 2>/dev/null | tr -d '\r' > "$W/out_gcc.txt"
gold="NO"; cmp -s "$W/out_ccsv.txt" "$W/out_gold.txt" && gold="YES"
gccm="NO"; cmp -s "$W/out_ccsv.txt" "$W/out_gcc.txt" && gccm="YES"
if [ $bv -eq 99 ] && [ "$gold" = "YES" ] && [ "$gccm" = "YES" ]; then
  say "ccsv ARBITRARY-PRECISION : C bignum (global array + putchar) -> sovereign x86 prints 100! (158 digits) == golden(node)=$gold == gcc(content)=$gccm -> 99.  ccsv grew: global arrays, indexing, output, #-line skip."
else say "FAIL bignum: exit=$bv golden=$gold gcc=$gccm"; fail=1; fi

# C feature tiers: compile a .c via ccsv -> SVIR -> sovereign x86 + wasm, verifier-accepted, gcc-agreed (all 99).
cfeat(){  # $1 = test file basename (in $S)
  "$W/ccsv.exe" "$S/$1" > "$W/g_$1.iii" 2>/dev/null
  "$IIIS" "$W/g_$1.iii" --compile-only --out "$W/g_$1.o" >/dev/null 2>&1
  gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/g_$1.o" -o "$W/vf_$1.exe" 2>/dev/null; "$W/vf_$1.exe" >/dev/null 2>&1; local vf=$?
  gcc "$W/svir_x86.o" "$W/g_$1.o" -o "$W/tx_$1.exe" 2>/dev/null; "$W/tx_$1.exe" > "$W/$1.s" 2>/dev/null
  timeout 20 "$BOOT/sovas_main.exe" "$W/$1.s" > "$W/$1.o2" 2>/dev/null
  timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/$1.o2" > "$W/$1.x86.exe" 2>/dev/null
  timeout 10 "$W/$1.x86.exe" >/dev/null 2>&1; local x=$?
  gcc "$W/svir_wasm.o" "$W/g_$1.o" -o "$W/tw_$1.exe" 2>/dev/null; "$W/tw_$1.exe" > "$W/$1.wasm" 2>/dev/null
  node "$S/run_wasm.mjs" "$W/$1.wasm" >/dev/null 2>&1; local w=$?
  gcc "$S/$1" -o "$W/gcc_$1.exe" 2>/dev/null; "$W/gcc_$1.exe" >/dev/null 2>&1; local gc=$?
  if [ $vf -eq 99 ] && [ $x -eq 99 ] && [ $w -eq 99 ] && [ $gc -eq 99 ]; then echo "ok"; else echo "FAIL($1 vf=$vf x86=$x wasm=$w gcc=$gc)"; fi
}
rp=$(cfeat test_ptr.c); rs=$(cfeat test_struct.c)
if [ "$rp" = "ok" ] && [ "$rs" = "ok" ]; then
  say "ccsv C TIERS : local int arrays (8-byte cells) + char literals + pointers (test_ptr.c) AND structs (test_struct.c) -> sovereign x86 + wasm + verifier + gcc, all 99.  ccsv = C integer core + arrays + output + pointers + structs."
else say "FAIL tiers: ptr=$rp struct=$rs"; fail=1; fi

# string literals: char *s = "..."; s[i] -> sovereign x86 prints the string == gcc's output (content); exit 99.
"$W/ccsv.exe" "$S/test_str.c" > "$W/gen_str.iii" 2>/dev/null
"$IIIS" "$W/gen_str.iii" --compile-only --out "$W/gen_str.o" >/dev/null 2>&1
gcc "$W/svir_x86.o" "$W/gen_str.o" -o "$W/tx_str.exe" 2>/dev/null; "$W/tx_str.exe" > "$W/str.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/str.s" > "$W/str.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/str.o2" > "$W/str.x86.exe" 2>/dev/null
timeout 10 "$W/str.x86.exe" > "$W/out_str.txt" 2>/dev/null; sv=$?
gcc "$S/test_str.c" -o "$W/str_gcc.exe" 2>/dev/null; "$W/str_gcc.exe" > "$W/_sg.txt" 2>/dev/null; sg=$?; tr -d '\r' < "$W/_sg.txt" > "$W/out_str_gcc.txt"
scon="NO"; cmp -s "$W/out_str.txt" "$W/out_str_gcc.txt" && scon="YES"
if [ $sv -eq 99 ] && [ $sg -eq 99 ] && [ "$scon" = "YES" ]; then
  say "ccsv STRING LITERALS : char *s=\"...\"; s[i] -> sovereign x86 prints [$(cat "$W/out_str.txt" | tr -d '\n')] == gcc(content)=$scon -> 99.  BYTE-PACKED via a SVIR DATA SECTION (real C layout, initialised memory) + char* stride-1 LOAD8."
else say "FAIL string: sovereign=$sv gcc=$sg content=$scon"; fail=1; fi
exit $fail
