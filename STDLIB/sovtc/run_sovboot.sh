#!/usr/bin/env bash
# run_sovboot.sh -- the SOVEREIGN BOOTSTRAP gate.  Unlike run_sovtc.sh (unit gates on hand-embedded .s), this
# takes a REAL, self-contained, multi-function III PROGRAM, compiles it with the real iiis-2, and drives the
# whole emission through III's own file-driven assembler (sovas_main) and assembler+linker (sovld_main):
#   1. iiis-2 boot1.iii            -> boot1.o.s            (real cg_r3 emission)
#   2. sovas_main boot1.o.s        -> boot1_sov.o         (sovereign COFF .o)   -- .text BYTE-IDENTICAL to gas
#   3. gcc-link boot1_sov.o + run  -> 99                  (the sovereign .o is linkable + correct)
#   4. sovld_main boot1.o.s        -> boot1.exe + run     -> 99  (native PE, NO gcc/ld/gas anywhere)
# Byte-differential vs gas is the spine: a wrong instruction byte reddens step 2 even if the program runs.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
SOV="$ROOT/STDLIB/sovtc"
OUT="$ROOT/STDLIB/build/_sovboot"
mkdir -p "$OUT"
fail=0

# --- build the toolchain + the two file-driven tools ---
for m in sovas sovparse sovcoff sovld sovas_main sovld_main; do
  "$IIIS" "$SOV/$m.iii" --compile-only --out "$OUT/$m.o" >/dev/null 2>&1 || { echo "[sovboot] FAIL compile $m"; fail=1; }
done
gcc "$OUT/sovas_main.o" "$OUT/sovparse.o" "$OUT/sovcoff.o" "$OUT/sovas.o" -lkernel32 -o "$OUT/sovas_main.exe" 2>/dev/null || { echo "[sovboot] FAIL link sovas_main"; fail=1; }
gcc "$OUT/sovld_main.o" "$OUT/sovld.o" "$OUT/sovparse.o" "$OUT/sovas.o" -lkernel32 -o "$OUT/sovld_main.exe" 2>/dev/null || { echo "[sovboot] FAIL link sovld_main"; fail=1; }

# --- the test program -> real cg_r3 .s ---
"$IIIS" "$SOV/boot1.iii" --compile-only --out "$OUT/boot1.o" >/dev/null 2>&1 || { echo "[sovboot] FAIL compile boot1"; fail=1; }
S="$OUT/boot1.o.s"

# --- step 2: sovereign .o, byte-differential vs gas ---
gcc -c -x assembler "$S" -o "$OUT/boot1_gcc.o" 2>/dev/null
timeout 25 "$OUT/sovas_main.exe" "$S" > "$OUT/boot1_sov.o" 2>/dev/null
objcopy -O binary --only-section=.text "$OUT/boot1_sov.o" "$OUT/sov.text" 2>/dev/null
objcopy -O binary --only-section=.text "$OUT/boot1_gcc.o" "$OUT/gcc.text" 2>/dev/null
if cmp -s "$OUT/sov.text" "$OUT/gcc.text"; then echo "[sovboot] PASS boot1 .text BYTE-IDENTICAL to gas ($(wc -c <"$OUT/sov.text") bytes)"; else echo "[sovboot] FAIL boot1 .text differs from gas"; fail=1; fi

# --- step 3: sovereign .o is linkable + runs ---
gcc "$OUT/boot1_sov.o" -lkernel32 -o "$OUT/boot1_sov.exe" 2>/dev/null
timeout 20 "$OUT/boot1_sov.exe" >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 99 ]; then echo "[sovboot] PASS boot1 (sovas .o, gcc-linked) runs 99"; else echo "[sovboot] FAIL boot1 sovas .o run (got $rc)"; fail=1; fi

# --- step 4: full sovereign PE, no gcc/ld/gas ---
timeout 25 "$OUT/sovld_main.exe" "$S" > "$OUT/boot1.exe" 2>/dev/null
timeout 20 "$OUT/boot1.exe" >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 99 ]; then echo "[sovboot] PASS boot1.exe (SOVEREIGN PE -- no gcc/ld/gas) runs 99"; else echo "[sovboot] FAIL boot1 sovereign PE run (got $rc)"; fail=1; fi

if [ "$fail" -eq 0 ]; then echo "[sovboot] ALL PASS"; else echo "[sovboot] FAILURES"; fi
exit "$fail"
