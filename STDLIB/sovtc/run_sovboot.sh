#!/usr/bin/env bash
# run_sovboot.sh -- the SOVEREIGN BOOTSTRAP gate.  Unlike run_sovtc.sh (unit gates on hand-embedded .s), this
# takes REAL, self-contained, multi-function III PROGRAMS, compiles each with the real iiis-2, and drives the
# whole emission through III's own file-driven assembler (sovas_main) and assembler+linker (sovld_main):
#   1. iiis-2 prog.iii            -> prog.o.s             (real cg_r3 emission)
#   2. sovas_main prog.o.s        -> prog_sov.o          (sovereign COFF .o)   -- .text BYTE-IDENTICAL to gas
#   3. gcc-link prog_sov.o + run  -> 99                  (the sovereign .o is linkable + correct)
#   4. sovld_main prog.o.s        -> prog.exe + run      -> 99  (native PE, NO gcc/ld/gas anywhere)
# Byte-differential vs gas is the spine: a wrong instruction byte reddens step 2 even if the program runs.
# Programs:  boot1 = u64 path (movq, sibling calls, data reloc).  boot2 = u32 path (movl + movl disp(%rbp) +
# movl SIB array access) -- the forms boot1 never exercises.
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

for prog in boot1 boot2 boot3 boot4; do
  "$IIIS" "$SOV/$prog.iii" --compile-only --out "$OUT/$prog.o" >/dev/null 2>&1 || { echo "[sovboot] FAIL compile $prog"; fail=1; continue; }
  S="$OUT/$prog.o.s"
  # step 2: sovereign .o, byte-differential vs gas
  gcc -c -x assembler "$S" -o "$OUT/${prog}_gcc.o" 2>/dev/null
  timeout 25 "$OUT/sovas_main.exe" "$S" > "$OUT/${prog}_sov.o" 2>/dev/null
  objcopy -O binary --only-section=.text "$OUT/${prog}_sov.o" "$OUT/${prog}_s.t" 2>/dev/null
  objcopy -O binary --only-section=.text "$OUT/${prog}_gcc.o" "$OUT/${prog}_g.t" 2>/dev/null
  if cmp -s "$OUT/${prog}_s.t" "$OUT/${prog}_g.t"; then echo "[sovboot] PASS $prog .text BYTE-IDENTICAL to gas ($(wc -c <"$OUT/${prog}_s.t") bytes)"; else echo "[sovboot] FAIL $prog .text differs from gas"; fail=1; fi
  # step 3: sovereign .o is linkable + runs
  gcc "$OUT/${prog}_sov.o" -lkernel32 -o "$OUT/${prog}_sov.exe" 2>/dev/null
  timeout 20 "$OUT/${prog}_sov.exe" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 99 ]; then echo "[sovboot] PASS $prog (sovas .o, gcc-linked) runs 99"; else echo "[sovboot] FAIL $prog sovas .o run (got $rc)"; fail=1; fi
  # step 4: full sovereign PE, no gcc/ld/gas
  timeout 25 "$OUT/sovld_main.exe" "$S" > "$OUT/$prog.exe" 2>/dev/null
  timeout 20 "$OUT/$prog.exe" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 99 ]; then echo "[sovboot] PASS $prog.exe (SOVEREIGN PE -- no gcc/ld/gas) runs 99"; else echo "[sovboot] FAIL $prog sovereign PE run (got $rc)"; fail=1; fi
done

if [ "$fail" -eq 0 ]; then echo "[sovboot] ALL PASS"; else echo "[sovboot] FAILURES"; fi
exit "$fail"
