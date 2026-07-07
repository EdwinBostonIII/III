#!/usr/bin/env bash
# tp_x86_roundtrip_gate.sh -- proves omnia/tp_x86_disasm is a REAL x86-64 decoder (independence G1),
# the inverse of the encoder, NOT a `.byte` dumper.
#
#   1. run the decoder on a known instruction stream (prologue + ALU + epilogue), print the AT&T text
#   2. assert it contains REAL mnemonics (movq/addq/subq/xorq/pushq/popq/retq) and NO `.byte` line
#   3. ROUND-TRIP: gas-reassemble the decoded text; the reg-reg + prologue/epilogue instruction bytes must
#      reproduce the input EXACTLY (disasm is the inverse of the encoder).  [callq's rel32 + gas's
#      function-alignment NOP padding are stripped -- they are not instruction-identity.]
#
# gcc/binutils are the WITNESS assembler for the round-trip cross-check (like run_fixpoint's gas-differential).
# rc captured directly.  Exit 0 GREEN, 1 a failed assertion, 2 environment.
set -u
export LC_ALL=C
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
W="$(mktemp -d "${TMPDIR:-/tmp}/tpdis.XXXXXX")"
trap 'rm -rf "$W"' EXIT
say(){ printf '[tp-disasm] %s\n' "$*"; }

[ -x "$IIIS" ] || { say "FAIL: missing $IIIS"; exit 2; }
command -v gcc >/dev/null 2>&1 || { say "SKIP: gcc absent (witness assembler needed for round-trip)"; exit 0; }

"$IIIS" "$ROOT/STDLIB/iii/omnia/tp_x86_disasm.iii"              --compile-only --out "$W/d.o"   >/dev/null 2>&1 || { say "FAIL: decoder compile"; exit 1; }
"$IIIS" "$ROOT/STDLIB/corpus/2488_tp_x86_disasm_roundtrip.iii" --compile-only --out "$W/drv.o" >/dev/null 2>&1 || { say "FAIL: driver compile"; exit 1; }
gcc "$W/drv.o" "$W/d.o" -lmsvcrt -o "$W/drv.exe" 2>/dev/null || { say "FAIL: driver link"; exit 1; }
"$W/drv.exe" > "$W/dis.s" 2>/dev/null; drc=$?
[ "$drc" -eq 99 ] || { say "FAIL: driver self-check exit=$drc (expected 99 -- decoder degraded to .byte)"; sed 's/^/    /' "$W/dis.s"; exit 1; }

# 2. real mnemonics, no .byte
if grep -qE '^\s*\.byte' "$W/dis.s"; then say "FAIL: output contains a .byte line -- a form was NOT decoded"; sed 's/^/    /' "$W/dis.s"; exit 1; fi
for mn in pushq movq addq subq xorq popq retq; do
  grep -qE "\b$mn\b" "$W/dis.s" || { say "FAIL: real mnemonic '$mn' absent from decode"; sed 's/^/    /' "$W/dis.s"; exit 1; }
done
say "PASS: decoder emits real AT&T mnemonics (no .byte fallback) --"; sed 's/^/    /' "$W/dis.s"

# 3. round-trip via gas on the exactly-reproducible subset (strip callq)
grep -vE 'callq' "$W/dis.s" > "$W/core.s"
gcc -c -x assembler "$W/core.s" -o "$W/rt.o" 2>/dev/null || { say "FAIL: gas could not reassemble the decode"; exit 1; }
objcopy -O binary --only-section=.text "$W/rt.o" "$W/rt.bin" 2>/dev/null
got="$(xxd -p "$W/rt.bin" | tr -d '\n' | sed 's/\(90\)*$//')"      # strip trailing NOP alignment padding
want="554889e54801d34829c84831f648c7c0100000005dc3"
if [ "$got" = "$want" ]; then
  say "PASS round-trip: gas reassembles the decode to the identical instruction bytes"
  say "GATE GREEN -- tp_x86_disasm is a real decoder (inverse of the encoder)"
  exit 0
else
  say "FAIL round-trip: reassembled $got != expected $want"
  exit 1
fi
