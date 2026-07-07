#!/usr/bin/env bash
# sov_preflight.sh -- C4 GO/NO-GO evidence: can the sovereign assembler (sovas) assemble
# the WHOLE tree's codegen byte-identical to gas?  Flipping emit.iii's default to sovereign
# makes every stdlib+compiler module .o.s route through sovas during bootstrap; run_fixpoint
# only proves ~20 toolchain modules + 7 SIMD.  This sweeps a broad sample and reports:
#   assemble-clean rate (rc 0, valid .o)  AND  byte-identity-vs-gas rate (.text == gas).
# NO tree mutation.  Names every divergent module -> the exact C4 blocker, or GO.
set -u
export LC_ALL=C
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
SOV="$ROOT/STDLIB/sovtc"
W="$(mktemp -d "${TMPDIR:-/tmp}/sovpf.XXXXXX")"
trap 'rm -rf "$W"' EXIT
say(){ printf '[preflight] %s\n' "$*"; }

# gen1 sovas_main.exe (the in-process fold will call these same sov_* internals)
for m in sovas sovparse sovcoff; do "$IIIS" "$SOV/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL bootstrap-compile $m"; exit 2; }; done
"$IIIS" "$SOV/sovas_main.iii" --compile-only --out "$W/sovas_main.o" >/dev/null 2>&1 || { say "FAIL compile sovas_main"; exit 2; }
gcc "$W/sovas_main.o" "$W/sovparse.o" "$W/sovcoff.o" "$W/sovas.o" -lkernel32 -o "$W/sovas_main.exe" 2>/dev/null || { say "FAIL gen1 link"; exit 2; }
say "gen1 sovas_main.exe ready"

# The sample: all COMPILER/BOOT .iii TUs (the compiler itself) + a stride sample of STDLIB/iii.
mapfile -t COMPILER_TUS < <(ls "$SOV/../.."/COMPILER/BOOT/*.iii 2>/dev/null)
mapfile -t STDLIB_TUS < <(find "$ROOT/STDLIB/iii" -name '*.iii' | LC_ALL=C sort)

ASM_OK=0; ASM_FAIL=0; IDENT=0; DIFF=0; ERR_ASM=0
FAILED_ASM=""; DIFFED=""
LIMIT="${1:-99999}"   # optional cap for a quick pass
n=0
sweep_one(){
  local src="$1" tag="$2"
  local base; base="$(basename "$src" .iii)"
  # iiis-2 codegen -> .o.s (skip modules iiis-2 itself can't compile -- not a sovas concern)
  if ! ( cd "$(dirname "$src")" && "$IIIS" "$base.iii" --compile-only --out "$W/m.o" >/dev/null 2>&1 ); then return; fi
  [ -f "$W/m.o.s" ] || return
  n=$((n+1))
  # sovereign assemble
  if timeout 40 "$W/sovas_main.exe" "$W/m.o.s" > "$W/m_sov.o" 2>/dev/null && [ -s "$W/m_sov.o" ]; then
    ASM_OK=$((ASM_OK+1))
  else
    ASM_FAIL=$((ASM_FAIL+1)); FAILED_ASM="$FAILED_ASM $tag/$base"; rm -f "$W/m.o.s"; return
  fi
  # byte-identity vs gas (.text)
  gcc -c -x assembler "$W/m.o.s" -o "$W/m_g.o" 2>/dev/null
  objcopy -O binary --only-section=.text "$W/m_sov.o" "$W/a.t" 2>/dev/null
  objcopy -O binary --only-section=.text "$W/m_g.o"   "$W/b.t" 2>/dev/null
  if cmp -s "$W/a.t" "$W/b.t"; then IDENT=$((IDENT+1)); else DIFF=$((DIFF+1)); DIFFED="$DIFFED $tag/$base"; fi
  rm -f "$W/m.o.s" "$W/m_sov.o" "$W/m_g.o"
}

for s in "${COMPILER_TUS[@]}"; do [ $n -ge "$LIMIT" ] && break; sweep_one "$s" COMPILER; done
for s in "${STDLIB_TUS[@]}";  do [ $n -ge "$LIMIT" ] && break; sweep_one "$s" STDLIB;  done

say "=================== SOVEREIGN PREFLIGHT ==================="
say "modules swept (iiis-2-compilable):     $n"
say "sov-assemble CLEAN (rc0, non-empty):   $ASM_OK"
say "sov-assemble FAILED:                   $ASM_FAIL"
say "of clean: .text BYTE-IDENTICAL to gas: $IDENT"
say "of clean: .text DIFFERS from gas:      $DIFF"
[ -n "$FAILED_ASM" ] && say "ASSEMBLE-FAILED modules:$FAILED_ASM"
[ -n "$DIFFED" ]     && say "BYTE-DIFF modules:$DIFFED"
if [ "$ASM_FAIL" -eq 0 ] && [ "$DIFF" -eq 0 ]; then say "VERDICT: GO -- sovereign path assembles the swept tree byte-identical to gas"; exit 0; fi
if [ "$ASM_FAIL" -eq 0 ]; then say "VERDICT: ASSEMBLE-COMPLETE but $DIFF byte-diffs (layout, not correctness -- inspect)"; exit 1; fi
say "VERDICT: NO-GO for default flip -- $ASM_FAIL modules sovas cannot assemble (named above)"; exit 1
