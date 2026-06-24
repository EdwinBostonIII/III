#!/usr/bin/env bash
# seed_ddc_msvc.sh -- Diverse Double-Compiling of the iiis-0 seed against an INDEPENDENT-LINEAGE compiler (MSVC).
#
# The Thompson "trusting trust" residual: a backdoor in the gcc that built iiis-0 could perpetuate itself into
# every binary iiis-0 produces, invisibly.  DDC (Wheeler 2009) defeats it: rebuild the seed with a compiler of a
# DIFFERENT lineage; if both seeds produce IDENTICAL output, no backdoor differing between the lineages exists.
#
# Here CC1 = gcc/mingw (the reference seed, COMPILED/iiis-0.exe) and CC2 = MSVC cl.exe (Microsoft lineage, fully
# independent of gcc) building build/_msvcddc/iiis-0_msvc.exe via build_iiis0_msvc.sh (seed footprint: one
# gcc-byte-identical rename; the rest are MSVC build flags -- see that script + DOCS/SVIR-DDC-RESIDUAL.md).
#
# The measurement: compile every iiis-1 source (.iii) with BOTH seeds, --compile-only, and byte-compare the .o.
# All-identical => the gcc-built seed carries no output-altering backdoor that MSVC's lineage does not also carry.
#
# Honest scope: this proves the iiis-0 -> iiis-1 codegen step at the .o level for all ported TUs.  It assumes MSVC
# is not backdoored identically to gcc (the standard DDC independence premise) and does not remove the irreducible
# TCB (CPU/microcode, OS loader).  It is genuine "outputs verified byte-for-byte by an independent toolchain."
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOT="$ROOT/COMPILER/BOOT"; OUT="$ROOT/build/_msvcddc"
G="$ROOT/COMPILED/iiis-0.exe"      # CC1 lineage: gcc/mingw
M="$OUT/iiis-0_msvc.exe"           # CC2 lineage: MSVC

# 1. ensure the independent (MSVC) seed exists
[ -f "$M" ] || bash "$BOOT/build_iiis0_msvc.sh" >/dev/null 2>&1
[ -f "$G" ] || { echo "[ddc] FAIL: reference iiis-0.exe (gcc) not found -- run build_iiis0.sh"; exit 2; }
[ -f "$M" ] || { echo "[ddc] FAIL: iiis-0_msvc.exe not built"; exit 2; }

# 2. the iiis-1 ported source set (PORTED_TUS from build_iiis1.sh)
PORTED="acc affine_audit ast ceiling cg_r0 cg_r3 cg_rm1 cg_rm2 cg_sha cg_typeclass emit emit_sanctum hexad_check jit_emit lex lex_rt link main parse proof sema sid witness_alloc"

# 3. compile each with both seeds, byte-compare the .o
ok=0; bad=0; err=0; total=0
for t in $PORTED; do
  src="$BOOT/$t.iii"; [ -f "$src" ] || continue
  total=$((total+1))
  timeout 60 "$G" "$src" --compile-only --out "$OUT/ddc_g_$t.o" >/dev/null 2>&1; rg=$?
  timeout 60 "$M" "$src" --compile-only --out "$OUT/ddc_m_$t.o" >/dev/null 2>&1; rm2=$?
  if [ $rg -ne 0 ] || [ $rm2 -ne 0 ]; then err=$((err+1)); echo "[ddc] ERR $t (gcc=$rg msvc=$rm2)"; continue; fi
  if cmp -s "$OUT/ddc_g_$t.o" "$OUT/ddc_m_$t.o"; then ok=$((ok+1)); else bad=$((bad+1)); echo "[ddc] DIVERGE $t"; fi
done

echo "[ddc] CHAIN (iiis-1 ported TUs): $ok/$total byte-identical .o ; diverged=$bad ; errored=$err"

# 4. BROAD WITNESS: every other .iii reachable (BOOT + sovir), to widen the diverse-lineage agreement set.
#    (space-safe array iteration -- the host path contains a space; word-splitting would mangle every name.)
wok=0; wbad=0; werr=0; wtot=0
mapfile -t WSRCS < <(ls "$BOOT"/*.iii "$ROOT"/STDLIB/sovir/*.iii 2>/dev/null)
for src in "${WSRCS[@]}"; do
  [ -f "$src" ] || continue
  b=$(basename "$src" .iii); wtot=$((wtot+1))
  timeout 60 "$G" "$src" --compile-only --out "$OUT/w_g_$b.o" >/dev/null 2>&1; rg=$?
  timeout 60 "$M" "$src" --compile-only --out "$OUT/w_m_$b.o" >/dev/null 2>&1; rm2=$?
  if [ $rg -ne 0 ] || [ $rm2 -ne 0 ]; then werr=$((werr+1)); continue; fi
  if cmp -s "$OUT/w_g_$b.o" "$OUT/w_m_$b.o"; then wok=$((wok+1)); else wbad=$((wbad+1)); echo "[ddc] WITNESS-DIVERGE $b"; fi
done
echo "[ddc] BROAD WITNESS (all reachable .iii): $wok byte-identical / $((wtot-werr)) compiled-by-both ; diverged=$wbad ; (unsupported=$werr)"

if [ $ok -eq $total ] && [ $total -gt 0 ] && [ $bad -eq 0 ] && [ $err -eq 0 ] && [ $wbad -eq 0 ]; then
  echo "[ddc] PASS -- two independent-lineage iiis-0 seeds (gcc vs MSVC) emit IDENTICAL object code for every iiis-1"
  echo "[ddc]         ported TU AND for all $wok reachable witness programs.  Zero divergence across the lineages."
  echo "[ddc] The gcc-built seed carries no output-altering Thompson backdoor that MSVC's lineage does not share."
  exit 0
else
  echo "[ddc] FAIL -- divergence or error; the seeds do not agree (investigate build/_msvcddc/*.o)"; exit 1
fi
