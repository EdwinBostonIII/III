#!/usr/bin/env bash
# tp_iii_to_c99_gate.sh -- proves omnia/tp_iii_to_c99 is a REAL construct-directed transpiler
# (independence G2), NOT a source-string wrapper, via a SEMANTIC round-trip.
#
#   1. compile+run corpus/1943 (self-checks: native III iiimul(6,7)==49 AND transpile is real C) -> exit 99
#      and it PRINTS the emitted C99 to stdout.
#   2. the printed C must be real (`#include`/`uint64_t iiimul`), NOT `static const char* iii_source`.
#   3. SEMANTIC round-trip: gcc-compile the emitted C + a test main calling iiimul(6,7), run it, and assert
#      it returns 49 -- i.e. the transpiled C reproduces the III program's result.
#
# gcc is the WITNESS compiler for the round-trip.  rc captured directly.  Exit 0 GREEN, 1 assertion, 2 env.
set -u
export LC_ALL=C
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
W="$(mktemp -d "${TMPDIR:-/tmp}/tp99.XXXXXX")"
trap 'rm -rf "$W"' EXIT
say(){ printf '[tp-c99] %s\n' "$*"; }

[ -x "$IIIS" ] || { say "FAIL: missing $IIIS"; exit 2; }
command -v gcc >/dev/null 2>&1 || { say "SKIP: gcc absent (witness compiler needed for the round-trip)"; exit 0; }

"$IIIS" "$ROOT/STDLIB/iii/omnia/tp_iii_to_c99.iii"              --compile-only --out "$W/t.o"   >/dev/null 2>&1 || { say "FAIL: transpiler compile"; exit 1; }
"$IIIS" "$ROOT/STDLIB/corpus/2489_tp_iii_to_c99_roundtrip.iii"  --compile-only --out "$W/drv.o" >/dev/null 2>&1 || { say "FAIL: driver compile"; exit 1; }
gcc "$W/drv.o" "$W/t.o" -lmsvcrt -o "$W/drv.exe" 2>/dev/null || { say "FAIL: driver link"; exit 1; }
"$W/drv.exe" > "$W/out.c" 2>/dev/null; drc=$?
[ "$drc" -eq 99 ] || { say "FAIL: driver self-check exit=$drc (2=native wrong, 1=byte-wrap not real C)"; sed 's/^/    /' "$W/out.c"; exit 1; }

# 2. real C, not a string wrapper
if grep -q 'iii_source' "$W/out.c"; then say "FAIL: output is a source-string wrapper (iii_source), not real C"; exit 1; fi
grep -q 'uint64_t iiimul' "$W/out.c" || { say "FAIL: expected real C decl 'uint64_t iiimul' absent"; sed 's/^/    /' "$W/out.c"; exit 1; }
say "PASS: transpile is real C99 --"; sed 's/^/    /' "$W/out.c"

# 3. semantic round-trip: compile the emitted C + a test main, run, assert iiimul(6,7)==49
printf '\nint main(void){ return (int)iiimul(6,7); }\n' >> "$W/out.c"
gcc "$W/out.c" -o "$W/rt.exe" 2>/dev/null || { say "FAIL: emitted C did not compile"; exit 1; }
"$W/rt.exe"; rc=$?
if [ "$rc" -eq 49 ]; then
  say "PASS round-trip: the transpiled C runs to 49 == the III program's result (6*7+7)"
  say "GATE GREEN -- tp_iii_to_c99 is a real construct-directed transpiler"
  exit 0
else
  say "FAIL round-trip: transpiled C returned $rc, expected 49"
  exit 1
fi
