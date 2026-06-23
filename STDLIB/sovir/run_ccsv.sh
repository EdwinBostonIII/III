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
exit $fail
