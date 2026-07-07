#!/usr/bin/env bash
# inproc_emit_gate.sh -- proves the IN-PROCESS sovereign assemble path (Phase C precondition for the emit.iii
# fold).  sovcoff, driven through the new sov_out_to_buffer sink, emits a COFF into MEMORY (no stdout, no gcc)
# byte-identical to gcc-as's .text -- exactly the capability emit.iii's iii_emit_assemble_sovereign needs to
# turn `iiis-2 foo.iii -o foo.o` sovereign in-process.  rc captured directly.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
SOV="$ROOT/STDLIB/sovtc"
OUT="$ROOT/STDLIB/build/_sovboot"
mkdir -p "$OUT"
say(){ echo "[inproc] $*"; }
fail=0

for m in sovas sovparse sovcoff sovld sovas_main; do
  "$IIIS" "$SOV/$m.iii" --compile-only --out "$OUT/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; fail=1; }
done
"$IIIS" "$SOV/test_bufemit.iii" --compile-only --out "$OUT/test_bufemit.o" >/dev/null 2>&1 || { say "FAIL compile harness"; fail=1; }
gcc "$OUT/sovas_main.o" "$OUT/sovparse.o" "$OUT/sovcoff.o" "$OUT/sovas.o" -lkernel32 -o "$OUT/sovas_main.exe" 2>/dev/null || { say "FAIL link sovas_main"; fail=1; }
gcc "$OUT/test_bufemit.o" "$OUT/sovparse.o" "$OUT/sovcoff.o" "$OUT/sovas.o" -lkernel32 -o "$OUT/test_bufemit.exe" 2>/dev/null || { say "FAIL link harness"; fail=1; }

# prove in-process (buffer) COFF == stdout-tool COFF == gcc-as .text, on a set of real modules
for m in prog_sat sovas sovparse; do
  src="$SOV/$m.iii"
  "$IIIS" "$src" --compile-only --out "$OUT/ip_$m.o" >/dev/null 2>&1 || { say "FAIL iiis-2 compile $m"; fail=1; continue; }
  timeout 40 "$OUT/test_bufemit.exe" "$OUT/ip_$m.o.s" "$OUT/ip_${m}_inproc.o"; rc=$?
  if [ "$rc" != "0" ]; then say "FAIL $m in-process emit (rc=$rc)"; fail=1; continue; fi
  timeout 40 "$OUT/sovas_main.exe" "$OUT/ip_$m.o.s" > "$OUT/ip_${m}_stdout.o" 2>/dev/null
  gcc -c -x assembler "$OUT/ip_$m.o.s" -o "$OUT/ip_${m}_gas.o" 2>/dev/null
  objcopy -O binary --only-section=.text "$OUT/ip_${m}_inproc.o" "$OUT/_ipa.t" 2>/dev/null
  objcopy -O binary --only-section=.text "$OUT/ip_${m}_gas.o" "$OUT/_ipb.t" 2>/dev/null
  if cmp -s "$OUT/ip_${m}_inproc.o" "$OUT/ip_${m}_stdout.o" && cmp -s "$OUT/_ipa.t" "$OUT/_ipb.t" && [ -s "$OUT/_ipa.t" ]; then
    say "PASS $m: in-process COFF == stdout tool, .text == gas (no stdout, no gcc)"
  else
    say "FAIL $m: in-process emit diverges"; fail=1
  fi
done

if [ "$fail" -eq 0 ]; then say "ALL PASS -- in-process sovereign COFF emission is byte-identical to gas"; exit 0; fi
say "FAILURES"; exit 1
