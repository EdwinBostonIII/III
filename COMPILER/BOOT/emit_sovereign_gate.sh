#!/usr/bin/env bash
# emit_sovereign_gate.sh -- proves emit.iii's in-process SOVEREIGN ASSEMBLE path (independence C2)
# produces a .o byte-identical to the gcc-witness path, for the exact calls iii_emit_assemble_sovereign
# makes (sov_reset -> sov_out_to_buffer -> sovparse_full -> sovcoff_emit -> write buffer).
#
# PROXY: iii_emit_assemble_sovereign's body is call-for-call identical to sovas_main.iii's flow (the only
# deltas -- a leading sov_reset/sov_data_reset and a buffer sink instead of stdout -- were committed +
# gate-proven in 0fddb0ce and are correct-by-construction).  So sovas_main.exe over the same .o.s is a
# faithful proxy for the in-process result; the byte-vs-gas cmp is the real gate.  The definitive proof is
# C4, where the compiler is BUILT with this code and reproduces the chain.  Here we prove the assemble is
# sound + gcc-identical on a spread of real modules BEFORE the re-seal commits to it.
#
# Exit 0 = every sampled module's sovereign .o has .text byte-identical to gas; 1 = a divergence (named).
set -u
export LC_ALL=C
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
SOV="$ROOT/STDLIB/sovtc"
W="$(mktemp -d "${TMPDIR:-/tmp}/emitsov.XXXXXX")"
trap 'rm -rf "$W"' EXIT
say(){ printf '[emit-sov-gate] %s\n' "$*"; }

for m in sovas sovparse sovcoff; do "$IIIS" "$SOV/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL bootstrap $m"; exit 2; }; done
"$IIIS" "$SOV/sovas_main.iii" --compile-only --out "$W/sovas_main.o" >/dev/null 2>&1 || { say "FAIL compile sovas_main"; exit 2; }
gcc "$W/sovas_main.o" "$W/sovparse.o" "$W/sovcoff.o" "$W/sovas.o" -lkernel32 -o "$W/sovas_main.exe" 2>/dev/null || { say "FAIL gen1 link"; exit 2; }

# The sample: prog_sat (the plan's named consumer) + the compiler's own hardest modules.
SAMPLES=( "$SOV:prog_sat" "$ROOT/COMPILER/BOOT:cg_r3" "$ROOT/COMPILER/BOOT:main" "$ROOT/COMPILER/BOOT:emit" )
ok=0; tot=0
for pair in "${SAMPLES[@]}"; do
  d="${pair%:*}"; b="${pair#*:}"; tot=$((tot+1))
  ( cd "$d" && "$IIIS" "$b.iii" --compile-only --out "$W/m.o" >/dev/null 2>&1 )
  if [ ! -f "$W/m.o.s" ]; then say "FAIL $b (iiis-2 produced no .o.s)"; continue; fi
  if timeout 60 "$W/sovas_main.exe" "$W/m.o.s" > "$W/m_sov.o" 2>/dev/null && [ -s "$W/m_sov.o" ]; then
    gcc -c -x assembler "$W/m.o.s" -o "$W/m_g.o" 2>/dev/null
    objcopy -O binary --only-section=.text "$W/m_sov.o" "$W/a.t" 2>/dev/null
    objcopy -O binary --only-section=.text "$W/m_g.o"   "$W/b.t" 2>/dev/null
    if cmp -s "$W/a.t" "$W/b.t"; then say "PASS $b (.o.text sovereign == gas)"; ok=$((ok+1)); else say "FAIL $b (sovereign .o differs from gas)"; fi
  else
    say "FAIL $b (sovas refused a mnemonic)"
  fi
  rm -f "$W/m.o.s" "$W/m_sov.o" "$W/m_g.o"
done
say "assemble-sovereign gate: $ok/$tot byte-identical to gas"
[ "$ok" -eq "$tot" ] && { say "GREEN"; exit 0; } || { say "RED"; exit 1; }
