#!/usr/bin/env bash
# emit_gen_diff.sh -- the emit_generic differential gate (the output-preservation safety net).
#
# The determinism corpus (--check-corpus) is R3-only and SELF-consistency (iiis-1==iiis-2); it proves
# NOTHING about r0/rm1/rm2 and does not compare against the pre-refactor compiler. A structural dedup of
# the codegens changes the compiler BINARY (mhash drifts -> reseal) even when perfectly output-preserving.
# This script regenerates every ring's codegen output for ONE compiler so two compilers can be diffed:
#
#   bash emit_gen_diff.sh COMPILED/iiis-2.exe.emitgen-baseline /tmp/eg_base   # the frozen baseline
#   bash emit_gen_diff.sh COMPILED/iiis-2.exe                  /tmp/eg_new    # after a refactor step
#   diff -r /tmp/eg_base /tmp/eg_new      # MUST be empty: output preserved across all 4 rings
#
# A single differing byte = the dedup changed emission = STOP and root-cause. Falsifiable by construction.
set -u
IIIS="${1:?usage: emit_gen_diff.sh <iiis-binary> <outdir>}"
OUT="${2:?usage: emit_gen_diff.sh <iiis-binary> <outdir>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 2
[ -x "$IIIS" ] || { echo "[eg-diff] FAIL: no compiler at $IIIS"; exit 1; }
mkdir -p "$OUT/r0" "$OUT/r3" "$OUT/rm1" "$OUT/rm2"

# --- R0: the 24 real KATABASIS kernel sources (the live cg_r0 consumer set) -> .s ---
R0_SRCS="KATABASIS-DEPLOY/src/gate_floor.iii KATABASIS-DEPLOY/src/gate_driver.iii KATABASIS-DEPLOY/src/cpufeat_kernel.iii KATABASIS-DEPLOY/src/gate_resident.iii"
R0_MODS="omnia/hexad_algebra omnia/hexad_pfs omnia/hexad_reach omnia/xii_term numera/trit numera/sha256 numera/keccak256 numera/keccak numera/cad aether/capability katabasis/svm_layout katabasis/bar_layout katabasis/cycle_family katabasis/cycle_admit katabasis/cycle_term katabasis/seal katabasis/caps katabasis/gate_verdict katabasis/gate katabasis/admit"
for s in $R0_SRCS; do bn=$(basename "$s" .iii); "$IIIS" "$s" --ring R0 --emit-asm-only --out "$OUT/r0/$bn" >/dev/null 2>&1; done
for m in $R0_MODS; do bn=$(basename "$m"); "$IIIS" "STDLIB/iii/$m.iii" --ring R0 --emit-asm-only --out "$OUT/r0/$bn" >/dev/null 2>&1; done

# --- R-1 (hypervisor) and R-2 (sanctum): sealed_call samples. rm2_sample = arith+return (covers
#     stmt_return + the empty string_pool prefix); rm_match_sample = match (covers pattern_compare
#     LITERAL+WILDCARD); rm_str_sample = string literal (covers the string_pool escaping loop).
#     Both rings for each = both sides of every SV_MODE branch in the sanctum-family engine. ---
for s in rm2_sample rm_match_sample rm_str_sample; do
  "$IIIS" "COMPILER/BOOT/$s.iii" --ring R-1 --emit-asm-only --out "$OUT/rm1/$s" >/dev/null 2>&1
  "$IIIS" "COMPILER/BOOT/$s.iii" --ring R-2 --emit-asm-only --out "$OUT/rm2/$s" >/dev/null 2>&1
done

# --- R3: the 59 stage1_corpus programs -> .o (the byte-identity set) ---
for f in COMPILER/BOOT/stage1_corpus/*.iii; do bn=$(basename "$f" .iii); "$IIIS" "$f" --ring R3 --compile-only --out "$OUT/r3/$bn.o" >/dev/null 2>&1; done

echo "[eg-diff] $IIIS -> $OUT : r0=$(ls "$OUT"/r0/*.s 2>/dev/null|wc -l).s rm1=$(ls "$OUT"/rm1/*.s 2>/dev/null|wc -l).s rm2=$(ls "$OUT"/rm2/*.s 2>/dev/null|wc -l).s r3=$(ls "$OUT"/r3/*.o 2>/dev/null|wc -l).o"
